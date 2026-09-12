import '../models/donation.dart';
import 'api_client.dart';
import 'api_error_mapper.dart';
import 'api_exception.dart';
import 'token_storage.dart';

class DonationService {
  DonationService({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = tokenStorage != null
          ? (apiClient ?? ApiClient()).withTokenStorage(tokenStorage)
          : apiClient ?? ApiClient(tokenStorage: TokenStorage());

  final ApiClient _apiClient;

  Future<DonationDetail> createDonation({
    String? clientId,
    required String title,
    required String description,
    required int categoryId,
    required List<String> imageReferences,
  }) async {
    try {
      final body = await _apiClient.post(
        '/api/donaciones',
        headers: {..._headers, 'Content-Type': 'application/json'},
        body: {
          'clientId': ?clientId,
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
    try {
      final body = await _apiClient.get(
        '/api/donaciones/$id',
        headers: _headers,
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
    try {
      final body = await _apiClient.get(
        '/api/donaciones',
        headers: _headers,
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
    try {
      final body = await _apiClient.get(
        '/api/donaciones/mias',
        headers: _headers,
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

  static const _headers = {'Accept': 'application/json'};
}
