import 'package:drift/drift.dart';

import '../../models/category.dart';
import '../../models/donation.dart';
import 'app_database.dart';
import 'conflict_resolver.dart';
import 'tables/local_tables.dart';

class DonationLocalDataSource {
  DonationLocalDataSource(
    this.database, {
    this.conflictResolver = const ConflictResolver(),
  });

  final AppDatabase database;
  final ConflictResolver conflictResolver;

  Stream<List<DonationListItem>> watchExplore({
    required int cacheUserId,
    int? categoryId,
  }) {
    final query =
        database.select(database.localDonations).join([
            innerJoin(
              database.localDonationMemberships,
              database.localDonationMemberships.localDonationId.equalsExp(
                    database.localDonations.localId,
                  ) &
                  database.localDonationMemberships.cacheUserId.equals(
                    cacheUserId,
                  ) &
                  database.localDonationMemberships.collectionType.equalsValue(
                    DonationCollectionType.explore,
                  ),
            ),
          ])
          ..where(database.localDonations.cacheUserId.equals(cacheUserId))
          ..where(database.localDonations.locallyDeleted.equals(false));
    if (categoryId != null) {
      query.where(database.localDonations.categoryId.equals(categoryId));
    }
    query.orderBy([OrderingTerm.desc(database.localDonations.createdAt)]);
    return query.watch().map(
      (rows) => rows
          .map((row) => _toModel(row.readTable(database.localDonations)))
          .toList(growable: false),
    );
  }

  Stream<List<Category>> watchCategories() =>
      (database.select(
        database.localCategories,
      )..orderBy([(row) => OrderingTerm.asc(row.name)])).watch().map(
        (rows) => rows
            .map(
              (row) => Category(
                id: row.remoteId,
                nombre: row.name,
                descripcion: row.description,
              ),
            )
            .toList(growable: false),
      );

  Stream<LocalCollectionMetadataData?> watchExploreMetadata(int cacheUserId) =>
      (database.select(database.localCollectionMetadata)
            ..where((row) => row.cacheUserId.equals(cacheUserId))
            ..where((row) => row.collectionKey.equals('explore')))
          .watchSingleOrNull();

  Future<bool> exploreNeedsRefresh({
    required int cacheUserId,
    required DateTime now,
  }) async {
    final metadata =
        await (database.select(database.localCollectionMetadata)
              ..where((row) => row.cacheUserId.equals(cacheUserId))
              ..where((row) => row.collectionKey.equals('explore')))
            .getSingleOrNull();
    return metadata == null || metadata.expiresAt.isBefore(now);
  }

  Future<void> storeCategories(
    List<Category> categories, {
    required DateTime syncedAt,
    required DateTime expiresAt,
  }) => database.transaction(() async {
    for (final category in categories) {
      await database
          .into(database.localCategories)
          .insertOnConflictUpdate(
            LocalCategoriesCompanion.insert(
              remoteId: Value(category.id),
              name: category.nombre,
              description: Value(category.descripcion),
              lastSyncedAt: syncedAt,
              expiresAt: expiresAt,
            ),
          );
    }
  });

  Future<void> storeExplorePage({
    required int cacheUserId,
    required DonationPage page,
    required int? categoryId,
    required DateTime syncedAt,
    required DateTime expiresAt,
  }) => database.transaction(() async {
    if (page.pagination.page == 1) {
      final memberships = database.delete(database.localDonationMemberships)
        ..where((row) => row.cacheUserId.equals(cacheUserId))
        ..where(
          (row) =>
              row.collectionType.equalsValue(DonationCollectionType.explore),
        );
      if (categoryId != null) {
        memberships.where(
          (row) => row.localDonationId.isInQuery(
            database.selectOnly(database.localDonations)
              ..addColumns([database.localDonations.localId])
              ..where(database.localDonations.categoryId.equals(categoryId)),
          ),
        );
      }
      await memberships.go();
    }

    for (final donation in page.donations) {
      final existing =
          await (database.select(database.localDonations)
                ..where((row) => row.cacheUserId.equals(cacheUserId))
                ..where((row) => row.remoteId.equals(donation.id)))
              .getSingleOrNull();
      final cacheMetadata = LocalDonationsCompanion(
        cacheUserId: Value(cacheUserId),
        clientId: Value(existing?.clientId ?? 'remote-${donation.id}'),
        lastSyncedAt: Value(syncedAt),
        expiresAt: Value(expiresAt),
        lastAccessedAt: Value(syncedAt),
      );
      final decision = existing == null
          ? ConflictDecision.applyRemote
          : conflictResolver.resolveDonation(
              localSyncState: existing.syncState,
              localServerUpdatedAt: existing.serverUpdatedAt,
              remoteServerUpdatedAt: donation.updatedAt,
            );
      final companion = decision == ConflictDecision.applyRemote
          ? cacheMetadata.copyWith(
              remoteId: Value(donation.id),
              syncState: const Value(DonationSyncState.synced),
              locallyDeleted: const Value(false),
              title: Value(donation.titulo),
              city: Value(donation.ciudad),
              status: Value(donation.estado.apiValue),
              categoryId: Value(donation.categoriaId),
              categoryName: Value(donation.categoriaNombre),
              mainImageUrl: Value(donation.imagenPrincipal?.referencia),
              imageCount: Value(donation.cantidadImagenes),
              createdAt: Value(donation.createdAt),
              serverUpdatedAt: Value(donation.updatedAt),
            )
          : cacheMetadata;
      final localId = existing == null
          ? await database.into(database.localDonations).insert(companion)
          : existing.localId;
      if (existing != null) {
        await (database.update(
          database.localDonations,
        )..where((row) => row.localId.equals(localId))).write(companion);
      }
      await database
          .into(database.localDonationMemberships)
          .insertOnConflictUpdate(
            LocalDonationMembershipsCompanion.insert(
              cacheUserId: cacheUserId,
              localDonationId: localId,
              collectionType: DonationCollectionType.explore,
              lastSeenAt: syncedAt,
              expiresAt: expiresAt,
            ),
          );
    }
    await database
        .into(database.localCollectionMetadata)
        .insertOnConflictUpdate(
          LocalCollectionMetadataCompanion.insert(
            cacheUserId: cacheUserId,
            collectionKey: 'explore',
            lastSyncedAt: syncedAt,
            expiresAt: expiresAt,
          ),
        );
  });

  DonationListItem _toModel(LocalDonation row) => DonationListItem(
    id: row.remoteId!,
    titulo: row.title,
    ciudad: row.city,
    estado: DonationStatusJson.fromJson(row.status),
    createdAt:
        row.createdAt ??
        row.lastSyncedAt ??
        DateTime.fromMillisecondsSinceEpoch(0),
    updatedAt:
        row.serverUpdatedAt ??
        row.lastSyncedAt ??
        DateTime.fromMillisecondsSinceEpoch(0),
    categoriaId: row.categoryId,
    categoriaNombre: row.categoryName,
    imagenPrincipal: row.mainImageUrl == null
        ? null
        : DonationImage(id: 0, referencia: row.mainImageUrl!, orden: 0),
    cantidadImagenes: row.imageCount,
  );
}
