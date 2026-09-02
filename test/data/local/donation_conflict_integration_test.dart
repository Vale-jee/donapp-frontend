import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:donapp_mobile/data/local/app_database.dart';
import 'package:donapp_mobile/data/local/donation_local_data_source.dart';
import 'package:donapp_mobile/data/local/tables/local_tables.dart';
import 'package:donapp_mobile/models/donation.dart';

void main() {
  late AppDatabase db;
  late DonationLocalDataSource source;
  final localTimestamp = DateTime.utc(2026, 9, 2, 20);
  final syncTime = DateTime.utc(2026, 9, 2, 21);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    source = DonationLocalDataSource(db);
  });
  tearDown(() => db.close());

  Future<int> seed() => db
      .into(db.localDonations)
      .insert(
        LocalDonationsCompanion.insert(
          cacheUserId: 1,
          clientId: 'stable-client-id',
          remoteId: const Value(10),
          lastSyncedAt: Value(localTimestamp),
          expiresAt: localTimestamp.add(const Duration(minutes: 30)),
          syncState: DonationSyncState.synced,
          title: 'Versión local',
          description: const Value('Descripción local conservada.'),
          city: 'Bogotá',
          status: const Value('PUBLICADA'),
          categoryId: 4,
          categoryName: 'Muebles',
          createdAt: Value(localTimestamp.subtract(const Duration(days: 1))),
          serverUpdatedAt: Value(localTimestamp),
        ),
      );

  DonationPage page({required String title, required DateTime updatedAt}) =>
      DonationPage(
        donations: [
          DonationListItem(
            id: 10,
            titulo: title,
            ciudad: 'Bogotá',
            estado: DonationStatus.publicada,
            createdAt: localTimestamp.subtract(const Duration(days: 1)),
            updatedAt: updatedAt,
            categoriaId: 4,
            categoriaNombre: 'Muebles',
            imagenPrincipal: null,
            cantidadImagenes: 0,
          ),
        ],
        pagination: const DonationPagination(
          page: 1,
          limit: 20,
          total: 1,
          totalPages: 1,
        ),
      );

  test('Explore no retrocede negocio pero siempre renueva caché', () async {
    final localId = await seed();
    final expiresAt = syncTime.add(const Duration(minutes: 30));
    await source.storeExplorePage(
      cacheUserId: 1,
      page: page(
        title: 'Remoto antiguo',
        updatedAt: localTimestamp.subtract(const Duration(minutes: 1)),
      ),
      categoryId: null,
      syncedAt: syncTime,
      expiresAt: expiresAt,
    );

    var saved = await db.select(db.localDonations).getSingle();
    expect(saved.title, 'Versión local');
    expect(saved.serverUpdatedAt?.toUtc(), localTimestamp);
    expect(saved.lastSyncedAt?.toUtc(), syncTime);
    expect(saved.expiresAt.toUtc(), expiresAt);
    expect(saved.localId, localId);
    expect(saved.clientId, 'stable-client-id');
    expect(await db.select(db.localDonationMemberships).get(), hasLength(1));

    final secondSync = syncTime.add(const Duration(minutes: 1));
    await source.storeExplorePage(
      cacheUserId: 1,
      page: page(title: 'Mismo timestamp', updatedAt: localTimestamp),
      categoryId: null,
      syncedAt: secondSync,
      expiresAt: secondSync.add(const Duration(minutes: 30)),
    );
    saved = await db.select(db.localDonations).getSingle();
    expect(saved.title, 'Versión local');
    expect(saved.lastSyncedAt?.toUtc(), secondSync);

    final newerTimestamp = localTimestamp.add(const Duration(minutes: 1));
    await source.storeExplorePage(
      cacheUserId: 1,
      page: page(title: 'Remoto nuevo', updatedAt: newerTimestamp),
      categoryId: null,
      syncedAt: secondSync,
      expiresAt: expiresAt,
    );
    saved = await db.select(db.localDonations).getSingle();
    expect(saved.title, 'Remoto nuevo');
    expect(saved.serverUpdatedAt?.toUtc(), newerTimestamp);
    expect(saved.localId, localId);
    expect(saved.clientId, 'stable-client-id');
    expect(await db.select(db.localDonations).get(), hasLength(1));
  });
}
