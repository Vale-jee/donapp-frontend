import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'package:donapp_mobile/data/local/app_database.dart';
import 'package:donapp_mobile/data/local/pending_operation_local_data_source.dart';
import 'package:donapp_mobile/data/local/tables/local_tables.dart';
import 'package:donapp_mobile/services/client_id_generator.dart';

void main() {
  late AppDatabase db;
  final now = DateTime.utc(2026, 9, 2, 20);

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test(
    'crea la operación con un operationId generado exactamente una vez',
    () async {
      final generator = _CountingIdGenerator(['operation-fixed']);
      final source = PendingOperationLocalDataSource(
        dao: db.pendingOperationsDao,
        idGenerator: generator,
        clock: () => now,
      );

      final operation = await source.createPendingDonationOperation(
        cacheUserId: 7,
        entityClientId: 'entity-fixed',
      );

      expect(generator.operationCalls, 1);
      expect(generator.entityCalls, 0);
      expect(operation.operationId, 'operation-fixed');
      expect(operation.entityClientId, 'entity-fixed');
      expect(operation.entityType, PendingOperationEntityType.donation);
      expect(operation.operationType, PendingOperationType.createDonation);
      expect(operation.state, PendingOperationState.pending);
      expect(operation.attemptCount, 0);
      expect(operation.createdAt.toUtc(), now);
    },
  );

  test(
    'mantiene operationId y entityClientId durante estados e intentos',
    () async {
      final source = PendingOperationLocalDataSource(
        dao: db.pendingOperationsDao,
        idGenerator: _CountingIdGenerator(['stable-operation']),
        clock: () => now,
      );
      final created = await source.createPendingDonationOperation(
        cacheUserId: 1,
        entityClientId: 'stable-entity',
      );

      await db.pendingOperationsDao.updateOperation(
        operationId: created.operationId,
        state: PendingOperationState.processing,
      );
      var updated = (await db.pendingOperationsDao.findByOperationId(
        created.operationId,
      ))!;
      expect(updated.operationId, created.operationId);
      expect(updated.entityClientId, created.entityClientId);

      await db.pendingOperationsDao.updateOperation(
        operationId: created.operationId,
        state: PendingOperationState.retryWait,
        nextAttemptAt: Value(now.add(const Duration(minutes: 1))),
      );
      await db.pendingOperationsDao.incrementAttemptCount(created.operationId);
      updated = (await db.pendingOperationsDao.findByOperationId(
        created.operationId,
      ))!;
      expect(updated.state, PendingOperationState.retryWait);
      expect(updated.attemptCount, 1);
      expect(updated.operationId, created.operationId);
      expect(updated.entityClientId, created.entityClientId);
    },
  );

  test('UNIQUE(operationId) rechaza una generación duplicada', () async {
    final generator = _CountingIdGenerator(['duplicate', 'duplicate']);
    final source = PendingOperationLocalDataSource(
      dao: db.pendingOperationsDao,
      idGenerator: generator,
      clock: () => now,
    );
    await source.createPendingDonationOperation(
      cacheUserId: 1,
      entityClientId: 'entity-a',
    );
    await expectLater(
      source.createPendingDonationOperation(
        cacheUserId: 1,
        entityClientId: 'entity-b',
      ),
      throwsA(isA<sqlite.SqliteException>()),
    );
  });
}

final class _CountingIdGenerator implements ClientIdGenerator {
  _CountingIdGenerator(this._operationIds);

  final List<String> _operationIds;
  int entityCalls = 0;
  int operationCalls = 0;

  @override
  String newEntityId() {
    entityCalls++;
    return 'entity-$entityCalls';
  }

  @override
  String newOperationId() => _operationIds[operationCalls++];
}
