import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:image_picker/image_picker.dart';

import '../data/local/app_database.dart';
import '../data/local/conflict_resolver.dart';
import '../data/local/tables/local_tables.dart';
import '../models/donation.dart';
import 'api_exception.dart';
import 'donation_service.dart';
import 'image_upload_service.dart';

const syncMaxAttempts = 5;
const abandonedProcessingThreshold = Duration(minutes: 5);

Duration syncBackoff(int attempt) => switch (attempt) {
  <= 1 => const Duration(seconds: 5),
  2 => const Duration(seconds: 15),
  3 => const Duration(seconds: 30),
  4 => const Duration(seconds: 60),
  _ => const Duration(seconds: 120),
};

class SyncCoordinator {
  SyncCoordinator({
    required this.database,
    required this.donationService,
    required this.imageUploadService,
    DateTime Function()? clock,
    Future<void> Function(String path)? deleteManagedFile,
    this.conflictResolver = const ConflictResolver(),
  }) : _clock = clock ?? DateTime.now,
       _deleteManagedFile = deleteManagedFile ?? _deleteFile;

  final AppDatabase database;
  final DonationService donationService;
  final ImageUploadService imageUploadService;
  final DateTime Function() _clock;
  final Future<void> Function(String path) _deleteManagedFile;
  final ConflictResolver conflictResolver;
  Future<void>? _activeSync;

  Future<void> processPending(int cacheUserId) {
    final active = _activeSync;
    if (active != null) return active;
    final run = _processPending(cacheUserId);
    _activeSync = run;
    return run.whenComplete(() {
      if (identical(_activeSync, run)) _activeSync = null;
    });
  }

  Future<void> _processPending(int cacheUserId) async {
    final now = _clock();
    await database.pendingOperationsDao.recoverAbandonedProcessing(
      cacheUserId: cacheUserId,
      abandonedBefore: now.subtract(abandonedProcessingThreshold),
    );
    final operations = await database.pendingOperationsDao.listProcessable(
      cacheUserId: cacheUserId,
      now: now,
    );
    for (final operation in operations) {
      try {
        await _processCreateDonation(operation);
      } on ApiException catch (error) {
        if (error.type == ApiErrorType.authentication ||
            error.type == ApiErrorType.inactiveAccount) {
          await _pauseForAuthentication(operation, error);
          return;
        }
        await _recordFailure(operation, error);
      } on FileSystemException {
        await _recordFailure(
          operation,
          const ApiException(
            ApiErrorType.validation,
            'Archivo local inválido.',
          ),
        );
      } on Object {
        await _recordFailure(
          operation,
          const ApiException(ApiErrorType.server, 'Fallo temporal.'),
        );
      }
    }
  }

  Future<void> _processCreateDonation(PendingOperation operation) async {
    final donation =
        await (database.select(database.localDonations)
              ..where((row) => row.cacheUserId.equals(operation.cacheUserId))
              ..where((row) => row.clientId.equals(operation.entityClientId)))
            .getSingleOrNull();
    if (donation == null) {
      throw const ApiException(
        ApiErrorType.validation,
        'La donación local ya no existe.',
      );
    }
    final attemptAt = _clock();
    await database.transaction(() async {
      await database.pendingOperationsDao.updateOperation(
        operationId: operation.operationId,
        state: PendingOperationState.processing,
        attemptCount: operation.attemptCount + 1,
        lastAttemptAt: Value(attemptAt),
        nextAttemptAt: const Value(null),
        lastErrorCode: const Value(null),
      );
      await (database.update(
        database.localDonations,
      )..where((row) => row.localId.equals(donation.localId))).write(
        const LocalDonationsCompanion(
          syncState: Value(DonationSyncState.syncing),
        ),
      );
    });

    final images =
        await (database.select(database.localDonationImages)
              ..where((row) => row.localDonationId.equals(donation.localId))
              ..orderBy([(row) => OrderingTerm.asc(row.sortOrder)]))
            .get();
    final references = <String>[];
    for (final image in images) {
      var remoteUrl = image.remoteUrl;
      if (remoteUrl == null) {
        final path = image.managedLocalPath;
        if (path == null) {
          throw const ApiException(
            ApiErrorType.validation,
            'La imagen local no está disponible.',
          );
        }
        await (database.update(
          database.localDonationImages,
        )..where((row) => row.localId.equals(image.localId))).write(
          const LocalDonationImagesCompanion(
            uploadState: Value(ImageUploadState.uploading),
          ),
        );
        remoteUrl = (await imageUploadService.uploadImages([
          XFile(path, mimeType: image.mimeType),
        ])).single;
        await (database.update(
          database.localDonationImages,
        )..where((row) => row.localId.equals(image.localId))).write(
          LocalDonationImagesCompanion(
            remoteUrl: Value(remoteUrl),
            uploadState: const Value(ImageUploadState.remote),
          ),
        );
      }
      references.add(remoteUrl);
    }

    final remote = await donationService.createDonation(
      clientId: donation.clientId,
      title: donation.title,
      description: donation.description ?? '',
      categoryId: donation.categoryId,
      imageReferences: references,
    );
    await _reconcile(operation, donation, images, remote);
  }

