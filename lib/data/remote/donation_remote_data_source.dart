import '../../models/category.dart';
import '../../models/donation.dart';
import '../../services/category_service.dart';
import '../../services/donation_service.dart';

class DonationRemoteDataSource {
  DonationRemoteDataSource(this._donationService, this._categoryService);

  final DonationService _donationService;
  final CategoryService _categoryService;

  Future<DonationPage> getExplore({
    required int page,
    required int limit,
    int? categoryId,
  }) => _donationService.getAvailableDonations(
    page: page,
    limit: limit,
    categoryId: categoryId,
  );

  Future<List<Category>> getCategories() => _categoryService.getCategories();
}
