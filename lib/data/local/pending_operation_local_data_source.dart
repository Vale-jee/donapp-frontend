import 'package:drift/drift.dart';

import '../../services/client_id_generator.dart';
import 'app_database.dart';
import 'daos/pending_operations_dao.dart';
import 'tables/local_tables.dart';

class PendingOperationLocalDataSource {
  PendingOperationLocalDataSource({
    required this.dao,
    ClientIdGenerator? idGenerator,
    DateTime Function()? clock,
  }) : _idGenerator = idGenerator ?? const UuidClientIdGenerator(),
       _clock = clock ?? DateTime.now;

  final PendingOperationsDao dao;
  final ClientIdGenerator _idGenerator;
  final DateTime Function() _clock;

  Future<PendingOperation> createPendingDonationOperation({
    required int cacheUserId,
    required String entityClientId,
  }) async {
    if (cacheUserId <= 0) {
      throw ArgumentError.value(cacheUserId, 'cacheUserId');
    }
    if (entityClientId.trim().isEmpty) {
      throw ArgumentError.value(entityClientId, 'entityClientId');
    }

    // This ID identifies one logical operation and must be reused for every
    // retry. It enables future idempotency, but remote deduplication will also
    // require the backend to accept this stable key.
    final operationId = _idGenerator.newOperationId();
    await dao.insertOperation(
      PendingOperationsCompanion.insert(
        operationId: operationId,
        cacheUserId: cacheUserId,
        entityType: PendingOperationEntityType.donation,
        entityClientId: entityClientId,
        operationType: PendingOperationType.createDonation,
        state: const Value(PendingOperationState.pending),
        attemptCount: const Value(0),
        createdAt: _clock(),
      ),
    );
    return (await dao.findByOperationId(operationId))!;
  }
}
