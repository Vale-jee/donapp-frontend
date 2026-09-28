import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../config/api_config.dart';

/// Accepts metadata only: never headers, bodies or exception messages.
enum LogLevel { debug, info, warning, error }

class HttpRequestLogger {
  const HttpRequestLogger({
    this.environment = ApiConfig.environment,
    this.write = _debugWrite,
    this.minimumLevel = LogLevel.debug,
    this.releaseMode = kReleaseMode,
    this.enabled = const bool.fromEnvironment('HTTP_LOGS', defaultValue: true),
  });

  final String environment;
  final void Function(String) write;
  final LogLevel minimumLevel;
  final bool releaseMode;
  final bool enabled;

  void record({
    required String method,
    required String path,
    required int? statusCode,
    required Duration elapsed,
  }) {
    if (kReleaseMode || releaseMode || !enabled || environment != 'dev') return;
    final level = statusCode == null || statusCode >= 500
        ? LogLevel.error
        : statusCode >= 400
        ? LogLevel.warning
        : LogLevel.info;
    if (level.index < minimumLevel.index) return;
    final safeMethod = const {'GET', 'POST', 'PATCH'}.contains(method)
        ? method
        : 'HTTP';
    try {
      write(
        jsonEncode({
          'event': 'http.request',
          'level': level.name,
          'method': safeMethod,
          'route': _safePath(path),
          'status_code': statusCode,
          'duration_ms': elapsed.inMilliseconds,
        }),
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
