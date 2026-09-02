import 'package:drift/drift.dart';

enum DonationSyncState {
  synced,
  pendingCreate,
  syncing,
  failedRetryable,
  failedPermanent,
}

enum DonationCollectionType { explore, myDonations }

enum ImageUploadState {
  remote,
  localPending,
  uploading,
  failedRetryable,
  failedPermanent,
}

enum RequestCollectionType { sent, received }

enum PendingOperationEntityType { donation }

enum PendingOperationType { createDonation }

enum PendingOperationState {
  pending,
  processing,
  retryWait,
  completed,
  failedPermanent,
}

class LocalAuthenticatedUsers extends Table {
  IntColumn get userId => integer()();
  TextColumn get nombreVisible => text()();
  TextColumn get city => text()();
  DateTimeColumn get lastValidatedAt => dateTime()();
  DateTimeColumn get offlineSessionValidUntil => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {userId};
}

class LocalCategories extends Table {
  IntColumn get remoteId => integer()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get lastSyncedAt => dateTime()();
  DateTimeColumn get expiresAt => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {remoteId};
}

class LocalDonations extends Table {
  IntColumn get localId => integer().autoIncrement()();
  IntColumn get cacheUserId => integer()();
  TextColumn get clientId => text()();
  IntColumn get remoteId => integer().nullable()();
  // Device-clock metadata used only to operate synchronization and the cache.
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  DateTimeColumn get expiresAt => dateTime()();
  DateTimeColumn get detailExpiresAt => dateTime().nullable()();
  TextColumn get syncState => textEnum<DonationSyncState>()();
  BoolColumn get locallyDeleted =>
      boolean().withDefault(const Constant(false))();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get city => text()();
  TextColumn get status => text().nullable()();
  IntColumn get categoryId => integer()();
  TextColumn get categoryName => text()();
  TextColumn get mainImageUrl => text().nullable()();
  IntColumn get imageCount => integer().withDefault(const Constant(0))();
  // While pending, createdAt may be provisional. Once confirmed, both fields
  // below are server authority for business data and conflict resolution.
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();
  // Device-clock metadata; never participates in business conflict decisions.
  DateTimeColumn get lastAccessedAt => dateTime().nullable()();
  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {cacheUserId, clientId},
    {cacheUserId, remoteId},
  ];
}

class LocalDonationMemberships extends Table {
  IntColumn get cacheUserId => integer()();
  IntColumn get localDonationId => integer().references(
    LocalDonations,
    #localId,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get collectionType => textEnum<DonationCollectionType>()();
  DateTimeColumn get lastSeenAt => dateTime()();
  DateTimeColumn get expiresAt => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {
    cacheUserId,
    localDonationId,
    collectionType,
  };
}

class LocalDonationImages extends Table {
  IntColumn get localId => integer().autoIncrement()();
  IntColumn get localDonationId => integer().references(
    LocalDonations,
    #localId,
    onDelete: KeyAction.cascade,
  )();
  IntColumn get remoteImageId => integer().nullable()();
  TextColumn get remoteUrl => text().nullable()();
  TextColumn get managedLocalPath => text().nullable()();
  IntColumn get sortOrder => integer()();
  TextColumn get mimeType => text().nullable()();
  IntColumn get sizeBytes => integer().nullable()();
  TextColumn get uploadState => textEnum<ImageUploadState>()();
}

class LocalRequests extends Table {
  IntColumn get cacheUserId => integer()();
  IntColumn get remoteId => integer()();
  TextColumn get collectionType => textEnum<RequestCollectionType>()();
  BoolColumn get detailCached => boolean().withDefault(const Constant(false))();
  TextColumn get status => text()();
  TextColumn get cancellationCause => text().nullable()();
  DateTimeColumn get acceptedAt => dateTime().nullable()();
  DateTimeColumn get rejectedAt => dateTime().nullable()();
  DateTimeColumn get cancelledAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get serverUpdatedAt => dateTime()();
  IntColumn get donationRemoteId => integer()();
  TextColumn get donationTitle => text()();
  TextColumn get donationStatus => text()();
  TextColumn get donationMainImageUrl => text().nullable()();
  IntColumn get participantRemoteId => integer()();
  TextColumn get participantVisibleName => text()();
  TextColumn get participantCity => text()();
  TextColumn get participantProfilePhotoUrl => text().nullable()();
  DateTimeColumn get lastSyncedAt => dateTime()();
  DateTimeColumn get expiresAt => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {cacheUserId, remoteId, collectionType};
}

class LocalCollectionMetadata extends Table {
  IntColumn get cacheUserId => integer()();
  TextColumn get collectionKey => text()();
  DateTimeColumn get lastSyncedAt => dateTime()();
  DateTimeColumn get expiresAt => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {cacheUserId, collectionKey};
}

@TableIndex(
  name: 'pending_operations_processable_idx',
  columns: {#cacheUserId, #state, #nextAttemptAt},
)
@TableIndex(
  name: 'pending_operations_entity_idx',
  columns: {#cacheUserId, #entityClientId},
)
class PendingOperations extends Table {
  IntColumn get localId => integer().autoIncrement()();
  TextColumn get operationId => text()();
  IntColumn get cacheUserId => integer()();
  TextColumn get entityType => textEnum<PendingOperationEntityType>()();
  TextColumn get entityClientId => text()();
  TextColumn get operationType => textEnum<PendingOperationType>()();
  TextColumn get state => textEnum<PendingOperationState>().withDefault(
    Constant(PendingOperationState.pending.name),
  )();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  TextColumn get lastErrorCode => text().nullable()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {operationId},
  ];
}
