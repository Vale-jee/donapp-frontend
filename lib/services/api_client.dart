import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_error_mapper.dart';
import 'api_exception.dart';

typedef ApiEndpointBuilder = Uri Function(String path);

abstract interface class SessionRecovery {
  Future<String> recoverAfterUnauthorized(String failedAccessToken);
  Future<Never> invalidateInactiveAccount(ApiException cause);
}

class ApiClient {
  ApiClient({
    http.Client? client,
    Duration timeout = const Duration(seconds: 15),
    ApiEndpointBuilder endpointBuilder = ApiConfig.endpoint,
    SessionRecovery? sessionRecovery,
  }) : _client = client ?? http.Client() {
    _timeout = timeout;
    _endpointBuilder = endpointBuilder;
    _sessionRecovery = sessionRecovery;
  }

  final http.Client _client;
  late final Duration _timeout;
  late final ApiEndpointBuilder _endpointBuilder;
  late final SessionRecovery? _sessionRecovery;

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
      var response = await send(uri, headers).timeout(_timeout);
      var body = _decode(response.body);
      final sessionRecovery = _sessionRecovery;

      if (response.statusCode == 401 &&
          context == ApiRequestContext.protectedSession &&
          sessionRecovery != null) {
        final failedAccessToken = _bearerToken(headers);
        if (failedAccessToken != null) {
          final accessToken = await sessionRecovery.recoverAfterUnauthorized(
            failedAccessToken,
          );
          final retryHeaders = Map<String, String>.of(headers ?? const {})
            ..['Authorization'] = 'Bearer $accessToken';
          response = await send(uri, retryHeaders).timeout(_timeout);
          body = _decode(response.body);
        }
      }

      if (!successStatusCodes.contains(response.statusCode)) {
        final error = ApiErrorMapper.fromHttp(
          statusCode: response.statusCode,
          body: body,
          context: context,
          allowSafeBackendMessage: allowSafeBackendMessage,
        );
        if (context == ApiRequestContext.protectedSession &&
            error.type == ApiErrorType.inactiveAccount &&
            sessionRecovery != null) {
          return await sessionRecovery.invalidateInactiveAccount(error);
        }
        throw error;
      }

      if (body['success'] != true || !body.containsKey('data')) {
        throw ApiErrorMapper.unexpectedResponse;
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

  Map<String, dynamic> _decode(String source) {
    if (source.trim().isEmpty) throw const FormatException();
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) throw const FormatException();
    return decoded;
  }

  String? _bearerToken(Map<String, String>? headers) {
    final authorization = headers?['Authorization'];
    if (authorization == null || !authorization.startsWith('Bearer ')) {
      return null;
    }
    final token = authorization.substring('Bearer '.length);
    return token.isEmpty ? null : token;
  }
}
