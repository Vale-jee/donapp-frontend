import 'dart:async';

import 'package:flutter/widgets.dart';

import '../data/local/app_database.dart';
import '../data/local/donation_local_data_source.dart';
import '../data/local/tables/local_tables.dart';
import '../data/remote/donation_remote_data_source.dart';
import '../repositories/donation_repository.dart';
import 'auth_state_controller.dart';
import 'category_service.dart';
import 'donation_service.dart';
import 'image_upload_service.dart';
import 'remote_image_cache.dart';
import 'sync_coordinator.dart';

/// One outbox worker for the authenticated app, never one per screen.
class OfflineDonations with WidgetsBindingObserver {
  OfflineDonations({
    required this.authState,
    AppDatabase Function()? databaseFactory,
    this.donationService,
    this.imageUploadService,
    DateTime Function()? clock,
  }) : _databaseFactory = databaseFactory ?? AppDatabase.new,
       _clock = clock ?? DateTime.now {
    WidgetsBinding.instance.addObserver(this);
    authState.addListener(_sessionChanged);
    _sessionChanged();
  }

  final AuthStateController authState;
  final AppDatabase Function() _databaseFactory;
  final DonationService? donationService;
  final ImageUploadService? imageUploadService;
  final DateTime Function() _clock;
  AppDatabase? _database;
  SyncCoordinator? _coordinator;
  DonationRepository? repository;
  int? _userId;
  Timer? _timer;
  bool _foreground = true;
  Future<void> _closing = Future<void>.value();

  void _sessionChanged() {
    final user = authState.profile;
    if (user?.id == _userId) return;
    _stop();
    if (user == null) return;
    _userId = user.id;
    final database = _database = _databaseFactory();
    final api = authState.sessionCoordinator.protectedApiClient;
    final donations =
        donationService ??
        DonationService(
          apiClient: api,
          tokenStorage: authState.sessionCoordinator.tokenStorage,
        );
    final images =
        imageUploadService ??
        ImageUploadService(
          apiClient: api,
          tokenStorage: authState.sessionCoordinator.tokenStorage,
        );
    _coordinator = SyncCoordinator(
      database: database,
      donationService: donations,
      imageUploadService: images,
      clock: _clock,
    );
    repository = DonationRepository(
      DonationLocalDataSource(database),
      DonationRemoteDataSource(donations, CategoryService(apiClient: api)),
      imageCache: RemoteImageCache(),
      onQueued: _trigger,
    );
    _trigger();
  }

  Future<void> _scheduleNext(SyncCoordinator coordinator, int userId) async {
    final database = _database;
    if (!_foreground ||
        database == null ||
        !identical(coordinator, _coordinator)) {
      return;
    }
    final rows = await (database.select(
      database.pendingOperations,
    )..where((row) => row.cacheUserId.equals(userId))).get();
    if (!_foreground || !identical(coordinator, _coordinator)) return;
    _timer?.cancel();
    _timer = null;
    // The coordinator pauses the whole queue for authentication. Other pending
    // rows must not schedule an immediate loop against that same session.
    if (rows.any(
      (row) =>
          row.state == PendingOperationState.pending &&
          row.lastErrorCode == 'AUTH_REQUIRED',
    )) {
      return;
    }
    DateTime? next;
    for (final row in rows) {
      final due = switch (row.state) {
        PendingOperationState.retryWait => row.nextAttemptAt,
        PendingOperationState.pending
            when row.lastErrorCode != 'AUTH_REQUIRED' =>
          _clock(),
        PendingOperationState.processing =>
          (row.lastAttemptAt ?? _clock())
              .add(abandonedProcessingThreshold)
              .add(const Duration(milliseconds: 1)),
        _ => null,
      };
      if (due != null && (next == null || due.isBefore(next))) next = due;
    }
    _timer?.cancel();
    _timer = null;
    if (next != null) {
      final delay = next.difference(_clock());
      _timer = Timer(delay.isNegative ? Duration.zero : delay, _trigger);
    }
  }

  void _trigger() {
    unawaited(syncNow());
  }

  Future<void> syncNow() async {
    final coordinator = _coordinator;
    final userId = _userId;
    if (coordinator == null || userId == null) return;
    try {
      await _closing;
      if (!identical(coordinator, _coordinator)) return;
      await coordinator.processPending(userId);
      await _scheduleNext(coordinator, userId);
    } on Object {
      // A local open/read failure leaves durable work for the next trigger.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      _trigger();
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    final coordinator = _coordinator;
    final database = _database;
    _coordinator = null;
    _database = null;
    repository = null;
    _userId = null;
    if (coordinator != null) {
      final stopping = coordinator.shutdown();
      _closing = _closing.then((_) async {
        await stopping;
        await database!.close();
      });
    }
  }

  Future<void> dispose() async {
    authState.removeListener(_sessionChanged);
    WidgetsBinding.instance.removeObserver(this);
    _stop();
    await _closing;
  }
}
