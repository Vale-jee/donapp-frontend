import 'dart:async';
import 'dart:convert';

import 'package:donapp_mobile/config/api_config.dart';
import 'package:donapp_mobile/services/api_client.dart';
import 'package:donapp_mobile/services/api_error_mapper.dart';
import 'package:donapp_mobile/services/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('Clasificación HTTP independiente del body', () {
    for (final status in [400, 422]) {
      test(
        '$status JSON conserva mensaje seguro, errores y status real',
        () async {
          final client = ApiClient(
            client: MockClient(
              (_) async => http.Response(
                jsonEncode({
                  'success': false,
                  'status': 999,
                  'message': 'Revisa los datos.',
                  'data': null,
                  'errors': [
                    {'field': 'titulo', 'message': 'El título es obligatorio.'},
                  ],
                }),
                status,
              ),
            ),
            endpointBuilder: _endpoint,
          );
          final error = await _capture(
            client.post(
              '/test',
              successStatusCodes: const {201},
              allowSafeBackendMessage: true,
            ),
          );
          expect(error.type, ApiErrorType.validation);
          expect(error.statusCode, status);
          expect(error.message, 'El título es obligatorio.');
          expect(error.fieldErrors.single.field, 'titulo');
          expect(error.fieldErrors.single.message, 'El título es obligatorio.');
        },
      );
    }

    for (final scenario in [
      (400, '', ApiErrorType.validation),
      (
        401,
        '{"success":false,"message":"Sesión inválida."}',
        ApiErrorType.authentication,
      ),
      (403, '<html>private</html>', ApiErrorType.forbidden),
      (404, '<html>private</html>', ApiErrorType.notFound),
      (500, '<html>private</html>', ApiErrorType.server),
      (500, '', ApiErrorType.server),
      (502, '{broken', ApiErrorType.server),
      (503, '[]', ApiErrorType.server),
      (599, 'null', ApiErrorType.server),
      (418, 'private', ApiErrorType.unexpectedResponse),
      (302, 'private', ApiErrorType.unexpectedResponse),
      (204, '', ApiErrorType.unexpectedResponse),
    ]) {
      test(
        '${scenario.$1} conserva clasificación con body ${scenario.$2}',
        () async {
          final client = ApiClient(
            client: MockClient(
              (_) async => http.Response(scenario.$2, scenario.$1),
            ),
            endpointBuilder: _endpoint,
          );
          final error = await _capture(
            client.get(
              '/test',
              successStatusCodes: const {200},
              allowSafeBackendMessage: true,
            ),
          );
          expect(error.type, scenario.$3);
          expect(error.statusCode, scenario.$1);
          expect(error.message, isNot(contains('private')));
          expect(error.message, isNotEmpty);
        },
      );
    }

    test(
      'mensaje JSON seguro sin errores conserva la política existente',
      () async {
        final client = ApiClient(
          client: MockClient(
            (_) async => http.Response(
              '{"success":false,"message":"Completa los datos solicitados."}',
              400,
            ),
          ),
          endpointBuilder: _endpoint,
        );
        final error = await _capture(
          client.get(
            '/test',
            successStatusCodes: const {200},
            allowSafeBackendMessage: true,
          ),
        );
        expect(error.message, 'Completa los datos solicitados.');
        expect(error.statusCode, 400);
      },
    );

    for (final status in [200, 201]) {
      test('$status JSON válido mantiene el sobre exitoso', () async {
        final client = ApiClient(
          client: MockClient(
            (_) async =>
                http.Response('{"success":true,"data":{"id":1}}', status),
          ),
          endpointBuilder: _endpoint,
        );
        expect(await client.get('/test', successStatusCodes: {status}), {
          'success': true,
          'data': {'id': 1},
        });
      });
    }

    for (final body in ['', '<html>private</html>', '[]', '{"data":{}}']) {
      test('200 inválido conserva status sin aceptar el body: $body', () async {
        final client = ApiClient(
          client: MockClient((_) async => http.Response(body, 200)),
          endpointBuilder: _endpoint,
        );
        final error = await _capture(
          client.get('/test', successStatusCodes: const {200}),
        );
        expect(error.type, ApiErrorType.unexpectedResponse);
        expect(error.statusCode, 200);
      });
    }

    for (final retryStatus in [200, 401, 500]) {
      test(
        '401 sin JSON mantiene recuperación única y status final $retryStatus',
        () async {
          final recovery = _FakeSessionRecovery();
          final sentHeaders = <String?>[];
          final client = ApiClient(
            client: MockClient((request) async {
              sentHeaders.add(request.headers['Authorization']);
              if (sentHeaders.length == 1) {
                return http.Response('<html>expired</html>', 401);
              }
              return http.Response(
                retryStatus == 200 ? '{"success":true,"data":null}' : '',
                retryStatus,
              );
            }),
            endpointBuilder: _endpoint,
            sessionRecovery: recovery,
          );
          final result = client.get(
            '/test',
            successStatusCodes: const {200},
            headers: const {'Authorization': 'Bearer old-access'},
            context: ApiRequestContext.protectedSession,
          );
          if (retryStatus == 200) {
            expect((await result)['success'], isTrue);
          } else {
            final error = await _capture(result);
            expect(error.statusCode, retryStatus);
            expect(
              error.type,
              retryStatus == 401
                  ? ApiErrorType.authentication
                  : ApiErrorType.server,
            );
          }
          expect(sentHeaders, ['Bearer old-access', 'Bearer new-access']);
          expect(recovery.calls, ['old-access']);
          expect(
            recovery.authenticationInvalidations,
            retryStatus == 401 ? 1 : 0,
          );
        },
      );
    }
  });

  testWidgets('el plazo API incluye body aunque ya llegaron cabeceras', (
    tester,
  ) async {
    final body = StreamController<List<int>>();
    final client = ApiClient(
      client: _BodyClient(body.stream),
      endpointBuilder: _endpoint,
    );
    final expectation = expectLater(
      client.get('/test', successStatusCodes: const {200}),
      throwsA(
        isA<ApiException>().having(
          (error) => error.type,
          'type',
          ApiErrorType.timeout,
        ),
      ),
    );
    await tester.pump();
    body.add(utf8.encode('{"success":true,'));
    await tester.pump(const Duration(seconds: 14));
    body.add(utf8.encode('"data":'));
    await tester.pump(const Duration(seconds: 2));
    await expectation;
    // Incoming chunks must not reset the total deadline.
    body.add(utf8.encode('null}'));
    await body.close();
  });

  testWidgets('API completa cuerpo dentro de 15 segundos', (tester) async {
    final body = StreamController<List<int>>();
    final client = ApiClient(
      client: _BodyClient(body.stream),
      endpointBuilder: _endpoint,
    );
    final result = client.get('/test', successStatusCodes: const {200});
    await tester.pump();
    await tester.pump(const Duration(seconds: 14));
    body.add(utf8.encode('{"success":true,"data":{"ok":true}}'));
    await body.close();
    expect((await result)['data'], {'ok': true});
  });

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

class _BodyClient extends http.BaseClient {
  _BodyClient(this.body);
  final Stream<List<int>> body;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async =>
      http.StreamedResponse(body, 200);
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
