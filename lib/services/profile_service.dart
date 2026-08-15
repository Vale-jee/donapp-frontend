import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/user_profile.dart';
import 'api_exception.dart';

class ProfileService {
  ProfileService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Future<UserProfile> getProfile(String accessToken) async {
    try {
      final response = await _client
          .get(
            ApiConfig.endpoint('/api/usuarios/perfil'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
          )
          .timeout(const Duration(seconds: 15));
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) throw const FormatException();
      if (response.statusCode == 200) {
        final data = decoded['data'];
        if (decoded['success'] != true ||
            data is! Map<String, dynamic> ||
            data['usuario'] is! Map<String, dynamic>) {
          throw const FormatException();
        }
        return UserProfile.fromJson(data['usuario'] as Map<String, dynamic>);
      }
      if (response.statusCode == 401) {
        throw const ApiException(
          ApiErrorType.authentication,
          'No fue posible validar tu sesión. Inicia sesión nuevamente.',
        );
      }
      if (response.statusCode == 403) {
        throw const ApiException(
          ApiErrorType.inactiveAccount,
          'Tu cuenta está inactiva. Comunícate con soporte.',
        );
      }
      throw const ApiException(
        ApiErrorType.server,
        'No fue posible consultar tu perfil. Intenta nuevamente.',
      );
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
}
