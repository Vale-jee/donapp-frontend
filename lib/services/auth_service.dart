import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/auth_session.dart';
import 'api_exception.dart';

class AuthService {
  AuthService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Future<AuthSession> login(String email, String password) async {
    try {
      final response = await _client
          .post(
            ApiConfig.endpoint('/api/auth/login'),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email': email.trim().toLowerCase(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));
      final body = _decodeBody(response.body);
      if (response.statusCode == 200) {
        final data = body['data'];
        if (body['success'] != true || data is! Map<String, dynamic>) {
          throw const FormatException();
        }
        return AuthSession.fromJson(data);
      }
      throw _httpError(response.statusCode, body);
    } on ApiException {
      rethrow;
    } on ApiConfigException catch (error) {
      throw ApiException(ApiErrorType.network, error.message);
    } on TimeoutException {
      throw const ApiException(
        ApiErrorType.timeout,
        'La solicitud tardó demasiado. Verifica tu conexión.',
      );
    } on http.ClientException {
      throw const ApiException(
        ApiErrorType.network,
        'No fue posible conectar con DonApp. Verifica tu conexión.',
      );
    } on FormatException {
      throw const ApiException(
        ApiErrorType.unexpectedResponse,
        'La respuesta del servidor no tiene el formato esperado.',
      );
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
      final response = await _client
          .post(
            ApiConfig.endpoint('/api/auth/register'),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'nombreCompleto': nombreCompleto.trim(),
              'nombreVisible': nombreVisible.trim().toLowerCase(),
              'email': email.trim().toLowerCase(),
              'password': password,
              'ciudad': ciudad.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));
      final body = _decodeBody(response.body);
      if (response.statusCode == 201) {
        if (body['success'] != true || body['data'] is! Map<String, dynamic>) {
          throw const FormatException();
        }
        return;
      }
      throw _registrationHttpError(response.statusCode, body);
    } on ApiException {
      rethrow;
    } on ApiConfigException catch (error) {
      throw ApiException(ApiErrorType.network, error.message);
    } on TimeoutException {
      throw const ApiException(
        ApiErrorType.timeout,
        'La solicitud tardó demasiado. Verifica tu conexión.',
      );
    } on http.ClientException {
      throw const ApiException(
        ApiErrorType.network,
        'No fue posible conectar con DonApp. Verifica tu conexión.',
      );
    } on FormatException {
      throw const ApiException(
        ApiErrorType.unexpectedResponse,
        'La respuesta del servidor no tiene el formato esperado.',
      );
    }
  }

  Map<String, dynamic> _decodeBody(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) throw const FormatException();
    return decoded;
  }

  ApiException _httpError(int status, Map<String, dynamic> body) {
    final backendMessage = body['message'];
    switch (status) {
      case 400:
        return ApiException(
          ApiErrorType.validation,
          backendMessage is String
              ? backendMessage
              : 'Revisa los datos ingresados.',
        );
      case 401:
        return const ApiException(
          ApiErrorType.invalidCredentials,
          'El correo o la contraseña son incorrectos.',
        );
      case 403:
        return const ApiException(
          ApiErrorType.inactiveAccount,
          'Tu cuenta está inactiva. Comunícate con soporte.',
        );
      default:
        return const ApiException(
          ApiErrorType.server,
          'DonApp no está disponible en este momento. Intenta nuevamente.',
        );
    }
  }

  ApiException _registrationHttpError(int status, Map<String, dynamic> body) {
    final backendMessage = body['message'];
    if (status == 400) {
      final errors = body['errors'];
      if (errors is List) {
        for (final error in errors) {
          if (error is Map<String, dynamic> && error['message'] is String) {
            return ApiException(
              ApiErrorType.validation,
              error['message'] as String,
            );
          }
        }
      }
      return ApiException(
        ApiErrorType.validation,
        backendMessage is String
            ? backendMessage
            : 'Revisa los datos ingresados.',
      );
    }
    if (status == 409) {
      return ApiException(
        ApiErrorType.validation,
        backendMessage is String
            ? backendMessage
            : 'El correo o el nombre de usuario ya están en uso.',
      );
    }
    return const ApiException(
      ApiErrorType.server,
      'No fue posible crear la cuenta. Intenta nuevamente.',
    );
  }
}
