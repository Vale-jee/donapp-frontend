import 'dart:convert';

import 'package:donapp_mobile/services/api_client.dart';
import 'package:donapp_mobile/services/api_exception.dart';
import 'package:donapp_mobile/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('refresh envía el token y devuelve los tokens rotados', () async {
    final service = AuthService(
      apiClient: ApiClient(
        endpointBuilder: _endpoint,
        client: MockClient((request) async {
          expect(request.url.path, '/api/auth/refresh');
          expect(jsonDecode(request.body), {'refreshToken': 'old-refresh'});
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'accessToken': 'new-access',
                'refreshToken': 'new-refresh',
                'accessTokenExpiresIn': 900,
                'refreshTokenExpiresIn': 604800,
              },
            }),
            200,
          );
        }),
      ),
    );

    final result = await service.refresh('old-refresh');
    expect(result.accessToken, 'new-access');
    expect(result.refreshToken, 'new-refresh');
  });

  test('refresh traduce una respuesta inválida', () async {
    final service = AuthService(
      apiClient: ApiClient(
        endpointBuilder: _endpoint,
        client: MockClient(
          (_) async => http.Response(
            '{"success":true,"data":{"accessToken":"only-access"}}',
            200,
          ),
        ),
      ),
    );

    await expectLater(
      service.refresh('old-refresh'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.type,
          'type',
          ApiErrorType.unexpectedResponse,
        ),
      ),
    );
  });

  test('logout envía el refresh token al endpoint real', () async {
    final service = AuthService(
      apiClient: ApiClient(
        endpointBuilder: _endpoint,
        client: MockClient((request) async {
          expect(request.url.path, '/api/auth/logout');
          expect(jsonDecode(request.body), {'refreshToken': 'current-refresh'});
          return http.Response('{"success":true,"data":{}}', 200);
        }),
      ),
    );

    await service.logout('current-refresh');
  });
}

Uri _endpoint(String path) => Uri.parse('https://example.test$path');
