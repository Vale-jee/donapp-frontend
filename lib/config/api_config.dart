class ApiConfig {
  ApiConfig._();

  static const String _apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  static Uri endpoint(String path) {
    final baseUri = validateBaseUrl(
      environment: environment,
      baseUrl: _apiBaseUrl,
    );
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return baseUri.replace(
      path: '${baseUri.path.replaceFirst(RegExp(r'/$'), '')}$normalizedPath',
      query: null,
      fragment: null,
    );
  }

  /// Pure validation also used by tests without contacting a backend.
  static Uri validateBaseUrl({
    required String environment,
    required String baseUrl,
  }) {
    if (!const {'dev', 'test', 'prod'}.contains(environment)) {
      throw const ApiConfigException('APP_ENV debe ser dev, test o prod.');
    }
    if (baseUrl.trim().isEmpty) {
      throw const ApiConfigException(
        'Falta configurar API_BASE_URL. Ejecute la aplicacion con '
        '--dart-define=API_BASE_URL=<url-del-backend>.',
      );
    }
    final baseUri = Uri.tryParse(baseUrl);
    if (baseUri == null ||
        !baseUri.hasScheme ||
        baseUri.host.isEmpty ||
        (baseUri.scheme != 'http' && baseUri.scheme != 'https')) {
      throw const ApiConfigException(
        'API_BASE_URL no contiene una URL HTTP valida.',
      );
    }
    if (environment == 'prod' && baseUri.scheme != 'https') {
      throw const ApiConfigException(
        'API_BASE_URL debe usar HTTPS cuando APP_ENV=prod.',
      );
    }
    return baseUri;
  }

  static Uri? resolveImageReference(String reference, {Uri? baseUri}) {
    final parsed = Uri.tryParse(reference);
    if (parsed == null) return null;
    if (parsed.hasScheme) {
      return (parsed.scheme == 'http' || parsed.scheme == 'https') &&
              parsed.host.isNotEmpty
          ? parsed
          : null;
    }
    if (!reference.startsWith('/')) return null;
    try {
      return (baseUri ?? endpoint('/')).resolve(reference);
    } on ApiConfigException {
      return null;
    }
  }
}

class ApiConfigException implements Exception {
  const ApiConfigException(this.message);
  final String message;
  @override
  String toString() => message;
}
