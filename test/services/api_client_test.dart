import 'package:donapp_mobile/config/api_config.dart';
import 'package:donapp_mobile/services/api_client.dart';
import 'package:donapp_mobile/services/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('ApiClient', () {
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
