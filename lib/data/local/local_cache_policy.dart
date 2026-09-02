enum LocalCacheFreshness { fresh, stale, cleanupCandidate }

/// Centralizes device-clock cache lifetimes. Expiration only changes freshness;
/// callers must not delete or hide a row merely because it is stale.
class LocalCachePolicy {
  const LocalCachePolicy({
    this.exploreTtl = const Duration(minutes: 30),
    this.categoriesTtl = const Duration(hours: 24),
    this.donationDetailTtl = const Duration(minutes: 30),
    this.requestsTtl = const Duration(minutes: 30),
    this.staleRetention = const Duration(days: 7),
  });

  final Duration exploreTtl;
  final Duration categoriesTtl;
  final Duration donationDetailTtl;
  final Duration requestsTtl;

  /// Grace period used only to identify candidates for a future cleanup flow.
  final Duration staleRetention;

  DateTime expiresAt(DateTime lastSyncedAt, Duration ttl) =>
      lastSyncedAt.add(ttl);

  LocalCacheFreshness freshness({
    required DateTime expiresAt,
    required DateTime now,
  }) {
    if (!expiresAt.isBefore(now)) return LocalCacheFreshness.fresh;
    if (expiresAt.add(staleRetention).isBefore(now)) {
      return LocalCacheFreshness.cleanupCandidate;
    }
    return LocalCacheFreshness.stale;
  }

  bool isStale({required DateTime expiresAt, required DateTime now}) =>
      freshness(expiresAt: expiresAt, now: now) != LocalCacheFreshness.fresh;
}
