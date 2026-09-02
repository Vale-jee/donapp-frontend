import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'package:donapp_mobile/data/local/app_database.dart';
import 'package:donapp_mobile/data/local/tables/local_tables.dart';

void main() {
  late AppDatabase db;
  final now = DateTime.utc(2026, 9, 2, 18);

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  PendingOperationsCompanion operation({
    required String operationId,
    required int cacheUserId,
    required String entityClientId,
    DateTime? nextAttemptAt,
  }) => PendingOperationsCompanion.insert(
    operationId: operationId,
    cacheUserId: cacheUserId,
    entityType: PendingOperationEntityType.donation,
    entityClientId: entityClientId,
    operationType: PendingOperationType.createDonation,
    createdAt: now,
    nextAttemptAt: Value(nextAttemptAt),
  );

  test('inserta CREATE_DONATION con valores iniciales y UUID único', () async {
    await db.pendingOperationsDao.insertOperation(
      operation(
        operationId: '550e8400-e29b-41d4-a716-446655440000',
        cacheUserId: 1,
        entityClientId: 'donation-client-1',
      ),
    );
    final saved = await db.pendingOperationsDao.findByOperationId(
      '550e8400-e29b-41d4-a716-446655440000',
    );
    expect(saved, isNotNull);
    expect(saved!.entityType, PendingOperationEntityType.donation);
    expect(saved.operationType, PendingOperationType.createDonation);
    expect(saved.state, PendingOperationState.pending);
    expect(saved.attemptCount, 0);
    await expectLater(
      db.pendingOperationsDao.insertOperation(
        operation(
          operationId: saved.operationId,
          cacheUserId: 2,
          entityClientId: 'different-entity',
        ),
      ),
      throwsA(isA<sqlite.SqliteException>()),
    );
  });

  test(
    'lista solo operaciones procesables del usuario y respeta backoff',
    () async {
      await db.pendingOperationsDao.insertOperation(
        operation(operationId: 'due', cacheUserId: 1, entityClientId: 'a'),
      );
      await db.pendingOperationsDao.insertOperation(
        operation(
          operationId: 'future',
          cacheUserId: 1,
          entityClientId: 'b',
          nextAttemptAt: now.add(const Duration(minutes: 1)),
        ),
      );
      await db.pendingOperationsDao.insertOperation(
        operation(
          operationId: 'other-user',
          cacheUserId: 2,
          entityClientId: 'c',
        ),
      );
      await db.pendingOperationsDao.updateOperation(
        operationId: 'due',
        state: PendingOperationState.retryWait,
        nextAttemptAt: Value(now.subtract(const Duration(minutes: 1))),
      );
      final rows = await db.pendingOperationsDao.listProcessable(
        cacheUserId: 1,
        now: now,
      );
      expect(rows.map((row) => row.operationId), ['due']);
    },
  );

  test(
    'actualiza estado, intentos, fechas y código de error sanitizado',
    () async {
      await db.pendingOperationsDao.insertOperation(
        operation(
          operationId: 'update',
          cacheUserId: 1,
          entityClientId: 'entity',
        ),
      );
      final nextAttempt = now.add(const Duration(minutes: 5));
      expect(
        await db.pendingOperationsDao.updateOperation(
          operationId: 'update',
          state: PendingOperationState.retryWait,
          nextAttemptAt: Value(nextAttempt),
          lastAttemptAt: Value(now),
          lastErrorCode: const Value(' network_timeout '),
        ),
        isTrue,
      );
      expect(
        await db.pendingOperationsDao.incrementAttemptCount('update'),
        isTrue,
      );
      final saved = (await db.pendingOperationsDao.findByOperationId(
        'update',
      ))!;
      expect(saved.state, PendingOperationState.retryWait);
      expect(saved.attemptCount, 1);
      expect(saved.nextAttemptAt?.toUtc(), nextAttempt);
      expect(saved.lastAttemptAt?.toUtc(), now);
      expect(saved.lastErrorCode, 'NETWORK_TIMEOUT');
      await expectLater(
        db.pendingOperationsDao.updateOperation(
          operationId: 'update',
          lastErrorCode: const Value('detalle con datos sensibles'),
        ),
        throwsArgumentError,
      );
    },
  );

  test('localiza entidades y mantiene aislamiento entre usuarios', () async {
    await db.pendingOperationsDao.insertOperation(
      operation(
        operationId: 'user-1',
        cacheUserId: 1,
        entityClientId: 'shared',
      ),
    );
    await db.pendingOperationsDao.insertOperation(
      operation(
        operationId: 'user-2',
        cacheUserId: 2,
        entityClientId: 'shared',
      ),
    );
    final firstUser = await db.pendingOperationsDao.findByEntityClientId(
      cacheUserId: 1,
      entityClientId: 'shared',
    );
    expect(firstUser.map((row) => row.operationId), ['user-1']);
    expect(
      (await db.pendingOperationsDao.listProcessable(
        cacheUserId: 2,
        now: now,
      )).map((row) => row.operationId),
      ['user-2'],
    );
  });

  test('elimina completadas o todas las operaciones de un usuario', () async {
    await db.pendingOperationsDao.insertOperation(
      operation(operationId: 'completed', cacheUserId: 1, entityClientId: 'a'),
    );
    await db.pendingOperationsDao.insertOperation(
      operation(operationId: 'pending', cacheUserId: 1, entityClientId: 'b'),
    );
    await db.pendingOperationsDao.insertOperation(
      operation(operationId: 'other-user', cacheUserId: 2, entityClientId: 'c'),
    );
    await db.pendingOperationsDao.updateOperation(
      operationId: 'completed',
      state: PendingOperationState.completed,
    );
    expect(await db.pendingOperationsDao.deleteCompleted(1), 1);
    expect(
      await db.pendingOperationsDao.findByOperationId('pending'),
      isNotNull,
    );
    expect(await db.pendingOperationsDao.deleteForUser(1), 1);
    expect(await db.pendingOperationsDao.findByOperationId('pending'), isNull);
    expect(
      await db.pendingOperationsDao.findByOperationId('other-user'),
      isNotNull,
    );
  });
}
