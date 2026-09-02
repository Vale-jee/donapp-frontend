import 'package:flutter_test/flutter_test.dart';

import 'package:donapp_mobile/data/local/local_cache_policy.dart';

void main() {
  const policy = LocalCachePolicy();
  final syncedAt = DateTime.utc(2026, 9, 2, 12);

  test('centraliza los TTL de las cachés locales', () {
    expect(policy.exploreTtl, const Duration(minutes: 30));
    expect(policy.categoriesTtl, const Duration(hours: 24));
    expect(policy.donationDetailTtl, const Duration(minutes: 30));
    expect(policy.requestsTtl, const Duration(minutes: 30));
  });

  test('calcula expiresAt solo desde el reloj local de sincronización', () {
    expect(
      policy.expiresAt(syncedAt, policy.exploreTtl),
      DateTime.utc(2026, 9, 2, 12, 30),
    );
  });

  test('distingue fresh, stale y cleanupCandidate sin borrar', () {
    final expiresAt = policy.expiresAt(syncedAt, policy.exploreTtl);

    expect(
      policy.freshness(expiresAt: expiresAt, now: expiresAt),
      LocalCacheFreshness.fresh,
    );
    expect(
      policy.freshness(
        expiresAt: expiresAt,
        now: expiresAt.add(const Duration(seconds: 1)),
      ),
      LocalCacheFreshness.stale,
    );
    expect(
      policy.freshness(
        expiresAt: expiresAt,
        now: expiresAt.add(policy.staleRetention + const Duration(seconds: 1)),
      ),
      LocalCacheFreshness.cleanupCandidate,
    );
  });
}
