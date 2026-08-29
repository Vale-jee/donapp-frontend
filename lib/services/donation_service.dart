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

  Future<DonationDetail> createDonation({
    required String title,
    required String description,
    required int categoryId,
    required List<String> imageReferences,
  }) async {
    final accessToken = await _accessToken();
    try {
      final body = await _apiClient.post(
        '/api/donaciones',
        headers: {..._headers(accessToken), 'Content-Type': 'application/json'},
        body: {
          'titulo': title,
          'descripcion': description,
          'categoriaId': categoryId,
          'imagenes': imageReferences,
        },
        successStatusCodes: const {201},
        context: ApiRequestContext.protectedSession,
        allowSafeBackendMessage: true,
      );
      final data = body['data'];
      final donation = data is Map<String, dynamic> ? data['donacion'] : null;
      if (donation is! Map<String, dynamic>) {
        throw ApiErrorMapper.unexpectedResponse;
      }
      return DonationDetail.fromMutationJson(donation);
    } on ApiException {
      rethrow;
    } on FormatException {
      throw ApiErrorMapper.unexpectedResponse;
    }
  }

  Future<DonationDetail> getDonationById(int id) async {
    if (id <= 0) {
      throw const ApiException(
        ApiErrorType.validation,
        'La donación solicitada no es válida.',
      );
    }
    final accessToken = await _accessToken();
    try {
      final body = await _apiClient.get(
        '/api/donaciones/$id',
        headers: _headers(accessToken),
        successStatusCodes: const {200},
        context: ApiRequestContext.protectedSession,
      );
      final data = body['data'];
      final donation = data is Map<String, dynamic> ? data['donacion'] : null;
      if (donation is! Map<String, dynamic>) {
        throw ApiErrorMapper.unexpectedResponse;
      }
      return DonationDetail.fromJson(donation);
    } on ApiException {
      rethrow;
    } on FormatException {
      throw ApiErrorMapper.unexpectedResponse;
    }
  }

  Future<DonationPage> getAvailableDonations({
    int page = 1,
    int limit = 20,
    int? categoryId,
  }) async {
    final accessToken = await _accessToken();
    try {
      final body = await _apiClient.get(
        '/api/donaciones',
        headers: _headers(accessToken),
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

  Future<DonationPage> getOwnDonations({
    int page = 1,
    int limit = 20,
    DonationStatus? status,
  }) async {
    final accessToken = await _accessToken();
    try {
      final body = await _apiClient.get(
        '/api/donaciones/mias',
        headers: _headers(accessToken),
        queryParameters: {
          'page': '$page',
          'limit': '$limit',
          if (status != null) 'estado': status.apiValue,
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

  Future<String> _accessToken() async {
    final accessToken = await _tokenStorage.readAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw const ApiException(
        ApiErrorType.authentication,
        'Tu sesión ya no es válida. Inicia sesión nuevamente.',
        statusCode: 401,
      );
    }
    return accessToken;
  }

  Map<String, String> _headers(String accessToken) => {
    'Accept': 'application/json',
    'Authorization': 'Bearer $accessToken',
  };
}
