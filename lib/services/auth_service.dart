import 'package:http/http.dart' as http;

import '../models/auth_session.dart';
import '../models/refreshed_tokens.dart';
import 'api_client.dart';
import 'api_error_mapper.dart';
import 'api_exception.dart';

class AuthService {
  AuthService({http.Client? client, ApiClient? apiClient})
    : assert(client == null || apiClient == null),
      _apiClient = apiClient ?? ApiClient(client: client);

  final ApiClient _apiClient;

  Future<AuthSession> login(String email, String password) async {
    try {
      final body = await _apiClient.post(
        '/api/auth/login',
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: {'email': email.trim().toLowerCase(), 'password': password},
        successStatusCodes: const {200},
        context: ApiRequestContext.login,
        allowSafeBackendMessage: true,
      );
      final data = body['data'];
      if (data is! Map<String, dynamic>) {
        throw ApiErrorMapper.unexpectedResponse;
      }
      return AuthSession.fromJson(data);
    } on ApiException {
      rethrow;
    } on FormatException {
      throw ApiErrorMapper.unexpectedResponse;
    }
  }

  Future<void> register({
    required String nombreCompleto,
    required String nombreVisible,
    required String email,
    required String password,
    required String ciudad,
  }) async {
    try {
      await _apiClient.post(
        '/api/auth/register',
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: {
          'nombreCompleto': nombreCompleto.trim(),
          'nombreVisible': nombreVisible.trim().toLowerCase(),
          'email': email.trim().toLowerCase(),
          'password': password,
          'ciudad': ciudad.trim(),
        },
        successStatusCodes: const {201},
        allowSafeBackendMessage: true,
      );
    } on ApiException {
      rethrow;
    } on FormatException {
      throw ApiErrorMapper.unexpectedResponse;
    }
  }

  Future<RefreshedTokens> refresh(String refreshToken) async {
    try {
      final body = await _apiClient.post(
        '/api/auth/refresh',
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: {'refreshToken': refreshToken},
        successStatusCodes: const {200},
        context: ApiRequestContext.protectedSession,
      );
      final data = body['data'];
      if (data is! Map<String, dynamic>) {
        throw ApiErrorMapper.unexpectedResponse;
      }
      return RefreshedTokens.fromJson(data);
    } on ApiException {
      rethrow;
    } on FormatException {
      throw ApiErrorMapper.unexpectedResponse;
    }
  }

  Future<void> logout(String refreshToken) async {
    await _apiClient.post(
      '/api/auth/logout',
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: {'refreshToken': refreshToken},
      successStatusCodes: const {200},
      context: ApiRequestContext.protectedSession,
    );
  }
}
