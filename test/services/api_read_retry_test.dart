import 'dart:async';
import 'dart:io';

import 'package:donapp_mobile/services/api_client.dart';
import 'package:donapp_mobile/services/api_error_mapper.dart';
import 'package:donapp_mobile/services/api_exception.dart';
import 'package:donapp_mobile/services/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _ok() => http.Response('{"success":true,"data":null}', 200);

void main() {
  for (final failure in [
    const SocketException('private'),
    http.ClientException('private'),
    TimeoutException('private'),
    500,
    502,
    503,
    504,
  ]) {
    test('GET $failure reintenta y termina en exito', () async {
      var calls = 0;
      final waits = <Duration>[];
      final client = _client((request) async {
        expect(request.url.queryParameters, {'page': '2'});
        expect(request.headers['Accept'], 'application/json');
        if (++calls == 1) {
          if (failure is int) {
            return http.Response('<html>private</html>', failure);
          }
          throw failure;
        }
        return _ok();
      }, waits);
      expect(
        await client.get(
          '/api/donaciones',
          headers: {'Accept': 'application/json'},
          queryParameters: {'page': '2'},
          successStatusCodes: {200},
        ),
        {'success': true, 'data': null},
      );
      expect(calls, 2);
      expect(waits, [const Duration(milliseconds: 500)]);
    });
  }

  for (final status in [400, 401, 403, 404, 409, 422, 501, 505]) {
    test('GET $status no repite', () async {
      var calls = 0;
      final waits = <Duration>[];
      final client = _client((_) async {
        calls++;
        return http.Response('', status);
      }, waits);
      await expectLater(
        client.get('/test', successStatusCodes: {200}),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'status', status),
        ),
      );
      expect(calls, 1);
      expect(waits, isEmpty);
    });
  }

  for (final header in [
    null,
    'invalid',
    '-1',
    '6',
    'Wed, 21 Oct 2030 07:28:00 GMT',
    '0',
    '2',
    '5',
  ]) {
    test(
      '429 Retry-After $header respeta ventana corta o no reintenta',
      () async {
        var calls = 0;
        final waits = <Duration>[];
        final client = _client((_) async {
          calls++;
          return calls == 1
              ? http.Response('', 429, headers: {'Retry-After': ?header})
              : _ok();
        }, waits);
        final allowed = ['0', '2', '5'].contains(header);
        final result = client.get('/test', successStatusCodes: {200});
        if (allowed) {
          await result;
          expect(calls, 2);
          expect(waits, [
            header == '0'
                ? const Duration(milliseconds: 500)
                : Duration(seconds: int.parse(header!)),
          ]);
        } else {
          await expectLater(
            result,
            throwsA(
              isA<ApiException>().having(
                (e) => e.type,
                'type',
                ApiErrorType.rateLimited,
              ),
            ),
          );
          expect(calls, 1);
          expect(waits, isEmpty);
        }
      },
    );
  }

  for (final failure in [
    http.ClientException('private'),
    TimeoutException('private'),
    503,
    429,
  ]) {
    test('$failure respeta tres intentos y backoff progresivo', () async {
      var calls = 0;
      final waits = <Duration>[];
      final client = _client((_) async {
        calls++;
        if (failure is int) {
          return http.Response('', failure, headers: {'Retry-After': '0'});
        }
        throw failure;
      }, waits);
      await expectLater(
        client.get('/test', successStatusCodes: {200}),
        throwsA(isA<ApiException>()),
      );
      expect(calls, ApiClient.maxReadAttempts);
      expect(waits, [
        const Duration(milliseconds: 500),
        const Duration(seconds: 1),
      ]);
    });
  }

  for (final body in ['{broken', '[]', '{"success":false}', '{"data":{}}']) {
    test('contrato invalido no reintenta: $body', () async {
      var calls = 0;
      final waits = <Duration>[];
      final client = _client((_) async {
        calls++;
        return http.Response(body, 200);
      }, waits);
      await expectLater(
        client.get('/test', successStatusCodes: {200}),
        throwsA(
          isA<ApiException>().having(
            (e) => e.type,
            'type',
            ApiErrorType.unexpectedResponse,
          ),
        ),
      );
      expect(calls, 1);
      expect(waits, isEmpty);
    });
  }

  for (final method in ['POST', 'PATCH']) {
    for (final failure in [
      http.ClientException('private'),
      TimeoutException('private'),
      429,
      503,
    ]) {
      test('$method $failure no repite escritura', () async {
        var calls = 0;
        final waits = <Duration>[];
        final client = _client((_) async {
          calls++;
          if (failure is int) {
            return http.Response('', failure, headers: {'Retry-After': '0'});
          }
          throw failure;
        }, waits);
        await expectLater(
          method == 'POST'
              ? client.post(
                  '/api/solicitudes',
                  body: {'donacionId': 1},
                  successStatusCodes: {201},
                )
              : client.patch(
                  '/api/solicitudes/1/aceptar',
                  successStatusCodes: {200},
                ),
          throwsA(isA<ApiException>()),
        );
        expect(calls, 1);
        expect(waits, isEmpty);
      });
    }
  }

  test('401 tras backoff conserva un solo replay de sesion sin reiniciar presupuesto', () async {
    var calls = 0;
    final waits = <Duration>[];
    final recovery = _Recovery();
    final client = _client((request) async {
      calls++;
      if (calls < 3) return http.Response('', 503);
      if (calls == 3) return http.Response('', 401);
      expect(request.headers['Authorization'], 'Bearer new');
      return http.Response('', 503);
    }, waits).withTokenStorage(_Tokens()).withSessionRecovery(recovery);
    await expectLater(
      client.get(
        '/test',
        context: ApiRequestContext.protectedSession,
        successStatusCodes: {200},
      ),
      throwsA(
        isA<ApiException>().having((e) => e.type, 'type', ApiErrorType.server),
      ),
    );
    expect(calls, 4);
    expect(recovery.calls, 1);
    expect(waits, [
      const Duration(milliseconds: 500),
      const Duration(seconds: 1),
    ]);
  });

  test('desactivar reintentos se conserva en las vistas del cliente', () async {
    var calls = 0;
    final client = ApiClient(
      retryReads: false,
      endpointBuilder: (path) => Uri.parse('https://donapp.test$path'),
      retryDelay: (_) async => fail('No debe esperar'),
      client: MockClient((_) async {
        calls++;
        return http.Response('', 503);
      }),
    ).withSessionRecovery(_Recovery()).withTokenStorage(_Tokens());
    await expectLater(
      client.get('/test', successStatusCodes: {200}),
      throwsA(isA<ApiException>()),
    );
    expect(calls, 1);
  });
}

ApiClient _client(
  Future<http.Response> Function(http.Request) handler,
  List<Duration> waits,
) => ApiClient(
  client: MockClient(handler),
  endpointBuilder: (path) => Uri.parse('https://donapp.test$path'),
  retryDelay: (delay) async {
    waits.add(delay);
  },
);

class _Tokens extends TokenStorage {
  @override
  Future<String?> readAccessToken() async => 'old';
}

class _Recovery implements SessionRecovery {
  int calls = 0;
  @override
  Future<String> recoverAfterUnauthorized(String failedAccessToken) async {
    calls++;
    return 'new';
  }

  @override
  Future<Never> invalidateAuthentication(ApiException cause) async =>
      throw cause;
  @override
  Future<Never> invalidateInactiveAccount(ApiException cause) async =>
      throw cause;
}
