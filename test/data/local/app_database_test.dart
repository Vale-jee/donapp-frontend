import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'package:donapp_mobile/data/local/app_database.dart';
import 'package:donapp_mobile/data/local/tables/local_tables.dart';

void main() {
  late AppDatabase db;
  late DateTime now;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    now = DateTime.utc(2026, 9, 2, 12);
  });
  tearDown(() => db.close());

  LocalDonationsCompanion donation({
    required int user,
    required String clientId,
    int? remoteId,
    DonationSyncState state = DonationSyncState.synced,
  }) => LocalDonationsCompanion.insert(
    cacheUserId: user,
    clientId: clientId,
    remoteId: Value(remoteId),
    expiresAt: now.add(const Duration(hours: 1)),
    syncState: state,
    title: 'Mesa',
    city: 'Bogotá',
    status: remoteId == null ? const Value.absent() : const Value('PUBLICADA'),
    categoryId: 7,
    categoryName: 'Hogar',
    lastSyncedAt: remoteId == null ? const Value.absent() : Value(now),
  );

  test('crea la base e inserta perfil mínimo y categoría', () async {
    expect(db.schemaVersion, 3);
    await db.localCacheDao.putAuthenticatedUser(
      LocalAuthenticatedUsersCompanion.insert(
        userId: const Value(1),
        nombreVisible: 'Ana',
        city: 'Bogotá',
        lastValidatedAt: now,
        offlineSessionValidUntil: now.add(const Duration(days: 1)),
      ),
    );
    await db.localCacheDao.putCategory(
      LocalCategoriesCompanion.insert(
        remoteId: const Value(7),
        name: 'Hogar',
        lastSyncedAt: now,
        expiresAt: now.add(const Duration(hours: 6)),
      ),
    );
    expect(
      (await db.select(db.localAuthenticatedUsers).getSingle()).nombreVisible,
      'Ana',
    );
    expect(
      (await db.select(db.localCategories).getSingle()).lastSyncedAt.toUtc(),
      now,
    );
  });

  test('guarda donación remota y offline con los campos de control', () async {
    await db.localCacheDao.putDonation(
      donation(user: 1, clientId: 'remote-1', remoteId: 10),
    );
    await db.localCacheDao.putDonation(
      donation(
        user: 1,
        clientId: 'offline-1',
        state: DonationSyncState.pendingCreate,
      ),
    );
    final rows = await db.localCacheDao.donationsFor(1);
    expect(rows, hasLength(2));
    final offline = rows.singleWhere((row) => row.remoteId == null);
    expect(offline.syncState, DonationSyncState.pendingCreate);
    expect(offline.locallyDeleted, isFalse);
    expect(
      rows.singleWhere((row) => row.remoteId == 10).lastSyncedAt?.toUtc(),
      now,
    );
  });

  test(
    'aplica unicidad por usuario para clientId y remoteId no nulo',
    () async {
      await db.localCacheDao.putDonation(
        donation(user: 1, clientId: 'a', remoteId: 10),
      );
      await expectLater(
        db.localCacheDao.putDonation(
          donation(user: 1, clientId: 'a', remoteId: 11),
        ),
        throwsA(isA<sqlite.SqliteException>()),
      );
      await expectLater(
        db.localCacheDao.putDonation(
          donation(user: 1, clientId: 'b', remoteId: 10),
        ),
        throwsA(isA<sqlite.SqliteException>()),
      );
      await db.localCacheDao.putDonation(
        donation(user: 2, clientId: 'a', remoteId: 10),
      );
      expect(await db.localCacheDao.donationsFor(2), hasLength(1));
    },
  );

  test('permite múltiples remoteId nulos', () async {
    await db.localCacheDao.putDonation(
      donation(user: 1, clientId: 'offline-a'),
    );
    await db.localCacheDao.putDonation(
      donation(user: 1, clientId: 'offline-b'),
    );
    expect(await db.localCacheDao.donationsFor(1), hasLength(2));
  });

  test('relaciona imágenes por localDonationId y las ordena', () async {
    final id = await db.localCacheDao.putDonation(
      donation(user: 1, clientId: 'images'),
    );
    await db.localCacheDao.putImage(
      LocalDonationImagesCompanion.insert(
        localDonationId: id,
        sortOrder: 2,
        uploadState: ImageUploadState.localPending,
        managedLocalPath: const Value('/private/b.jpg'),
      ),
    );
    await db.localCacheDao.putImage(
      LocalDonationImagesCompanion.insert(
        localDonationId: id,
        sortOrder: 1,
        uploadState: ImageUploadState.remote,
        remoteUrl: const Value('https://example.test/a.jpg'),
      ),
    );
    expect((await db.localCacheDao.imagesFor(id)).map((row) => row.sortOrder), [
      1,
      2,
    ]);
    await expectLater(
      db.localCacheDao.putImage(
        LocalDonationImagesCompanion.insert(
          localDonationId: 999,
          sortOrder: 1,
          uploadState: ImageUploadState.localPending,
        ),
      ),
      throwsA(isA<sqlite.SqliteException>()),
    );
  });

  test('evita membresías duplicadas y las aísla por usuario', () async {
    final id = await db.localCacheDao.putDonation(
      donation(user: 1, clientId: 'member'),
    );
    final membership = LocalDonationMembershipsCompanion.insert(
      cacheUserId: 1,
      localDonationId: id,
      collectionType: DonationCollectionType.explore,
      lastSeenAt: now,
      expiresAt: now.add(const Duration(hours: 1)),
    );
    await db.localCacheDao.putMembership(membership);
    await db.localCacheDao.putMembership(membership);
    await db.localCacheDao.putMembership(
      membership.copyWith(cacheUserId: const Value(2)),
    );
    expect(await db.select(db.localDonationMemberships).get(), hasLength(2));
  });

  test(
    'guarda solicitudes básicas y metadatos separados por usuario',
    () async {
      LocalRequestsCompanion request(int user) => LocalRequestsCompanion.insert(
        cacheUserId: user,
        remoteId: 50,
        collectionType: RequestCollectionType.sent,
        status: 'PENDIENTE',
        createdAt: now,
        serverUpdatedAt: now,
        donationRemoteId: 10,
        donationTitle: 'Mesa',
        donationStatus: 'PUBLICADA',
        participantRemoteId: 2,
        participantVisibleName: 'Luis',
        participantCity: 'Cali',
        lastSyncedAt: now,
        expiresAt: now.add(const Duration(hours: 1)),
      );
      await db.localCacheDao.putRequest(request(1));
      await db.localCacheDao.putRequest(request(2));
      final rows = await db.select(db.localRequests).get();
      expect(rows.map((row) => row.cacheUserId), containsAll([1, 2]));
      expect(rows.first.lastSyncedAt.toUtc(), now);
    },
  );
}
