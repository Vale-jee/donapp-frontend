import 'dart:async';

import 'package:donapp_mobile/services/api_client.dart';
import 'package:donapp_mobile/services/api_exception.dart';
import 'package:donapp_mobile/services/api_error_mapper.dart';
import 'package:donapp_mobile/services/token_storage.dart';
import 'package:donapp_mobile/services/http_request_logger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  for (final env in ['dev', 'test', 'prod']) {
    test('$env logs only safe metadata', () async {
      final logs = <String>[];
      final client = ApiClient(
        logger: HttpRequestLogger(environment: env, write: logs.add),
        endpointBuilder: (path) =>
            Uri.https('secret-host.test', '/api/auth/login'),
        client: MockClient((request) async {
          expect(request.headers['authorization'], 'Bearer ACCESS_SECRET');
          return http.Response(
            '{"success":true,"data":{"accessToken":"RESPONSE_SECRET"}}',
            200,
            headers: {'set-cookie': 'COOKIE_SECRET'},
          );
        }),
      );
      await client.post(
        '/api/auth/login?refreshToken=QUERY_SECRET#FRAGMENT_SECRET',
        headers: {
          'Authorization': 'Bearer ACCESS_SECRET',
          'Cookie': 'COOKIE_SECRET',
        },
        body: {'password': 'PASSWORD_SECRET', 'refreshToken': 'REFRESH_SECRET'},
        successStatusCodes: {200},
      );
      if (env == 'dev') {
        expect(logs, hasLength(1));
        expect(
          logs.single,
          matches(r'^\[HTTP\] POST /api/auth/login status=200 duration=\d+ms$'),
        );
        expect(logs.single, isNot(contains('SECRET')));
        expect(logs.single, isNot(contains('Authorization')));
        expect(logs.single, isNot(contains('secret-host')));
      } else {
        expect(logs, isEmpty);
      }
    });
  }

  for (final path in [
    '/api/donaciones/123',
    '/api/solicitudes/42/aceptar',
    '/private/TOKEN_SECRET',
    'https://user:PASSWORD_SECRET@host/api/auth/login',
    '/api/auth/login%0ASECRET',
  ]) {
    test('sanitizes $path', () {
      final logs = <String>[];
      HttpRequestLogger(environment: 'dev', write: logs.add).record(
        method: 'GET',
        path: path,
        statusCode: 404,
        elapsed: const Duration(milliseconds: 12),
      );
      expect(logs.single, isNot(contains('SECRET')));
      expect(logs.single, isNot(contains('123')));
      expect(logs.single, isNot(contains('42')));
      expect(logs.single, contains('status=404 duration=12ms'));
      if (path == '/api/donaciones/123') {
        expect(logs.single, contains('/api/donaciones/:id'));
      }
    });
  }

  for (final failure in ['http', 'network', 'timeout']) {
    test('$failure records one safe log without changing error', () async {
      final logs = <String>[];
      final client = ApiClient(
        logger: HttpRequestLogger(environment: 'dev', write: logs.add),
        endpointBuilder: (path) => Uri.https('example.test', path),
        client: MockClient((_) async {
          if (failure == 'network') throw http.ClientException('ACCESS_SECRET');
          if (failure == 'timeout') throw TimeoutException('PASSWORD_SECRET');
          return http.Response('<html>REFRESH_SECRET</html>', 500);
        }),
      );
      await expectLater(
        client.get('/api/categorias', successStatusCodes: {200}),
        throwsA(
          isA<ApiException>().having(
            (e) => e.type,
            'type',
            failure == 'http'
                ? ApiErrorType.server
                : failure == 'network'
                ? ApiErrorType.network
                : ApiErrorType.timeout,
          ),
        ),
      );
      expect(logs, hasLength(1));
      expect(
        logs.single,
        contains(failure == 'http' ? 'status=500' : 'status=sin_respuesta'),
      );
      expect(logs.single, isNot(contains('SECRET')));
    });
  }

  test('shared views log once per attempt including retry', () async {
    final logs = <String>[];
    var count = 0;
    final client = ApiClient(
      logger: HttpRequestLogger(environment: 'dev', write: logs.add),
      endpointBuilder: (path) => Uri.https('example.test', path),
      client: MockClient(
        (_) async => ++count == 1
            ? http.Response('', 401)
            : http.Response('{"success":true,"data":null}', 200),
      ),
    ).withTokenStorage(TokenStorage()).withSessionRecovery(_Recovery());
    await client.get(
      '/api/donaciones',
      headers: {'Authorization': 'Bearer OLD_SECRET'},
      successStatusCodes: {200},
      context: ApiRequestContext.protectedSession,
    );
    expect(count, 2);
    expect(logs, hasLength(2));
    expect(logs.first, contains('status=401'));
    expect(logs.last, contains('status=200'));
    expect(logs.join(), isNot(contains('SECRET')));
  });

  test('failing sink cannot change successful response', () async {
    final client = ApiClient(
      logger: HttpRequestLogger(
        environment: 'dev',
        write: (_) => throw StateError('sink'),
      ),
      endpointBuilder: (path) => Uri.https('example.test', path),
      client: MockClient(
        (_) async => http.Response('{"success":true,"data":null}', 200),
      ),
    );
    expect(await client.get('/api/categorias', successStatusCodes: {200}), {
      'success': true,
      'data': null,
    });
  });
}

class _Recovery implements SessionRecovery {
  @override
  Future<String> recoverAfterUnauthorized(String failedAccessToken) async =>
      'NEW_SECRET';
  @override
  Future<Never> invalidateAuthentication(ApiException cause) async =>
      throw cause;
  @override
  Future<Never> invalidateInactiveAccount(ApiException cause) async =>
      throw cause;
}
