import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../config/network_timeouts.dart';
import 'api_error_mapper.dart';
import 'api_exception.dart';
import 'token_storage.dart';
import 'http_request_logger.dart';

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
    HttpRequestLogger logger = const HttpRequestLogger(),
    bool retryReads = true,
    Future<void> Function(Duration)? retryDelay,
  }) : _client = client ?? http.Client() {
    _timeout = timeout;
    _endpointBuilder = endpointBuilder;
    _sessionRecovery = sessionRecovery;
    _tokenStorage = tokenStorage;
    _logger = logger;
    _retryReads = retryReads;
    _retryDelay = retryDelay ?? Future<void>.delayed;
  }

  final http.Client _client;
  late final Duration _timeout;
  late final ApiEndpointBuilder _endpointBuilder;
  late final SessionRecovery? _sessionRecovery;
  late final TokenStorage? _tokenStorage;
  late final HttpRequestLogger _logger;
  late final bool _retryReads;
  late final Future<void> Function(Duration) _retryDelay;

  static const maxReadAttempts = 3;
  static const _readBackoff = [
    Duration(milliseconds: 500),
    Duration(seconds: 1),
  ];

  /// Shares transport and configuration while isolating session recovery policy.
  ApiClient withSessionRecovery(SessionRecovery sessionRecovery) => ApiClient(
    client: _client,
    timeout: _timeout,
    endpointBuilder: _endpointBuilder,
    sessionRecovery: sessionRecovery,
    tokenStorage: _tokenStorage,
    logger: _logger,
    retryReads: _retryReads,
    retryDelay: _retryDelay,
  );

  /// Shares transport and recovery while selecting the encrypted token source.
  ApiClient withTokenStorage(TokenStorage tokenStorage) => ApiClient(
    client: _client,
    timeout: _timeout,
    endpointBuilder: _endpointBuilder,
    sessionRecovery: _sessionRecovery,
    tokenStorage: tokenStorage,
    logger: _logger,
    retryReads: _retryReads,
    retryDelay: _retryDelay,
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
      method: 'GET',
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
      method: 'POST',
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
      method: 'PATCH',
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
    required String method,
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
      var response = await _sendWithReadRetry(
        method,
        path,
        () => send(uri, requestHeaders),
      );
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
          response = await _sendLogged(
            method,
            path,
            () => send(uri, retryHeaders),
          );
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
    } on SocketException {
      throw ApiErrorMapper.network;
    } on FormatException {
      throw ApiErrorMapper.unexpectedResponse;
    }
  }

  Future<http.Response> _sendLogged(
    String method,
    String path,
    Future<http.Response> Function() send,
  ) async {
    final timer = Stopwatch()..start();
    int? statusCode;
    try {
      final response = await send().timeout(_timeout);
      statusCode = response.statusCode;
      return response;
    } finally {
      timer.stop();
      _logger.record(
        method: method,
        path: path,
        statusCode: statusCode,
        elapsed: timer.elapsed,
      );
    }
  }

  // Only the first transport phase can retry. A 401 leaves this loop and uses
  // the existing single session recovery replay, never another retry budget.
  Future<http.Response> _sendWithReadRetry(
    String method,
    String path,
    Future<http.Response> Function() send,
  ) async {
    final attempts = method == 'GET' && _retryReads ? maxReadAttempts : 1;
    for (var attempt = 0; ; attempt++) {
      Duration delay;
      try {
        final response = await _sendLogged(method, path, send);
        if (attempt + 1 >= attempts) return response;
        delay = _readBackoff[attempt];
        if (response.statusCode == 429) {
          // Do not guess a rate-limit window or shorten the server's wait.
          final retryAfter = response.headers.entries
              .where((entry) => entry.key.toLowerCase() == 'retry-after')
              .map((entry) => entry.value)
              .firstOrNull;
          final seconds = int.tryParse(retryAfter ?? '');
          if (seconds == null || seconds < 0 || seconds > 5) return response;
          final requested = Duration(seconds: seconds);
          if (requested > delay) delay = requested;
        } else if (!const {500, 502, 503, 504}.contains(response.statusCode)) {
          return response;
        }
      } on TimeoutException {
        if (attempt + 1 >= attempts) rethrow;
        delay = _readBackoff[attempt];
      } on http.ClientException {
        if (attempt + 1 >= attempts) rethrow;
        delay = _readBackoff[attempt];
      } on SocketException {
        if (attempt + 1 >= attempts) rethrow;
        delay = _readBackoff[attempt];
      }
      await _retryDelay(delay);
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
