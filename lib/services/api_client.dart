import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_error_mapper.dart';
import 'api_exception.dart';

typedef ApiEndpointBuilder = Uri Function(String path);

class ApiClient {
  ApiClient({
    http.Client? client,
    Duration timeout = const Duration(seconds: 15),
    ApiEndpointBuilder endpointBuilder = ApiConfig.endpoint,
  }) : _client = client ?? http.Client() {
    _timeout = timeout;
    _endpointBuilder = endpointBuilder;
  }

  final http.Client _client;
  late final Duration _timeout;
  late final ApiEndpointBuilder _endpointBuilder;

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
      send: (uri) => _client.get(uri, headers: headers),
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
      send: (uri) =>
          _client.post(uri, headers: headers, body: jsonEncode(body)),
      successStatusCodes: successStatusCodes,
      context: context,
      allowSafeBackendMessage: allowSafeBackendMessage,
    );
  }

  Future<Map<String, dynamic>> _request({
    required String path,
    Map<String, String>? queryParameters,
    required Future<http.Response> Function(Uri uri) send,
    required Set<int> successStatusCodes,
    required ApiRequestContext context,
    required bool allowSafeBackendMessage,
  }) async {
    try {
      final endpoint = _endpointBuilder(path);
      final uri = queryParameters == null || queryParameters.isEmpty
          ? endpoint
          : endpoint.replace(queryParameters: queryParameters);
      final response = await send(uri).timeout(_timeout);
      final body = _decode(response.body);

      if (!successStatusCodes.contains(response.statusCode)) {
        throw ApiErrorMapper.fromHttp(
          statusCode: response.statusCode,
          body: body,
          context: context,
          allowSafeBackendMessage: allowSafeBackendMessage,
        );
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
}
