import 'package:image_picker/image_picker.dart';

import '../data/local/app_database.dart';
import '../data/local/donation_local_data_source.dart';
import '../data/local/local_cache_policy.dart';
import '../data/remote/donation_remote_data_source.dart';
import '../models/category.dart';
import '../models/donation.dart';
import '../services/category_service.dart';
import '../services/donation_service.dart';
import '../services/remote_image_cache.dart';
import '../services/read_cancellation.dart';

class ExploreCacheStatus {
  const ExploreCacheStatus({
    required this.lastSyncedAt,
    required this.expiresAt,
    required this.isStale,
  });

  final DateTime lastSyncedAt;
  final DateTime expiresAt;
  final bool isStale;
}

class DonationRepository {
  DonationRepository(
    this._local,
    this._remote, {
    DateTime Function()? clock,
    this.cachePolicy = const LocalCachePolicy(),
    this.imageCache,
    this.onQueued,
  }) : _clock = clock ?? DateTime.now;

  DonationRepository.remote({DonationRemoteDataSource? remote})
    : _local = null,
      _remote =
          remote ??
          DonationRemoteDataSource(DonationService(), const CategoryService()),
      _clock = DateTime.now,
      cachePolicy = const LocalCachePolicy(),
      imageCache = null;
  factory DonationRepository.fromService(DonationService service) =>
      DonationRepository.remote(
        remote: DonationRemoteDataSource(service, const CategoryService()),
      );
  factory DonationRepository.create({
    DonationService? donationService,
    CategoryService? categoryService,
  }) {
    final database = AppDatabase();
    return DonationRepository(
      DonationLocalDataSource(database),
      DonationRemoteDataSource(
        donationService ?? DonationService(),
        categoryService ?? const CategoryService(),
      ),
      imageCache: RemoteImageCache(),
    ).._ownedDatabase = database;
  }

  final DonationLocalDataSource? _local;
  final DonationRemoteDataSource _remote;
  final DateTime Function() _clock;
  final LocalCachePolicy cachePolicy;
  final RemoteImageCache? imageCache;
  AppDatabase? _ownedDatabase;
  void Function()? onQueued;

  Future<List<Category>> getLocalFirstCategories() async {
    final cached = await _local!.watchCategories().first;
    if (cached.isNotEmpty) return cached;
    await refreshCategories();
    return _local.watchCategories().first;
  }

  Future<PendingOperation> enqueueCreation({
    required int cacheUserId,
    required String city,
    required String title,
    required String description,
    required Category category,
    required List<XFile> images,
  }) async {
    final operation = await _local!.enqueueCreation(
      cacheUserId: cacheUserId,
      city: city,
      title: title,
      description: description,
      category: category,
      images: images,
    );
    onQueued?.call();
    return operation;
  }

  Stream<List<DonationListItem>> watchExplore({
    required int cacheUserId,
    int? categoryId,
  }) => _local!.watchExplore(cacheUserId: cacheUserId, categoryId: categoryId);

  Stream<List<Category>> watchCategories() => _local!.watchCategories();

  Stream<ExploreCacheStatus?> watchExploreStatus(int cacheUserId) => _local!
      .watchExploreMetadata(cacheUserId)
      .map(
        (metadata) => metadata == null
            ? null
            : ExploreCacheStatus(
                lastSyncedAt: metadata.lastSyncedAt,
                expiresAt: metadata.expiresAt,
                isStale: cachePolicy.isStale(
                  expiresAt: metadata.expiresAt,
                  now: _clock(),
                ),
              ),
      );

  Future<bool> needsExploreRefresh(int cacheUserId) =>
      _local!.exploreNeedsRefresh(cacheUserId: cacheUserId, now: _clock());

  Future<DonationPage> refreshExplore({
    required int cacheUserId,
    int page = 1,
    int limit = 20,
    int? categoryId,
  }) async {
    final result = await _remote.getExplore(
      page: page,
      limit: limit,
      categoryId: categoryId,
    );
    final now = _clock();
    ReadCancellation.current?.throwIfCancelled();
    await _local!.storeExplorePage(
      cacheUserId: cacheUserId,
      page: result,
      categoryId: categoryId,
      syncedAt: now,
      expiresAt: cachePolicy.expiresAt(now, cachePolicy.exploreTtl),
    );
    await _cacheRemoteImages(cacheUserId, result.donations);
    return result;
  }

  Future<void> _cacheRemoteImages(
    int cacheUserId,
    List<DonationListItem> donations,
  ) async {
    final cache = imageCache;
    if (cache == null) return;
    await Future.wait(
      donations.map((donation) async {
        final image = donation.imagenPrincipal;
        if (image == null) return;
        try {
          final path = await cache.cache(
            cacheUserId: cacheUserId,
            donationId: donation.id,
            imageId: image.id,
            reference: image.referencia,
          );
          ReadCancellation.current?.throwIfCancelled();
          await _local!.attachRemoteImageCache(
            cacheUserId: cacheUserId,
            donationRemoteId: donation.id,
            remoteImageId: image.id,
            cachedLocalPath: path,
          );
        } on RequestCancelled {
          rethrow;
        } on Object {
          // A failed image download must not invalidate cached donation data.
        }
      }),
    );
  }

  Future<void> refreshCategories() async {
    final categories = await _remote.getCategories();
    ReadCancellation.current?.throwIfCancelled();
    final now = _clock();
    await _local!.storeCategories(
      categories,
      syncedAt: now,
      expiresAt: cachePolicy.expiresAt(now, cachePolicy.categoriesTtl),
    );
  }

  Future<void> close() => _ownedDatabase?.close() ?? Future<void>.value();
  Future<DonationDetail> getDonationById(int id) => _remote.getDonationById(id);
  Future<DonationPage> getOwnDonations({
    int page = 1,
    int limit = 20,
    DonationStatus? status,
  }) => _remote.getOwnDonations(page: page, limit: limit, status: status);
  Future<DonationDetail> createDonation({
    String? clientId,
    required String title,
    required String description,
    required int categoryId,
    required List<String> imageReferences,
  }) => _remote.createDonation(
    clientId: clientId,
    title: title,
    description: description,
    categoryId: categoryId,
    imageReferences: imageReferences,
  );
  Future<DonationPage> getAvailableDonations({
    int page = 1,
    int limit = 20,
    int? categoryId,
  }) => _remote.getExplore(page: page, limit: limit, categoryId: categoryId);
}
