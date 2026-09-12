import 'dart:convert';

import 'package:donapp_mobile/services/api_client.dart';
import 'package:donapp_mobile/services/api_error_mapper.dart';
import 'package:donapp_mobile/services/api_exception.dart';
import 'package:donapp_mobile/services/session_coordinator.dart';
import 'package:donapp_mobile/services/token_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('lee TokenStorage en cada peticion, sin cachear access token', () async {
    final storage = TokenStorage();
    final headers = <String?>[];
    final client = ApiClient(
      tokenStorage: storage,
      endpointBuilder: _endpoint,
      client: MockClient((request) async {
        headers.add(request.headers['Authorization']);
        return _ok();
      }),
    );
    for (final token in ['first', 'second']) {
      await storage.saveTokens(accessToken: token, refreshToken: 'refresh');
      await client.get(
        '/private',
        successStatusCodes: {200},
        context: ApiRequestContext.protectedSession,
      );
    }
    expect(headers, ['Bearer first', 'Bearer second']);
  });

  test('sin token rechaza antes de enviar', () async {
    final client = ApiClient(
      tokenStorage: TokenStorage(),
      endpointBuilder: _endpoint,
      client: MockClient((_) async {
        fail('No debe enviar');
      }),
    );
    await expectLater(
      client.get(
        '/private',
        successStatusCodes: {200},
        context: ApiRequestContext.protectedSession,
      ),
      throwsA(
        isA<ApiException>()
            .having((e) => e.type, 'type', ApiErrorType.authentication)
            .having((e) => e.statusCode, 'status', 401),
      ),
    );
  });

  test(
    'respeta Authorization explicito sin duplicarlo ni leer storage',
    () async {
      final client = ApiClient(
        tokenStorage: _UnreadableStorage(),
        endpointBuilder: _endpoint,
        client: MockClient((request) async {
          expect(request.headers['authorization'], 'Bearer explicit');
          expect(
            request.headers.keys.where(
              (key) => key.toLowerCase() == 'authorization',
            ),
            hasLength(1),
          );
          return _ok();
        }),
      );
      final headers = {'authorization': 'Bearer explicit'};
      await client.get(
        '/private',
        headers: headers,
        successStatusCodes: {200},
        context: ApiRequestContext.protectedSession,
      );
      expect(headers, {'authorization': 'Bearer explicit'});
    },
  );

  test('rutas publicas no leen storage ni reciben Bearer', () async {
    final client = ApiClient(
      tokenStorage: _UnreadableStorage(),
      endpointBuilder: _endpoint,
      client: MockClient((request) async {
        expect(request.headers.containsKey('authorization'), isFalse);
        return _ok();
      }),
    );
    for (final path in ['login', 'register', 'refresh', 'logout']) {
      await client.post(
        '/api/auth/$path',
        successStatusCodes: {200},
        context: path == 'login'
            ? ApiRequestContext.login
            : ApiRequestContext.general,
      );
    }
  });

  test('composicion usa storage y token renovado en reintento y siguiente peticion', () async {
    final storage = TokenStorage();
    await storage.saveTokens(accessToken: 'old', refreshToken: 'refresh');
    final sent = <String?>[];
    final coordinator = SessionCoordinator(
      tokenStorage: storage,
      apiClient: ApiClient(
        endpointBuilder: _endpoint,
        client: MockClient((request) async {
          if (request.url.path == '/api/auth/refresh') {
            expect(request.headers.containsKey('authorization'), isFalse);
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'accessToken': 'new',
                  'refreshToken': 'rotated',
                  'accessTokenExpiresIn': 900,
                  'refreshTokenExpiresIn': 604800,
                },
              }),
              200,
            );
          }
          sent.add(request.headers['authorization']);
          return sent.length == 1 ? http.Response('', 401) : _ok();
        }),
      ),
    );
    for (var i = 0; i < 2; i++) {
      await coordinator.protectedApiClient.get(
        '/private',
        successStatusCodes: {200},
        context: ApiRequestContext.protectedSession,
      );
    }
    expect(sent, ['Bearer old', 'Bearer new', 'Bearer new']);
    expect(await storage.readAccessToken(), 'new');
  });
}

Uri _endpoint(String path) => Uri.https('donapp.test', path);
http.Response _ok() => http.Response('{"success":true,"data":null}', 200);

class _UnreadableStorage extends TokenStorage {
  @override
  Future<String?> readAccessToken() async =>
      throw StateError('Unexpected read');
}
