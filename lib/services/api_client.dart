import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../config/network_timeouts.dart';
import 'api_error_mapper.dart';
import 'api_exception.dart';
import 'token_storage.dart';

typedef ApiEndpointBuilder = Uri Function(String path);

abstract interface class SessionRecovery {
  Future<String> recoverAfterUnauthorized(String failedAccessToken);
  Future<Never> invalidateAuthentication(ApiException cause);
  Future<Never> invalidateInactiveAccount(ApiException cause);
}

class ApiClient {
  ApiClient({
    http.Client? client,
    Duration timeout = NetworkTimeouts.apiResponse,
    ApiEndpointBuilder endpointBuilder = ApiConfig.endpoint,
    SessionRecovery? sessionRecovery,
    TokenStorage? tokenStorage,
  }) : _client = client ?? http.Client() {
    _timeout = timeout;
    _endpointBuilder = endpointBuilder;
    _sessionRecovery = sessionRecovery;
    _tokenStorage = tokenStorage;
  }

  final http.Client _client;
  late final Duration _timeout;
  late final ApiEndpointBuilder _endpointBuilder;
  late final SessionRecovery? _sessionRecovery;
  late final TokenStorage? _tokenStorage;

  /// Shares transport and configuration while isolating session recovery policy.
  ApiClient withSessionRecovery(SessionRecovery sessionRecovery) => ApiClient(
    client: _client,
    timeout: _timeout,
    endpointBuilder: _endpointBuilder,
    sessionRecovery: sessionRecovery,
    tokenStorage: _tokenStorage,
  );

  /// Shares transport and recovery while selecting the encrypted token source.
  ApiClient withTokenStorage(TokenStorage tokenStorage) => ApiClient(
    client: _client,
    timeout: _timeout,
    endpointBuilder: _endpointBuilder,
    sessionRecovery: _sessionRecovery,
    tokenStorage: tokenStorage,
  );

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
    required Set<int> successStatusCodes,
    ApiRequestContext context = ApiRequestContext.general,
    bool allowSafeBackendMessage = false,
  }) {
    return _request(
      path: path,
      queryParameters: queryParameters,
      headers: headers,
      send: (uri, requestHeaders) => _client.get(uri, headers: requestHeaders),
      successStatusCodes: successStatusCodes,
      context: context,
      allowSafeBackendMessage: allowSafeBackendMessage,
    );
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
    required Set<int> successStatusCodes,
    ApiRequestContext context = ApiRequestContext.general,
    bool allowSafeBackendMessage = false,
  }) {
    return _request(
      path: path,
      headers: headers,
      send: (uri, requestHeaders) =>
          _client.post(uri, headers: requestHeaders, body: jsonEncode(body)),
      successStatusCodes: successStatusCodes,
      context: context,
      allowSafeBackendMessage: allowSafeBackendMessage,
    );
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, String>? headers,
    Object? body,
    required Set<int> successStatusCodes,
    ApiRequestContext context = ApiRequestContext.general,
    bool allowSafeBackendMessage = false,
  }) {
    return _request(
      path: path,
      headers: headers,
      send: (uri, requestHeaders) =>
          _client.patch(uri, headers: requestHeaders, body: jsonEncode(body)),
      successStatusCodes: successStatusCodes,
      context: context,
      allowSafeBackendMessage: allowSafeBackendMessage,
    );
  }

  Future<Map<String, dynamic>> _request({
    required String path,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    required Future<http.Response> Function(
      Uri uri,
      Map<String, String>? headers,
    )
    send,
    required Set<int> successStatusCodes,
    required ApiRequestContext context,
    required bool allowSafeBackendMessage,
  }) async {
    try {
      final endpoint = _endpointBuilder(path);
      final uri = queryParameters == null || queryParameters.isEmpty
          ? endpoint
          : endpoint.replace(queryParameters: queryParameters);
      final requestHeaders = Map<String, String>.of(headers ?? const {});
      final storage = _tokenStorage;
      if (context == ApiRequestContext.protectedSession &&
          storage != null &&
          !requestHeaders.keys.any(
            (key) => key.toLowerCase() == 'authorization',
          )) {
        final token = await storage.readAccessToken();
        if (token == null || token.isEmpty) {
          throw const ApiException(
            ApiErrorType.authentication,
            'Tu sesión ya no es válida. Inicia sesión nuevamente.',
            statusCode: 401,
          );
        }
        requestHeaders['Authorization'] = 'Bearer $token';
      }
      var response = await send(uri, requestHeaders).timeout(_timeout);
      final sessionRecovery = _sessionRecovery;
      var retriedAfterUnauthorized = false;

      if (response.statusCode == 401 &&
          context == ApiRequestContext.protectedSession &&
          sessionRecovery != null) {
        final failedAccessToken = _bearerToken(requestHeaders);
        if (failedAccessToken != null) {
          final accessToken = await sessionRecovery.recoverAfterUnauthorized(
            failedAccessToken,
          );
          final retryHeaders = Map<String, String>.of(requestHeaders)
            ..removeWhere((key, _) => key.toLowerCase() == 'authorization')
            ..['Authorization'] = 'Bearer $accessToken';
          response = await send(uri, retryHeaders).timeout(_timeout);
          retriedAfterUnauthorized = true;
        }
      }

      // HTTP status remains authoritative even when a proxy returns HTML or
      // no body. Decoding supplies optional error details, never the status.
      final body = _decode(response.body);
      if (!successStatusCodes.contains(response.statusCode)) {
        final error = ApiErrorMapper.fromHttp(
          statusCode: response.statusCode,
          body: body,
          context: context,
          allowSafeBackendMessage: allowSafeBackendMessage,
        );
        if (retriedAfterUnauthorized &&
            error.type == ApiErrorType.authentication &&
            sessionRecovery != null) {
          return await sessionRecovery.invalidateAuthentication(error);
        }
        if (context == ApiRequestContext.protectedSession &&
            error.type == ApiErrorType.inactiveAccount &&
            sessionRecovery != null) {
          return await sessionRecovery.invalidateInactiveAccount(error);
        }
        throw error;
      }

      if (body == null ||
          body['success'] != true ||
          !body.containsKey('data')) {
        throw ApiException(
          ApiErrorType.unexpectedResponse,
          ApiErrorMapper.unexpectedResponse.message,
          statusCode: response.statusCode,
        );
      }
      return body;
    } on ApiException {
      rethrow;
    } on ApiConfigException {
      throw ApiErrorMapper.configuration;
    } on TimeoutException {
      throw ApiErrorMapper.timeout;
    } on http.ClientException {
      throw ApiErrorMapper.network;
    } on FormatException {
      throw ApiErrorMapper.unexpectedResponse;
    }
  }

  Map<String, dynamic>? _decode(String source) {
    if (source.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(source);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  String? _bearerToken(Map<String, String>? headers) {
    final authorization = headers?.entries
        .where((entry) => entry.key.toLowerCase() == 'authorization')
        .map((entry) => entry.value)
        .firstOrNull;
    if (authorization == null || !authorization.startsWith('Bearer ')) {
      return null;
    }
    final token = authorization.substring('Bearer '.length);
    return token.isEmpty ? null : token;
  }
}
