import 'dart:async';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'package:donapp_mobile/data/local/app_database.dart';
import 'package:donapp_mobile/data/local/tables/local_tables.dart';
import 'package:donapp_mobile/models/donation.dart';
import 'package:donapp_mobile/services/api_exception.dart';
import 'package:donapp_mobile/services/donation_service.dart';
import 'package:donapp_mobile/services/image_upload_service.dart';
import 'package:donapp_mobile/services/sync_coordinator.dart';

void main() {
  late AppDatabase db;
  var now = DateTime.utc(2026, 9, 2, 20);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    now = DateTime.utc(2026, 9, 2, 20);
  });
  tearDown(() => db.close());

  Future<({int localId, String operationId})> seed({
    int user = 1,
    String suffix = 'a',
    String? remoteUrl = 'https://images.test/existing.jpg',
    String? managedPath,
    int attemptCount = 0,
    PendingOperationState operationState = PendingOperationState.pending,
    DateTime? provisionalCreatedAt,
  }) async {
    final clientId = 'client-$suffix';
    final localId = await db
        .into(db.localDonations)
        .insert(
          LocalDonationsCompanion.insert(
            cacheUserId: user,
            clientId: clientId,
            expiresAt: now.add(const Duration(days: 1)),
            syncState: DonationSyncState.pendingCreate,
            title: 'Mesa para donar',
            description: const Value(
              'Mesa de madera en buen estado para donar.',
            ),
            city: 'Bogotá',
            categoryId: 4,
            categoryName: 'Muebles',
            createdAt: Value(provisionalCreatedAt),
          ),
        );
    await db
        .into(db.localDonationImages)
        .insert(
          LocalDonationImagesCompanion.insert(
            localDonationId: localId,
            remoteUrl: Value(remoteUrl),
            managedLocalPath: Value(managedPath),
            sortOrder: 1,
            mimeType: const Value('image/jpeg'),
            uploadState: remoteUrl == null
                ? ImageUploadState.localPending
                : ImageUploadState.remote,
          ),
        );
    final operationId = 'operation-$suffix';
    await db.pendingOperationsDao.insertOperation(
      PendingOperationsCompanion.insert(
        operationId: operationId,
        cacheUserId: user,
        entityType: PendingOperationEntityType.donation,
        entityClientId: clientId,
        operationType: PendingOperationType.createDonation,
        state: Value(operationState),
        attemptCount: Value(attemptCount),
        createdAt: now,
      ),
    );
    return (localId: localId, operationId: operationId);
  }

  SyncCoordinator coordinator({
    required _DonationService donations,
    _ImageService? images,
    Future<void> Function(String)? deleteFile,
  }) => SyncCoordinator(
    database: db,
    donationService: donations,
    imageUploadService: images ?? _ImageService(),
    clock: () => now,
    deleteManagedFile: deleteFile,
  );

  test('éxito procesa y reconcilia la misma fila sin duplicarla', () async {
    final provisionalCreatedAt = DateTime.utc(2020, 1, 1);
    final seeded = await seed(provisionalCreatedAt: provisionalCreatedAt);
    final service = _DonationService((_) async => remoteDonation());
    final imageService = _ImageService();
    await coordinator(
      donations: service,
      images: imageService,
    ).processPending(1);

    final operation = await db.pendingOperationsDao.findByOperationId(
      seeded.operationId,
    );
    final donations = await db.select(db.localDonations).get();
    expect(operation!.state, PendingOperationState.completed);
    expect(operation.attemptCount, 1);
    expect(operation.lastAttemptAt?.toUtc(), now);
    expect(operation.operationId, seeded.operationId);
    expect(donations, hasLength(1));
    expect(donations.single.localId, seeded.localId);
    expect(donations.single.clientId, 'client-a');
    expect(donations.single.remoteId, 42);
    expect(donations.single.syncState, DonationSyncState.synced);
    expect(donations.single.createdAt?.toUtc(), remoteDonation().createdAt);
    expect(donations.single.createdAt, isNot(provisionalCreatedAt));
    expect(
      donations.single.serverUpdatedAt?.toUtc(),
      remoteDonation().updatedAt,
    );
    expect(donations.single.lastSyncedAt?.toUtc(), now);
    expect(await db.select(db.localDonationMemberships).get(), hasLength(1));
    expect(imageService.calls, 0, reason: 'una URL remota no vuelve a subirse');

    await coordinator(donations: service).processPending(1);
    expect(service.calls, 1, reason: 'completed no debe reprocesarse');
  });

  test(
    'respuesta idempotente adopta tiempos del servidor y conserva IDs',
    () async {
      final seeded = await seed(
        suffix: 'idempotent',
        provisionalCreatedAt: DateTime.utc(2020, 1, 1),
      );
      final existingRemote = remoteDonation();

      await coordinator(
        donations: _DonationService((_) async => existingRemote),
      ).processPending(1);

      final saved = await db.select(db.localDonations).getSingle();
      final operation = await db.pendingOperationsDao.findByOperationId(
        seeded.operationId,
      );
      expect(saved.localId, seeded.localId);
      expect(saved.clientId, 'client-idempotent');
      expect(saved.createdAt?.toUtc(), existingRemote.createdAt);
      expect(saved.serverUpdatedAt?.toUtc(), existingRemote.updatedAt);
      expect(operation?.operationId, seeded.operationId);
      expect(operation?.state, PendingOperationState.completed);
      expect(await db.select(db.localDonations).get(), hasLength(1));
    },
  );

  test(
    'timestamp remoto ausente o inválido no reconcilia ni inventa fecha',
    () async {
      for (final suffix in ['missing-time', 'invalid-time']) {
        final provisional = DateTime.utc(2020, 1, 1);
        final seeded = await seed(
          suffix: suffix,
          provisionalCreatedAt: provisional,
        );
        final service = _DonationService(
          (_) async => throw const FormatException('timestamp remoto inválido'),
        );

        await coordinator(donations: service).processPending(1);

        final saved = await (db.select(
          db.localDonations,
        )..where((row) => row.localId.equals(seeded.localId))).getSingle();
        final operation = await db.pendingOperationsDao.findByOperationId(
          seeded.operationId,
        );
        expect(saved.remoteId, isNull);
        expect(saved.createdAt?.toUtc(), provisional);
        expect(saved.serverUpdatedAt, isNull);
        expect(saved.syncState, DonationSyncState.failedRetryable);
        expect(operation?.state, PendingOperationState.retryWait);
        expect(operation?.lastErrorCode, 'SERVER');
        expect(operation?.nextAttemptAt?.toUtc(), now.add(syncBackoff(1)));
      }
    },
  );

  test('dos llamadas concurrentes procesan una sola vez', () async {
    await seed();
    final response = Completer<DonationDetail>();
    final service = _DonationService((_) => response.future);
    final sync = coordinator(donations: service);

    final first = sync.processPending(1);
    final second = sync.processPending(1);
    await Future<void>.delayed(Duration.zero);
    final processing = await db.pendingOperationsDao.findByOperationId(
      'operation-a',
    );
    expect(processing!.state, PendingOperationState.processing);
    response.complete(remoteDonation());
    await Future.wait([first, second]);
    expect(service.calls, 1);
  });

  test('error recuperable persiste backoff creciente', () async {
    final seeded = await seed();
    final service = _DonationService(
      (_) async => throw const ApiException(ApiErrorType.network, 'Sin red'),
    );
    final sync = coordinator(donations: service);

    await sync.processPending(1);
    var operation = (await db.pendingOperationsDao.findByOperationId(
      seeded.operationId,
    ))!;
    expect(operation.state, PendingOperationState.retryWait);
    expect(operation.attemptCount, 1);
    expect(operation.nextAttemptAt?.toUtc(), now.add(syncBackoff(1)));
    expect(operation.lastErrorCode, 'NETWORK');

    now = operation.nextAttemptAt!.toUtc();
    await sync.processPending(1);
    operation = (await db.pendingOperationsDao.findByOperationId(
      seeded.operationId,
    ))!;
    expect(operation.attemptCount, 2);
    expect(operation.nextAttemptAt?.toUtc(), now.add(syncBackoff(2)));
    expect(syncBackoff(2), greaterThan(syncBackoff(1)));
  });

  test(
    'máximo de intentos y error permanente terminan correctamente',
    () async {
      final retry = await seed(suffix: 'retry', attemptCount: 4);
      final permanent = await seed(suffix: 'permanent');
      final service = _DonationService((input) async {
        throw ApiException(
          input.clientId == 'client-retry'
              ? ApiErrorType.server
              : ApiErrorType.validation,
          'fallo',
        );
      });
      await coordinator(donations: service).processPending(1);

      for (final id in [retry.operationId, permanent.operationId]) {
        final operation = await db.pendingOperationsDao.findByOperationId(id);
        expect(operation!.state, PendingOperationState.failedPermanent);
        expect(operation.nextAttemptAt, isNull);
      }
      expect(
        (await db.pendingOperationsDao.findByOperationId(retry.operationId))!
            .attemptCount,
        syncMaxAttempts,
      );
    },
  );

  test('autenticación inválida detiene el lote sin perder la cola', () async {
    await seed(suffix: 'first');
    await seed(suffix: 'second');
    final service = _DonationService(
      (_) async => throw const ApiException(
        ApiErrorType.authentication,
        'Sesión inválida',
        statusCode: 401,
      ),
    );
    await coordinator(donations: service).processPending(1);

    expect(service.calls, 1);
    expect(
      (await db.pendingOperationsDao.findByOperationId('operation-first'))!
          .state,
      PendingOperationState.pending,
    );
    expect(
      (await db.pendingOperationsDao.findByOperationId('operation-second'))!
          .state,
      PendingOperationState.pending,
    );
  });

  test('solo procesa operaciones del usuario activo', () async {
    await seed(user: 1, suffix: 'mine');
    await seed(user: 2, suffix: 'other');
    final service = _DonationService((_) async => remoteDonation());
    await coordinator(donations: service).processPending(1);
    expect(service.clientIds, ['client-mine']);
    expect(
      (await db.pendingOperationsDao.findByOperationId('operation-other'))!
          .state,
      PendingOperationState.pending,
    );
  });

  test('recupera una operación processing abandonada', () async {
    final seeded = await seed(operationState: PendingOperationState.processing);
    await db.pendingOperationsDao.updateOperation(
      operationId: seeded.operationId,
      lastAttemptAt: Value(
        now.subtract(abandonedProcessingThreshold + const Duration(seconds: 1)),
      ),
    );
    final service = _DonationService((_) async => remoteDonation());
    await coordinator(donations: service).processPending(1);
    expect(service.calls, 1);
    expect(
      (await db.pendingOperationsDao.findByOperationId(seeded.operationId))!
          .state,
      PendingOperationState.completed,
    );
  });

  test(
    'reutiliza URL subida y limpia copia privada solo tras confirmar',
    () async {
      final seeded = await seed(
        suffix: 'image',
        remoteUrl: null,
        managedPath: 'private/image.jpg',
      );
      final deleted = <String>[];
      final imageService = _ImageService(result: 'https://images.test/new.jpg');
      final service = _DonationService((_) async => remoteDonation());
      await coordinator(
        donations: service,
        images: imageService,
        deleteFile: (path) async => deleted.add(path),
      ).processPending(1);

      expect(imageService.calls, 1);
      expect(deleted, ['private/image.jpg']);
      final image = await db.select(db.localDonationImages).getSingle();
      expect(image.remoteUrl, 'https://images.test/remote.jpg');
      expect(image.managedLocalPath, isNull);
      expect(
        (await db.pendingOperationsDao.findByOperationId(seeded.operationId))!
            .state,
        PendingOperationState.completed,
      );
    },
  );

  test('fallo temporal de imagen conserva archivo y no ejecuta POST', () async {
    await seed(remoteUrl: null, managedPath: 'private/image.jpg');
    final service = _DonationService((_) async => remoteDonation());
    final images = _ImageService(
      error: const ApiException(ApiErrorType.server, 'Cloudinary temporal'),
    );
    await coordinator(donations: service, images: images).processPending(1);

    expect(service.calls, 0);
    expect(
      (await db.select(db.localDonationImages).getSingle()).managedLocalPath,
      'private/image.jpg',
    );
    expect(
      (await db.pendingOperationsDao.findByOperationId('operation-a'))!.state,
      PendingOperationState.retryWait,
    );
  });

  test('recuperación de conectividad dispara procesamiento una vez', () async {
    await seed();
    final events = StreamController<bool>();
    final service = _DonationService((_) async => remoteDonation());
    final trigger = ConnectivitySyncTrigger(
      connectivity: events.stream,
      cacheUserId: () => 1,
      coordinator: coordinator(donations: service),
    )..start();

    events.add(false);
    events.add(true);
    await events.close();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(service.calls, 1);
    await trigger.dispose();
  });
}

