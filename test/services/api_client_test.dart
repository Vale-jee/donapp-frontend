import 'package:donapp_mobile/config/api_config.dart';
import 'package:donapp_mobile/services/api_client.dart';
import 'package:donapp_mobile/services/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('ApiClient', () {
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
