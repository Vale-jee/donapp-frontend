import 'package:donapp_mobile/services/api_client.dart';
import 'package:donapp_mobile/services/api_exception.dart';
import 'package:donapp_mobile/services/auth_service.dart';
import 'package:donapp_mobile/services/category_service.dart';
import 'package:donapp_mobile/services/profile_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('AuthService usa mensaje de credenciales para 401 de Login', () async {
    final service = AuthService(apiClient: _errorClient(401));
    final error = await _capture(
      service.login('ana@example.com', 'incorrecta'),
    );

    expect(error.type, ApiErrorType.invalidCredentials);
    expect(error.message, 'El correo o la contraseña son incorrectos.');
  });

  test('ProfileService usa mensaje de sesión para 401', () async {
    final service = ProfileService(apiClient: _errorClient(401));
    final error = await _capture(service.getProfile('access'));

    expect(error.type, ApiErrorType.authentication);
    expect(
      error.message,
      'Tu sesión ya no es válida. Inicia sesión nuevamente.',
    );
  });

  test('AuthService conserva error seguro por campo en Registro', () async {
    final service = AuthService(
      apiClient: _client(
        400,
        '{"success":false,"status":400,"message":"Datos inválidos.",'
        '"data":null,"errors":[{"field":"email",'
        '"message":"El correo ya está en uso."}]}',
      ),
    );

    final error = await _capture(
      service.register(
        nombreCompleto: 'Ana Pérez',
        nombreVisible: 'ana',
        email: 'ana@example.com',
        password: 'Clave1234',
        ciudad: 'Bogotá',
      ),
    );
    expect(error.message, 'El correo ya está en uso.');
    expect(error.fieldErrors.single.field, 'email');
  });

  test('CategoryService devuelve categorías con el contrato válido', () async {
    final service = CategoryService(
      apiClient: _client(
        200,
        '{"success":true,"message":"Bien","data":{"categorias":['
        '{"id":1,"nombre":"Ropa","descripcion":null}]}}',
      ),
    );
    final categories = await service.getCategories();
    expect(categories.single.nombre, 'Ropa');
  });

  test('CategoryService nunca muestra términos técnicos prohibidos', () async {
    const prohibited = [
      'http',
      'api',
      'backend',
      'json',
      'token',
      'status code',
      'adb reverse',
      'api_base_url',
      'dart-define',
    ];

    for (final status in [400, 401, 403, 404, 409, 429, 500, 503]) {
      final service = CategoryService(apiClient: _errorClient(status));
      final error = await _capture(service.getCategories());
      final normalized = error.message.toLowerCase();
      for (final term in prohibited) {
        expect(normalized, isNot(contains(term)), reason: '$status: $term');
      }
    }
  });
}

ApiClient _errorClient(int status) {
  return _client(
    status,
    '{"success":false,"status":$status,"message":'
    '"HTTP API backend JSON token status code adb reverse", "data":null}',
  );
}

ApiClient _client(int status, String body) {
  return ApiClient(
    client: MockClient((_) async => http.Response(body, status)),
    endpointBuilder: (path) => Uri.parse('https://example.test$path'),
  );
}

Future<ApiException> _capture(Future<Object?> future) async {
  try {
    await future;
    fail('Se esperaba ApiException.');
  } on ApiException catch (error) {
    return error;
  }
}