  Future<void> _reconcile(
    PendingOperation operation,
    LocalDonation local,
    List<LocalDonationImage> images,
    DonationDetail remote,
  ) async {
    final conflictDecision = conflictResolver.resolveConfirmedCreation(
      remoteServerUpdatedAt: remote.updatedAt,
    );
    if (conflictDecision != ConflictDecision.applyRemote) {
      throw const ApiException(
        ApiErrorType.unexpectedResponse,
        'La respuesta no contiene una versión válida del servidor.',
      );
    }
    final syncedAt = _clock();
    final managedPaths = images
        .map((image) => image.managedLocalPath)
        .whereType<String>()
        .toList(growable: false);
    await database.transaction(() async {
      await (database.update(
        database.localDonations,
      )..where((row) => row.localId.equals(local.localId))).write(
        LocalDonationsCompanion(
          remoteId: Value(remote.id),
          lastSyncedAt: Value(syncedAt),
          syncState: const Value(DonationSyncState.synced),
          status: Value(remote.estado.apiValue),
          title: Value(remote.titulo),
          description: Value(remote.descripcion),
          city: Value(remote.ciudad),
          categoryId: Value(remote.categoriaId),
          categoryName: Value(remote.categoriaNombre),
          mainImageUrl: Value(
            remote.imagenes.isEmpty ? null : remote.imagenes.first.referencia,
          ),
          imageCount: Value(remote.imagenes.length),
          createdAt: Value(remote.createdAt),
          serverUpdatedAt: Value(remote.updatedAt),
        ),
      );
      for (final image in remote.imagenes) {
        await (database.update(database.localDonationImages)
              ..where((row) => row.localDonationId.equals(local.localId))
              ..where((row) => row.sortOrder.equals(image.orden)))
            .write(
              LocalDonationImagesCompanion(
                remoteImageId: Value(image.id),
                remoteUrl: Value(image.referencia),
                uploadState: const Value(ImageUploadState.remote),
              ),
            );
      }
      await database
          .into(database.localDonationMemberships)
          .insertOnConflictUpdate(
            LocalDonationMembershipsCompanion.insert(
              cacheUserId: operation.cacheUserId,
              localDonationId: local.localId,
              collectionType: DonationCollectionType.myDonations,
              lastSeenAt: syncedAt,
              expiresAt: syncedAt,
            ),
          );
      await database.pendingOperationsDao.updateOperation(
        operationId: operation.operationId,
        state: PendingOperationState.completed,
        nextAttemptAt: const Value(null),
        lastErrorCode: const Value(null),
      );
    });
    for (final path in managedPaths) {
      await _deleteManagedFile(path);
      await (database.update(database.localDonationImages)
            ..where((row) => row.localDonationId.equals(local.localId))
            ..where((row) => row.managedLocalPath.equals(path)))
          .write(
            const LocalDonationImagesCompanion(managedLocalPath: Value(null)),
          );
    }
  }

  Future<void> _recordFailure(
    PendingOperation operation,
    ApiException error,
  ) async {
    final attempt = operation.attemptCount + 1;
    final recoverable = _isRecoverable(error);
    final permanent = !recoverable || attempt >= syncMaxAttempts;
    final state = permanent
        ? PendingOperationState.failedPermanent
        : PendingOperationState.retryWait;
    final now = _clock();
    await database.transaction(() async {
      await database.pendingOperationsDao.updateOperation(
        operationId: operation.operationId,
        state: state,
        attemptCount: attempt,
        lastAttemptAt: Value(now),
        nextAttemptAt: Value(permanent ? null : now.add(syncBackoff(attempt))),
        lastErrorCode: Value(_errorCode(error)),
      );
      await _updateDonationSyncState(
        operation,
        permanent
            ? DonationSyncState.failedPermanent
            : DonationSyncState.failedRetryable,
      );
    });
  }

  Future<void> _pauseForAuthentication(
    PendingOperation operation,
    ApiException error,
  ) => database.transaction(() async {
    await database.pendingOperationsDao.updateOperation(
      operationId: operation.operationId,
      state: PendingOperationState.pending,
      nextAttemptAt: const Value(null),
      lastErrorCode: const Value('AUTH_REQUIRED'),
    );
    await _updateDonationSyncState(
      operation,
      DonationSyncState.failedRetryable,
    );
  });

  Future<void> _updateDonationSyncState(
    PendingOperation operation,
    DonationSyncState state,
  ) =>
      (database.update(database.localDonations)..where(
            (row) =>
                row.cacheUserId.equals(operation.cacheUserId) &
                row.clientId.equals(operation.entityClientId),
          ))
          .write(LocalDonationsCompanion(syncState: Value(state)));

  bool _isRecoverable(ApiException error) =>
      error.type == ApiErrorType.network ||
      error.type == ApiErrorType.timeout ||
      error.type == ApiErrorType.server ||
      error.type == ApiErrorType.rateLimited;

  String _errorCode(ApiException error) => switch (error.type) {
    ApiErrorType.network => 'NETWORK',
    ApiErrorType.timeout => 'TIMEOUT',
    ApiErrorType.server => 'SERVER',
    ApiErrorType.rateLimited => 'RATE_LIMITED',
    ApiErrorType.forbidden => 'FORBIDDEN',
    ApiErrorType.conflict => 'CONFLICT',
    ApiErrorType.notFound => 'NOT_FOUND',
    _ => 'VALIDATION',
  };
}

Future<void> _deleteFile(String path) async {
  final file = File(path);
  if (await file.exists()) await file.delete();
}

class ConnectivitySyncTrigger {
  ConnectivitySyncTrigger({
    required this.connectivity,
    required this.cacheUserId,
    required this.coordinator,
  });

  final Stream<bool> connectivity;
  final int Function() cacheUserId;
  final SyncCoordinator coordinator;
  StreamSubscription<bool>? _subscription;
  bool _wasOnline = false;

  void start() {
    _subscription ??= connectivity.distinct().listen((online) {
      if (online && !_wasOnline) {
        unawaited(coordinator.processPending(cacheUserId()));
      }
      _wasOnline = online;
    });
  }

  Future<void> dispose() async => _subscription?.cancel();
}
