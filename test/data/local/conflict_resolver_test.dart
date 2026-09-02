import 'package:flutter_test/flutter_test.dart';

import 'package:donapp_mobile/data/local/conflict_resolver.dart';
import 'package:donapp_mobile/data/local/tables/local_tables.dart';

void main() {
  const resolver = ConflictResolver();
  final timestamp = DateTime.utc(2026, 9, 2, 20);

  test('remoto más nuevo aplica la versión del servidor', () {
    expect(
      resolver.resolveDonation(
        localSyncState: DonationSyncState.synced,
        localServerUpdatedAt: timestamp,
        remoteServerUpdatedAt: timestamp.add(const Duration(seconds: 1)),
      ),
      ConflictDecision.applyRemote,
    );
  });

  test('remoto más antiguo conserva la versión local conocida', () {
    expect(
      resolver.resolveDonation(
        localSyncState: DonationSyncState.synced,
        localServerUpdatedAt: timestamp,
        remoteServerUpdatedAt: timestamp.subtract(const Duration(seconds: 1)),
      ),
      ConflictDecision.keepLocal,
    );
  });

  test('timestamps iguales evitan una escritura de negocio', () {
    expect(
      resolver.resolveDonation(
        localSyncState: DonationSyncState.synced,
        localServerUpdatedAt: timestamp,
        remoteServerUpdatedAt: timestamp,
      ),
      ConflictDecision.unchanged,
    );
  });

  test('timestamp local nulo y remoto válido aplica remoto', () {
    expect(
      resolver.resolveDonation(
        localSyncState: DonationSyncState.synced,
        localServerUpdatedAt: null,
        remoteServerUpdatedAt: timestamp,
      ),
      ConflictDecision.applyRemote,
    );
  });

  test('remoto sin timestamp conserva local sin inventar DateTime.now', () {
    expect(
      resolver.resolveDonation(
        localSyncState: DonationSyncState.synced,
        localServerUpdatedAt: timestamp,
        remoteServerUpdatedAt: null,
      ),
      ConflictDecision.keepLocal,
    );
  });

  test('creaciones pendientes y syncing nunca se sobrescriben', () {
    for (final state in [
      DonationSyncState.pendingCreate,
      DonationSyncState.syncing,
      DonationSyncState.failedRetryable,
      DonationSyncState.failedPermanent,
    ]) {
      expect(
        resolver.resolveDonation(
          localSyncState: state,
          localServerUpdatedAt: timestamp,
          remoteServerUpdatedAt: timestamp.add(const Duration(days: 1)),
        ),
        ConflictDecision.keepLocal,
      );
    }
  });

  test('creación confirmada requiere timestamp real del servidor', () {
    expect(
      resolver.resolveConfirmedCreation(remoteServerUpdatedAt: timestamp),
      ConflictDecision.applyRemote,
    );
    expect(
      resolver.resolveConfirmedCreation(remoteServerUpdatedAt: null),
      ConflictDecision.keepLocal,
    );
  });
}
