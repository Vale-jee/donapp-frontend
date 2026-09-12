import 'package:donapp_mobile/config/api_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dev acepta localhost HTTP', () {
    expect(
      ApiConfig.validateBaseUrl(
        environment: 'dev',
        baseUrl: 'http://localhost:3000',
      ),
      Uri.parse('http://localhost:3000'),
    );
  });

  test('prod acepta HTTPS', () {
    expect(
      ApiConfig.validateBaseUrl(
        environment: 'prod',
        baseUrl: 'https://api.example.com',
      ).scheme,
      'https',
    );
  });

  test('prod rechaza HTTP incluso localhost', () {
    for (final url in ['http://api.example.com', 'http://localhost:3000']) {
      expect(
        () => ApiConfig.validateBaseUrl(environment: 'prod', baseUrl: url),
        throwsA(
          isA<ApiConfigException>().having(
            (error) => error.message,
            'message',
            contains('HTTPS'),
          ),
        ),
      );
    }
  });

  test('rechaza ambiente inválido o explícitamente vacío', () {
    for (final env in ['staging', 'PROD', '']) {
      expect(
        () => ApiConfig.validateBaseUrl(
          environment: env,
          baseUrl: 'https://api.example.com',
        ),
        throwsA(
          isA<ApiConfigException>().having(
            (error) => error.message,
            'message',
            contains('APP_ENV'),
          ),
        ),
      );
    }
  });

  test('URL ausente produce error claro en todos los ambientes', () {
    for (final env in ['dev', 'test', 'prod']) {
      for (final url in ['', '   ']) {
        expect(
          () => ApiConfig.validateBaseUrl(environment: env, baseUrl: url),
          throwsA(
            isA<ApiConfigException>().having(
              (error) => error.message,
              'message',
              contains('Falta configurar API_BASE_URL'),
            ),
          ),
        );
      }
    }
  });

  test('test acepta una dirección ficticia sin realizar peticiones', () {
    expect(
      ApiConfig.validateBaseUrl(
        environment: 'test',
        baseUrl: 'https://donapp.test',
      ).host,
      'donapp.test',
    );
  });

  test('rechaza URL relativa, sin host o con esquema no HTTP', () {
    for (final url in ['/api', 'https://', 'ftp://example.com']) {
      expect(
        () => ApiConfig.validateBaseUrl(environment: 'dev', baseUrl: url),
        throwsA(isA<ApiConfigException>()),
      );
    }
  });

  test(
    'endpoint usa las constantes de compilación y conserva el path base',
    () {
      const env = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
      const url = String.fromEnvironment('API_BASE_URL');
      expect(ApiConfig.environment, env);
      if (url.isEmpty) {
        expect(
          () => ApiConfig.endpoint('/api/categorias'),
          throwsA(isA<ApiConfigException>()),
        );
      } else {
        final base = ApiConfig.validateBaseUrl(environment: env, baseUrl: url);
        final expected = base.replace(
          path: '${base.path.replaceFirst(RegExp(r'/$'), '')}/api/categorias',
          query: null,
          fragment: null,
        );
        expect(ApiConfig.endpoint('/api/categorias'), expected);
        expect(ApiConfig.endpoint('api/categorias'), expected);
      }
    },
  );
}