DonationDetail remoteDonation() => DonationDetail(
  id: 42,
  titulo: 'Mesa para donar',
  descripcion: 'Mesa de madera en buen estado para donar.',
  ciudad: 'Bogotá',
  estado: DonationStatus.publicada,
  createdAt: DateTime.utc(2026, 9, 2, 19),
  updatedAt: DateTime.utc(2026, 9, 2, 19, 1),
  categoriaId: 4,
  categoriaNombre: 'Muebles',
  imagenes: const [
    DonationImage(
      id: 9,
      referencia: 'https://images.test/remote.jpg',
      orden: 1,
    ),
  ],
);

typedef _Create = Future<DonationDetail> Function(_CreateInput input);

class _CreateInput {
  const _CreateInput(this.clientId, this.imageReferences);
  final String? clientId;
  final List<String> imageReferences;
}

final class _DonationService extends DonationService {
  _DonationService(this.create);
  final _Create create;
  int calls = 0;
  final List<String?> clientIds = [];

  @override
  Future<DonationDetail> createDonation({
    String? clientId,
    required String title,
    required String description,
    required int categoryId,
    required List<String> imageReferences,
  }) {
    calls++;
    clientIds.add(clientId);
    return create(_CreateInput(clientId, imageReferences));
  }
}

final class _ImageService extends ImageUploadService {
  _ImageService({this.result = 'https://images.test/uploaded.jpg', this.error});
  final String result;
  final ApiException? error;
  int calls = 0;

  @override
  Future<List<String>> uploadImages(List<XFile> images) async {
    calls++;
    if (error case final error?) throw error;
    return [result];
  }
}
