import '../models/request.dart';
import 'api_client.dart';
import 'api_error_mapper.dart';
import 'api_exception.dart';
import 'token_storage.dart';

class RequestService {
  RequestService({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<CreatedRequest> createRequest(int donationId) async {
    if (donationId <= 0) throw _invalidDonationId;
    final token = await _accessToken();
    try {
      final body = await _apiClient.post(
        '/api/solicitudes',
        headers: {..._headers(token), 'Content-Type': 'application/json'},
        body: {'donacionId': donationId},
        successStatusCodes: const {201},
        context: ApiRequestContext.protectedSession,
        allowSafeBackendMessage: true,
      );
      final request = _data(body)['solicitud'];
      if (request is! Map<String, dynamic>) {
        throw ApiErrorMapper.unexpectedResponse;
      }
      return CreatedRequest.fromJson(request);
    } on ApiException {
      rethrow;
    } on FormatException {
      throw ApiErrorMapper.unexpectedResponse;
    }
  }

  Future<RequestPage<SentRequestListItem>> getSentRequests({
    int page = 1,
    int limit = 20,
    RequestStatus? status,
  }) => _getPage(
    '/api/solicitudes/enviadas',
    page: page,
    limit: limit,
    status: status,
    parse: SentRequestListItem.fromJson,
  );

  Future<RequestPage<ReceivedRequestListItem>> getReceivedRequests({
    int page = 1,
    int limit = 20,
    RequestStatus? status,
  }) => _getPage(
    '/api/solicitudes/recibidas',
    page: page,
    limit: limit,
    status: status,
    parse: ReceivedRequestListItem.fromJson,
  );

  Future<RequestPage<T>> _getPage<T extends RequestListItem>(
    String path, {
    required int page,
    required int limit,
    required RequestStatus? status,
    required T Function(Map<String, dynamic>) parse,
  }) async {
    final token = await _accessToken();
    try {
      final body = await _apiClient.get(
        path,
        headers: _headers(token),
        queryParameters: {
          'page': '$page',
          'limit': '$limit',
          if (status != null) 'estado': status.apiValue,
        },
        successStatusCodes: const {200},
        context: ApiRequestContext.protectedSession,
      );
      return RequestPage.fromJson(_data(body), parse);
    } on ApiException {
      rethrow;
    } on FormatException {
      throw ApiErrorMapper.unexpectedResponse;
    }
  }

  Future<RequestDetail> getRequestById(int id) async {
    if (id <= 0) throw _invalidId;
    return _detailRequest('GET', '/api/solicitudes/$id');
  }

  Future<RequestDetail> acceptRequest(int id) =>
      _action(id, '/api/solicitudes/$id/aceptar');
  Future<RequestDetail> rejectRequest(int id) =>
      _action(id, '/api/solicitudes/$id/rechazar');
  Future<RequestDetail> cancelRequest(int id) =>
      _action(id, '/api/solicitudes/$id/cancelar');

  Future<RequestDetail> _action(int id, String path) async {
    if (id <= 0) throw _invalidId;
    return _detailRequest('PATCH', path);
  }

  Future<RequestDetail> _detailRequest(String method, String path) async {
    final token = await _accessToken();
    try {
      final body = method == 'GET'
          ? await _apiClient.get(
              path,
              headers: _headers(token),
              successStatusCodes: const {200},
              context: ApiRequestContext.protectedSession,
            )
          : await _apiClient.patch(
              path,
              headers: {..._headers(token), 'Content-Type': 'application/json'},
              body: const {},
              successStatusCodes: const {200},
              context: ApiRequestContext.protectedSession,
              allowSafeBackendMessage: true,
            );
      final request = _data(body)['solicitud'];
      if (request is! Map<String, dynamic>) {
        throw ApiErrorMapper.unexpectedResponse;
      }
      return RequestDetail.fromJson(request);
    } on ApiException {
      rethrow;
    } on FormatException {
      throw ApiErrorMapper.unexpectedResponse;
    }
  }

  Map<String, dynamic> _data(Map<String, dynamic> body) {
    final data = body['data'];
    if (data is! Map<String, dynamic>) throw ApiErrorMapper.unexpectedResponse;
    return data;
  }

  Future<String> _accessToken() async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        ApiErrorType.authentication,
        'Tu sesión ya no es válida. Inicia sesión nuevamente.',
        statusCode: 401,
      );
    }
    return token;
  }

  Map<String, String> _headers(String token) => {
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };

  static const _invalidId = ApiException(
    ApiErrorType.validation,
    'La solicitud no es válida.',
  );
  static const _invalidDonationId = ApiException(
    ApiErrorType.validation,
    'La donación no es válida.',
  );
}
