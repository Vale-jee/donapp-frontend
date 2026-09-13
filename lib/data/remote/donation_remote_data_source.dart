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
  Future<DonationDetail> getDonationById(int id) =>
      _donationService.getDonationById(id);
  Future<DonationPage> getOwnDonations({
    int page = 1,
    int limit = 20,
    DonationStatus? status,
  }) => _donationService.getOwnDonations(
    page: page,
    limit: limit,
    status: status,
  );
  Future<DonationDetail> createDonation({
    String? clientId,
    required String title,
    required String description,
    required int categoryId,
    required List<String> imageReferences,
  }) => _donationService.createDonation(
    clientId: clientId,
    title: title,
    description: description,
    categoryId: categoryId,
    imageReferences: imageReferences,
  );
}
