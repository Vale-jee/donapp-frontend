import 'package:donapp_mobile/config/api_config.dart';
import 'package:donapp_mobile/services/api_client.dart';
import 'package:donapp_mobile/services/api_error_mapper.dart';
import 'package:donapp_mobile/services/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('ApiClient', () {
    test(
      '401 protegido renueva y repite una sola vez con token nuevo',
      () async {
        final recovery = _FakeSessionRecovery();
        final authorizationHeaders = <String?>[];
        final client = ApiClient(
          client: MockClient((request) async {
            authorizationHeaders.add(request.headers['Authorization']);
            if (authorizationHeaders.length == 1) {
              return http.Response(
                '{"success":false,"message":"Access token inválido."}',
                401,
              );
            }
            return http.Response('{"success":true,"data":{"ok":true}}', 200);
          }),
          endpointBuilder: _endpoint,
          sessionRecovery: recovery,
        );

        final result = await client.get(
          '/protegido',
          headers: const {'Authorization': 'Bearer old-access'},
          successStatusCodes: const {200},
          context: ApiRequestContext.protectedSession,
        );

        expect(result['data'], {'ok': true});
        expect(recovery.calls, ['old-access']);
        expect(recovery.authenticationInvalidations, 0);
        expect(authorizationHeaders, [
          'Bearer old-access',
          'Bearer new-access',
        ]);
      },
    );

    test('un segundo 401 no crea un loop de refresh', () async {
      final recovery = _FakeSessionRecovery();
      var requestCount = 0;
      final client = ApiClient(
        client: MockClient((_) async {
          requestCount++;
          return http.Response(
            '{"success":false,"message":"Access token inválido."}',
            401,
          );
        }),
        endpointBuilder: _endpoint,
        sessionRecovery: recovery,
      );

      await _expectType(
        client.get(
          '/protegido',
          headers: const {'Authorization': 'Bearer old-access'},
          successStatusCodes: const {200},
          context: ApiRequestContext.protectedSession,
        ),
        ApiErrorType.authentication,
      );

      expect(requestCount, 2);
      expect(recovery.calls, hasLength(1));
      expect(recovery.authenticationInvalidations, 1);
    });

    test('401 de Login no intenta recuperar sesión', () async {
      final recovery = _FakeSessionRecovery();
      final client = ApiClient(
        client: MockClient(
          (_) async => http.Response(
            '{"success":false,"message":"Credenciales inválidas."}',
            401,
          ),
        ),
        endpointBuilder: _endpoint,
        sessionRecovery: recovery,
      );

      await _expectType(
        client.post(
          '/api/auth/login',
          headers: const {'Content-Type': 'application/json'},
          body: const {'email': 'ana@example.com', 'password': 'incorrecta'},
          successStatusCodes: const {200},
          context: ApiRequestContext.login,
        ),
        ApiErrorType.invalidCredentials,
      );
      expect(recovery.calls, isEmpty);
      expect(recovery.authenticationInvalidations, 0);
    });

    test('403 de permisos no invalida la sesión', () async {
      final recovery = _FakeSessionRecovery();
      final client = ApiClient(
        client: MockClient(
          (_) async => http.Response(
            '{"success":false,"message":"No tiene permisos para realizar esta operación."}',
            403,
          ),
        ),
        endpointBuilder: _endpoint,
        sessionRecovery: recovery,
      );

      await _expectType(
        client.get(
          '/protegido',
          headers: const {'Authorization': 'Bearer access'},
          successStatusCodes: const {200},
          context: ApiRequestContext.protectedSession,
        ),
        ApiErrorType.forbidden,
      );
      expect(recovery.inactiveInvalidations, 0);
      expect(recovery.authenticationInvalidations, 0);
      expect(recovery.calls, isEmpty);
    });

    test('403 de cuenta inactiva invalida el acceso protegido', () async {
      final recovery = _FakeSessionRecovery();
      final client = ApiClient(
        client: MockClient(
          (_) async => http.Response(
            '{"success":false,"message":"La cuenta se encuentra inactiva."}',
            403,
          ),
        ),
        endpointBuilder: _endpoint,
        sessionRecovery: recovery,
      );

      await _expectType(
        client.get(
          '/protegido',
          headers: const {'Authorization': 'Bearer access'},
          successStatusCodes: const {200},
          context: ApiRequestContext.protectedSession,
        ),
        ApiErrorType.inactiveAccount,
      );
      expect(recovery.inactiveInvalidations, 1);
      expect(recovery.calls, isEmpty);
    });

    test('construye query parameters con Uri sin alterar el path', () async {
      late Uri requestedUri;
      final client = ApiClient(
        client: MockClient((request) async {
          requestedUri = request.url;
          return http.Response('{"success":true,"data":{}}', 200);
        }),
        endpointBuilder: _endpoint,
      );

      await client.get(
        '/test',
        queryParameters: const {'page': '2', 'categoriaId': '4'},
        successStatusCodes: const {200},
      );

      expect(requestedUri.path, '/test');
      expect(requestedUri.queryParameters, {'page': '2', 'categoriaId': '4'});
    });
    test('traduce timeout', () async {
      final client = ApiClient(
        client: MockClient((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 30));
          return http.Response('{}', 200);
        }),
        timeout: const Duration(milliseconds: 1),
        endpointBuilder: _endpoint,
      );

      await _expectType(
        client.get('/test', successStatusCodes: const {200}),
        ApiErrorType.timeout,
      );
    });

    test('traduce falta de conexión', () async {
      final client = ApiClient(
        client: MockClient((_) async => throw http.ClientException('offline')),
        endpointBuilder: _endpoint,
      );

      await _expectType(
        client.get('/test', successStatusCodes: const {200}),
        ApiErrorType.network,
      );
    });

    test('traduce respuesta no JSON y cuerpo vacío', () async {
      for (final body in ['no-json', '']) {
        final client = ApiClient(
          client: MockClient((_) async => http.Response(body, 200)),
          endpointBuilder: _endpoint,
        );
        await _expectType(
          client.get('/test', successStatusCodes: const {200}),
          ApiErrorType.unexpectedResponse,
        );
      }
    });

    test('traduce estructura inesperada', () async {
      final client = ApiClient(
        client: MockClient((_) async => http.Response('{"data":{}}', 200)),
        endpointBuilder: _endpoint,
      );
      await _expectType(
        client.get('/test', successStatusCodes: const {200}),
        ApiErrorType.unexpectedResponse,
      );
    });

    test(
      'traduce configuración inválida sin mostrar detalle técnico',
      () async {
        final client = ApiClient(
          client: MockClient((_) async => http.Response('{}', 200)),
          endpointBuilder: (_) =>
              throw const ApiConfigException('detalle técnico'),
        );

        final error = await _capture(
          client.get('/test', successStatusCodes: const {200}),
        );
        expect(error.type, ApiErrorType.configuration);
        expect(
          error.message,
          'DonApp no está configurada correctamente. Comunícate con soporte.',
        );
      },
    );
  });

  group('ApiConfig.resolveImageReference', () {
    test('resuelve una referencia relativa contra el servidor', () {
      final uri = ApiConfig.resolveImageReference(
        '/imagenes/donacion.jpg',
        baseUri: Uri.parse('https://api.donapp.test/api/'),
      );

      expect(uri, Uri.parse('https://api.donapp.test/imagenes/donacion.jpg'));
    });

    test('acepta HTTP/HTTPS y rechaza esquemas no seguros', () {
      expect(
        ApiConfig.resolveImageReference('https://cdn.test/imagen.jpg'),
        Uri.parse('https://cdn.test/imagen.jpg'),
      );
      expect(ApiConfig.resolveImageReference('file:///imagen.jpg'), isNull);
    });
  });
}

class _FakeSessionRecovery implements SessionRecovery {
  final calls = <String>[];
  int authenticationInvalidations = 0;
  int inactiveInvalidations = 0;

  @override
  Future<String> recoverAfterUnauthorized(String failedAccessToken) async {
    calls.add(failedAccessToken);
    return 'new-access';
  }

  @override
  Future<Never> invalidateAuthentication(ApiException cause) async {
    authenticationInvalidations++;
    throw cause;
  }

  @override
  Future<Never> invalidateInactiveAccount(ApiException cause) async {
    inactiveInvalidations++;
    throw cause;
  }
}

Uri _endpoint(String path) => Uri.parse('https://example.test$path');

Future<void> _expectType(Future<Object?> future, ApiErrorType type) async {
  final error = await _capture(future);
  expect(error.type, type);
}

Future<ApiException> _capture(Future<Object?> future) async {
  try {
    await future;
    fail('Se esperaba ApiException.');
  } on ApiException catch (error) {
    return error;
  }
}
