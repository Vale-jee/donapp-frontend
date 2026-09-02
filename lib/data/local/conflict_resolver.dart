import 'tables/local_tables.dart';

enum ConflictDecision { keepLocal, applyRemote, unchanged }

/// DonApp usa la versión más reciente confirmada por el servidor para las
/// entidades sincronizadas. La regla es simple y determinista, pero una futura
/// edición local concurrente podría perderse porque no existe merge por campo.
class ConflictResolver {
  const ConflictResolver();

  ConflictDecision resolveDonation({
    required DonationSyncState localSyncState,
    required DateTime? localServerUpdatedAt,
    required DateTime? remoteServerUpdatedAt,
  }) {
    if (localSyncState != DonationSyncState.synced) {
      return ConflictDecision.keepLocal;
    }
    if (remoteServerUpdatedAt == null) {
      return ConflictDecision.keepLocal;
    }
    if (localServerUpdatedAt == null) {
      return ConflictDecision.applyRemote;
    }
    if (remoteServerUpdatedAt.isAfter(localServerUpdatedAt)) {
      return ConflictDecision.applyRemote;
    }
    if (remoteServerUpdatedAt.isBefore(localServerUpdatedAt)) {
      return ConflictDecision.keepLocal;
    }
    return ConflictDecision.unchanged;
  }

  ConflictDecision resolveConfirmedCreation({
    required DateTime? remoteServerUpdatedAt,
  }) => remoteServerUpdatedAt == null
      ? ConflictDecision.keepLocal
      : ConflictDecision.applyRemote;
}
