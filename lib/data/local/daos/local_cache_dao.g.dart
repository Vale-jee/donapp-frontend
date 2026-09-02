// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_cache_dao.dart';

// ignore_for_file: type=lint
mixin _$LocalCacheDaoMixin on DatabaseAccessor<AppDatabase> {
  $LocalAuthenticatedUsersTable get localAuthenticatedUsers =>
      attachedDatabase.localAuthenticatedUsers;
  $LocalCategoriesTable get localCategories => attachedDatabase.localCategories;
  $LocalDonationsTable get localDonations => attachedDatabase.localDonations;
  $LocalDonationMembershipsTable get localDonationMemberships =>
      attachedDatabase.localDonationMemberships;
  $LocalDonationImagesTable get localDonationImages =>
      attachedDatabase.localDonationImages;
  $LocalRequestsTable get localRequests => attachedDatabase.localRequests;
  $LocalCollectionMetadataTable get localCollectionMetadata =>
      attachedDatabase.localCollectionMetadata;
  LocalCacheDaoManager get managers => LocalCacheDaoManager(this);
}

class LocalCacheDaoManager {
  final _$LocalCacheDaoMixin _db;
  LocalCacheDaoManager(this._db);
  $$LocalAuthenticatedUsersTableTableManager get localAuthenticatedUsers =>
      $$LocalAuthenticatedUsersTableTableManager(
        _db.attachedDatabase,
        _db.localAuthenticatedUsers,
      );
  $$LocalCategoriesTableTableManager get localCategories =>
      $$LocalCategoriesTableTableManager(
        _db.attachedDatabase,
        _db.localCategories,
      );
  $$LocalDonationsTableTableManager get localDonations =>
      $$LocalDonationsTableTableManager(
        _db.attachedDatabase,
        _db.localDonations,
      );
  $$LocalDonationMembershipsTableTableManager get localDonationMemberships =>
      $$LocalDonationMembershipsTableTableManager(
        _db.attachedDatabase,
        _db.localDonationMemberships,
      );
  $$LocalDonationImagesTableTableManager get localDonationImages =>
      $$LocalDonationImagesTableTableManager(
        _db.attachedDatabase,
        _db.localDonationImages,
      );
  $$LocalRequestsTableTableManager get localRequests =>
      $$LocalRequestsTableTableManager(_db.attachedDatabase, _db.localRequests);
  $$LocalCollectionMetadataTableTableManager get localCollectionMetadata =>
      $$LocalCollectionMetadataTableTableManager(
        _db.attachedDatabase,
        _db.localCollectionMetadata,
      );
}
