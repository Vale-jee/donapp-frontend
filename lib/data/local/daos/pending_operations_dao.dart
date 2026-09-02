import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/local_tables.dart';

part 'pending_operations_dao.g.dart';

@DriftAccessor(tables: [PendingOperations])
class PendingOperationsDao extends DatabaseAccessor<AppDatabase>
    with _$PendingOperationsDaoMixin {
  PendingOperationsDao(super.db);

  Future<int> insertOperation(PendingOperationsCompanion operation) =>
      into(pendingOperations).insert(operation);

  Future<PendingOperation?> findByOperationId(String operationId) => (select(
    pendingOperations,
  )..where((row) => row.operationId.equals(operationId))).getSingleOrNull();

  Future<List<PendingOperation>> listProcessable({
    required int cacheUserId,
    required DateTime now,
  }) =>
      (select(pendingOperations)
            ..where(
              (row) =>
                  row.cacheUserId.equals(cacheUserId) &
                  (row.state.equals(PendingOperationState.pending.name) |
                      row.state.equals(PendingOperationState.retryWait.name)) &
                  (row.nextAttemptAt.isNull() |
                      row.nextAttemptAt.isSmallerOrEqualValue(now)),
            )
            ..orderBy([(row) => OrderingTerm.asc(row.createdAt)]))
          .get();

  Future<List<PendingOperation>> findByEntityClientId({
    required int cacheUserId,
    required String entityClientId,
  }) =>
      (select(pendingOperations)..where(
            (row) =>
                row.cacheUserId.equals(cacheUserId) &
                row.entityClientId.equals(entityClientId),
          ))
          .get();

  Future<bool> updateOperation({
    required String operationId,
    PendingOperationState? state,
    int? attemptCount,
    Value<DateTime?> nextAttemptAt = const Value.absent(),
    Value<DateTime?> lastAttemptAt = const Value.absent(),
    Value<String?> lastErrorCode = const Value.absent(),
  }) async {
    if (attemptCount != null && attemptCount < 0) {
      throw ArgumentError.value(attemptCount, 'attemptCount');
    }
    final sanitizedErrorCode = lastErrorCode.present
        ? Value(_sanitizeErrorCode(lastErrorCode.value))
        : const Value<String?>.absent();
    final changed =
        await (update(
          pendingOperations,
        )..where((row) => row.operationId.equals(operationId))).write(
          PendingOperationsCompanion(
            state: state == null ? const Value.absent() : Value(state),
            attemptCount: attemptCount == null
                ? const Value.absent()
                : Value(attemptCount),
            nextAttemptAt: nextAttemptAt,
            lastAttemptAt: lastAttemptAt,
            lastErrorCode: sanitizedErrorCode,
          ),
        );
    return changed == 1;
  }

  Future<bool> incrementAttemptCount(String operationId) async {
    final operation = await findByOperationId(operationId);
    if (operation == null) return false;
    return updateOperation(
      operationId: operationId,
      attemptCount: operation.attemptCount + 1,
    );
  }

  Future<int> deleteCompleted(int cacheUserId) =>
      (delete(pendingOperations)..where(
            (row) =>
                row.cacheUserId.equals(cacheUserId) &
                row.state.equals(PendingOperationState.completed.name),
          ))
          .go();

  Future<int> deleteForUser(int cacheUserId) => (delete(
    pendingOperations,
  )..where((row) => row.cacheUserId.equals(cacheUserId))).go();
}

String? _sanitizeErrorCode(String? value) {
  if (value == null) return null;
  final normalized = value.trim().toUpperCase();
  if (!RegExp(r'^[A-Z0-9_]{1,64}$').hasMatch(normalized)) {
    throw ArgumentError.value(value, 'lastErrorCode', 'Código no válido');
  }
  return normalized;
}
