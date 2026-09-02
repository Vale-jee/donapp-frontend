import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/local_tables.dart';

part 'local_cache_dao.g.dart';

@DriftAccessor(
  tables: [
    LocalAuthenticatedUsers,
    LocalCategories,
    LocalDonations,
    LocalDonationMemberships,
    LocalDonationImages,
    LocalRequests,
    LocalCollectionMetadata,
  ],
)
class LocalCacheDao extends DatabaseAccessor<AppDatabase>
    with _$LocalCacheDaoMixin {
  LocalCacheDao(super.db);

  Future<void> putAuthenticatedUser(LocalAuthenticatedUsersCompanion value) =>
      into(localAuthenticatedUsers).insertOnConflictUpdate(value);
  Future<void> putCategory(LocalCategoriesCompanion value) =>
      into(localCategories).insertOnConflictUpdate(value);
  Future<int> putDonation(LocalDonationsCompanion value) =>
      into(localDonations).insert(value);
  Future<void> putMembership(LocalDonationMembershipsCompanion value) =>
      into(localDonationMemberships).insertOnConflictUpdate(value);
  Future<int> putImage(LocalDonationImagesCompanion value) =>
      into(localDonationImages).insert(value);
  Future<void> putRequest(LocalRequestsCompanion value) =>
      into(localRequests).insertOnConflictUpdate(value);
  Future<void> putCollectionMetadata(LocalCollectionMetadataCompanion value) =>
      into(localCollectionMetadata).insertOnConflictUpdate(value);

  Future<List<LocalDonationImage>> imagesFor(int localDonationId) =>
      (select(localDonationImages)
            ..where((row) => row.localDonationId.equals(localDonationId))
            ..orderBy([(row) => OrderingTerm.asc(row.sortOrder)]))
          .get();

  Future<List<LocalDonation>> donationsFor(int cacheUserId) => (select(
    localDonations,
  )..where((row) => row.cacheUserId.equals(cacheUserId))).get();
}
