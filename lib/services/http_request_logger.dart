import 'package:flutter/foundation.dart';

import '../config/api_config.dart';

/// Accepts metadata only: never headers, bodies or exception messages.
class HttpRequestLogger {
  const HttpRequestLogger({
    this.environment = ApiConfig.environment,
    this.write = _debugWrite,
  });

  final String environment;
  final void Function(String) write;

  void record({
    required String method,
    required String path,
    required int? statusCode,
    required Duration elapsed,
  }) {
    if (environment != 'dev') return;
    final safeMethod = const {'GET', 'POST', 'PATCH'}.contains(method)
        ? method
        : 'HTTP';
    try {
      write(
        '[HTTP] $safeMethod ${_safePath(path)} status=${statusCode ?? "sin_respuesta"} duration=${elapsed.inMilliseconds}ms',
      );
    } on Object {
      // Diagnostics must never change the request result.
    }
  }

  static void _debugWrite(String message) => debugPrint(message);

  static String _safePath(String path) {
    final uri = Uri.tryParse(path);
    if (uri == null || uri.hasScheme || uri.hasAuthority) {
      return '[ruta omitida]';
    }
    final clean = uri.path;
    if (const {
      '/api/auth/login',
      '/api/auth/register',
      '/api/auth/refresh',
      '/api/auth/logout',
      '/api/usuarios/perfil',
      '/api/categorias',
      '/api/imagenes/firma',
      '/api/donaciones',
      '/api/donaciones/mias',
      '/api/solicitudes',
      '/api/solicitudes/enviadas',
      '/api/solicitudes/recibidas',
    }.contains(clean)) {
      return clean;
    }
    final match = RegExp(
      r'^/api/(donaciones|solicitudes)/[0-9]+(/(aceptar|rechazar|cancelar))?$',
    ).firstMatch(clean);
    if (match == null) return '[ruta omitida]';
    return '/api/${match[1]}/:id${match[2] ?? ""}';
  }
}
