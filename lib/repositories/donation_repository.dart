import '../data/local/app_database.dart';
import '../data/local/donation_local_data_source.dart';
import '../data/remote/donation_remote_data_source.dart';
import '../models/category.dart';
import '../models/donation.dart';
import '../services/category_service.dart';
import '../services/donation_service.dart';

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
  DonationRepository(this._local, this._remote, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  factory DonationRepository.create({
    required DonationService donationService,
    required CategoryService categoryService,
  }) {
    final database = AppDatabase();
    return DonationRepository(
      DonationLocalDataSource(database),
      DonationRemoteDataSource(donationService, categoryService),
    ).._ownedDatabase = database;
  }

  static const cacheLifetime = Duration(minutes: 30);
  static const categoryCacheLifetime = Duration(hours: 24);
  final DonationLocalDataSource _local;
  final DonationRemoteDataSource _remote;
  final DateTime Function() _clock;
  AppDatabase? _ownedDatabase;

  Stream<List<DonationListItem>> watchExplore({
    required int cacheUserId,
    int? categoryId,
  }) => _local.watchExplore(cacheUserId: cacheUserId, categoryId: categoryId);

  Stream<List<Category>> watchCategories() => _local.watchCategories();

  Stream<ExploreCacheStatus?> watchExploreStatus(int cacheUserId) => _local
      .watchExploreMetadata(cacheUserId)
      .map(
        (metadata) => metadata == null
            ? null
            : ExploreCacheStatus(
                lastSyncedAt: metadata.lastSyncedAt,
                expiresAt: metadata.expiresAt,
                isStale: metadata.expiresAt.isBefore(_clock()),
              ),
      );

  Future<bool> needsExploreRefresh(int cacheUserId) =>
      _local.exploreNeedsRefresh(cacheUserId: cacheUserId, now: _clock());

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
    await _local.storeExplorePage(
      cacheUserId: cacheUserId,
      page: result,
      categoryId: categoryId,
      syncedAt: now,
      expiresAt: now.add(cacheLifetime),
    );
    return result;
  }

  Future<void> refreshCategories() async {
    final categories = await _remote.getCategories();
    final now = _clock();
    await _local.storeCategories(
      categories,
      syncedAt: now,
      expiresAt: now.add(categoryCacheLifetime),
    );
  }

  Future<void> close() => _ownedDatabase?.close() ?? Future<void>.value();
}
