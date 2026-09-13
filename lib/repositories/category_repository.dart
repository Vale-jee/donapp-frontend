import '../models/category.dart';
import '../services/category_service.dart';
import '../data/remote/category_remote_data_source.dart';

class CategoryRepository {
  const CategoryRepository({CategoryRemoteDataSource? remote})
    : _remote = remote ?? const CategoryRemoteDataSource();
  final CategoryRemoteDataSource _remote;
  CategoryRemoteDataSource get _delegate => _remote;
  factory CategoryRepository.fromService(CategoryService service) =>
      CategoryRepository(remote: CategoryRemoteDataSource(service));
  Future<List<Category>> getCategories() => _delegate.getCategories();
}
