import '../models/donation.dart';
import 'api_client.dart';
import 'api_error_mapper.dart';
import 'api_exception.dart';
import 'token_storage.dart';

class DonationService {
  DonationService({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<DonationPage> getAvailableDonations({
    int page = 1,
    int limit = 20,
    int? categoryId,
  }) async {
    final accessToken = await _tokenStorage.readAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw const ApiException(
        ApiErrorType.authentication,
        'Tu sesión ya no es válida. Inicia sesión nuevamente.',
        statusCode: 401,
      );
    }

    try {
      final body = await _apiClient.get(
        '/api/donaciones',
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        queryParameters: {
          'page': '$page',
          'limit': '$limit',
          if (categoryId != null) 'categoriaId': '$categoryId',
        },
        successStatusCodes: const {200},
        context: ApiRequestContext.protectedSession,
      );
      final data = body['data'];
      if (data is! Map<String, dynamic>) {
        throw ApiErrorMapper.unexpectedResponse;
      }
      return DonationPage.fromJson(data);
    } on ApiException {
      rethrow;
    } on FormatException {
      throw ApiErrorMapper.unexpectedResponse;
    }
  }
}
