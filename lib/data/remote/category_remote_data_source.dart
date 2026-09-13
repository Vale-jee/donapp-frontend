import '../../models/category.dart';
import '../../services/category_service.dart';

class CategoryRemoteDataSource {
  const CategoryRemoteDataSource([CategoryService? service])
    : _service = service;
  final CategoryService? _service;
  CategoryService get _delegate => _service ?? const CategoryService();
  Future<List<Category>> getCategories() => _delegate.getCategories();
}
