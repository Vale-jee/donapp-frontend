import '../models/category.dart';
import 'api_client.dart';
import 'api_error_mapper.dart';
import 'api_exception.dart';

class CategoryService {
  // Keep the public injection name while storing the dependency privately.
  // ignore: prefer_initializing_formals
  const CategoryService({ApiClient? apiClient}) : _apiClient = apiClient;

  final ApiClient? _apiClient;

  Future<List<Category>> getCategories() async {
    try {
      final body = await (_apiClient ?? ApiClient()).get(
        '/api/categorias',
        headers: const {'Accept': 'application/json'},
        successStatusCodes: const {200},
      );
      final data = body['data'];
      if (data is! Map<String, dynamic> || data['categorias'] is! List) {
        throw ApiErrorMapper.unexpectedResponse;
      }
      return (data['categorias'] as List)
          .map((item) {
            if (item is! Map<String, dynamic>) throw const FormatException();
            return Category.fromJson(item);
          })
          .toList(growable: false);
    } on ApiException {
      rethrow;
    } on FormatException {
      throw ApiErrorMapper.unexpectedResponse;
    }
  }
}

@Deprecated('Use ApiException para manejar errores de servicios.')
typedef CategoryServiceException = ApiException;
