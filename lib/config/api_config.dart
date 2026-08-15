class ApiConfig {
  ApiConfig._();

  static const String _apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  static Uri endpoint(String path) {
    if (_apiBaseUrl.trim().isEmpty) {
      throw const ApiConfigException(
        'Falta configurar API_BASE_URL. Ejecute la aplicacion con '
        '--dart-define=API_BASE_URL=<url-del-backend>.',
      );
    }
    final baseUri = Uri.tryParse(_apiBaseUrl);
    if (baseUri == null ||
        !baseUri.hasScheme ||
        baseUri.host.isEmpty ||
        (baseUri.scheme != 'http' && baseUri.scheme != 'https')) {
      throw const ApiConfigException(
        'API_BASE_URL no contiene una URL HTTP valida.',
      );
    }
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return baseUri.replace(
      path: '${baseUri.path.replaceFirst(RegExp(r'/$'), '')}$normalizedPath',
      query: null,
      fragment: null,
    );
  }
}

class ApiConfigException implements Exception {
  const ApiConfigException(this.message);
  final String message;
  @override
  String toString() => message;
}
