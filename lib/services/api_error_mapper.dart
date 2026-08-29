import 'api_exception.dart';

enum ApiRequestContext { general, login, protectedSession }

abstract final class ApiErrorMapper {
  static const _validationMessage =
      'Revisa los datos ingresados e intenta nuevamente.';
  static const _invalidCredentialsMessage =
      'El correo o la contraseña son incorrectos.';
  static const _invalidSessionMessage =
      'Tu sesión ya no es válida. Inicia sesión nuevamente.';
  static const _inactiveAccountMessage =
      'Tu cuenta está inactiva. Comunícate con soporte.';
  static const _forbiddenMessage =
      'No tienes permiso para realizar esta acción.';
  static const _notFoundMessage = 'No encontramos la información solicitada.';
  static const _conflictMessage =
      'No pudimos completar la acción porque la información cambió. '
      'Actualiza e intenta nuevamente.';
  static const _rateLimitedMessage =
      'Has realizado demasiados intentos. Espera un momento y vuelve a intentarlo.';
  static const _serverMessage =
      'DonApp no está disponible en este momento. Intenta nuevamente más tarde.';
  static const _timeoutMessage =
      'La operación está tardando más de lo esperado. Verifica tu conexión '
      'e intenta nuevamente.';
  static const _networkMessage =
      'No pudimos conectarnos. Verifica tu conexión a Internet e intenta nuevamente.';
  static const _unexpectedResponseMessage =
      'Recibimos una respuesta inesperada. Intenta nuevamente más tarde.';
  static const _configurationMessage =
      'DonApp no está configurada correctamente. Comunícate con soporte.';

  static final RegExp _technicalTerms = RegExp(
    r'\b(http|api|backend|json|token|status code|adb reverse|api_base_url|dart-define)\b',
    caseSensitive: false,
  );

  static ApiException fromHttp({
    required int statusCode,
    required Map<String, dynamic>? body,
    ApiRequestContext context = ApiRequestContext.general,
    bool allowSafeBackendMessage = false,
  }) {
    final fieldErrors = _fieldErrors(body);
    final safeMessage = allowSafeBackendMessage
        ? _safeBackendMessage(body, fieldErrors)
        : null;

    if (statusCode == 400 || statusCode == 422) {
      return ApiException(
        ApiErrorType.validation,
        safeMessage ?? _validationMessage,
        statusCode: statusCode,
        fieldErrors: fieldErrors,
      );
    }

    if (statusCode == 401) {
      return ApiException(
        context == ApiRequestContext.login
            ? ApiErrorType.invalidCredentials
            : ApiErrorType.authentication,
        context == ApiRequestContext.login
            ? _invalidCredentialsMessage
            : _invalidSessionMessage,
        statusCode: statusCode,
      );
    }

    if (statusCode == 403) {
      final inactiveAccount = _isInactiveAccount(body);
      return ApiException(
        inactiveAccount ? ApiErrorType.inactiveAccount : ApiErrorType.forbidden,
        inactiveAccount ? _inactiveAccountMessage : _forbiddenMessage,
        statusCode: statusCode,
      );
    }

    if (statusCode == 404) {
      return const ApiException(
        ApiErrorType.notFound,
        _notFoundMessage,
        statusCode: 404,
      );
    }

    if (statusCode == 409) {
      return ApiException(
        ApiErrorType.conflict,
        safeMessage ?? _conflictMessage,
        statusCode: statusCode,
      );
    }

    if (statusCode == 429) {
      return const ApiException(
        ApiErrorType.rateLimited,
        _rateLimitedMessage,
        statusCode: 429,
      );
    }

    if (statusCode >= 500 && statusCode <= 599) {
      return ApiException(
        ApiErrorType.server,
        _serverMessage,
        statusCode: statusCode,
      );
    }

    return ApiException(
      ApiErrorType.unexpectedResponse,
      _unexpectedResponseMessage,
      statusCode: statusCode,
    );
  }

  static const ApiException timeout = ApiException(
    ApiErrorType.timeout,
    _timeoutMessage,
  );

  static const ApiException network = ApiException(
    ApiErrorType.network,
    _networkMessage,
  );

  static const ApiException unexpectedResponse = ApiException(
    ApiErrorType.unexpectedResponse,
    _unexpectedResponseMessage,
  );

  static const ApiException configuration = ApiException(
    ApiErrorType.configuration,
    _configurationMessage,
  );

  static List<ApiFieldError> _fieldErrors(Map<String, dynamic>? body) {
    final errors = body?['errors'];
    if (errors is! List) return const [];

    return errors
        .whereType<Map<String, dynamic>>()
        .map((error) {
          final field = error['field'];
          final message = error['message'];
          if (field is! String || message is! String || !_isSafe(message)) {
            return null;
          }
          return ApiFieldError(field: field, message: message.trim());
        })
        .whereType<ApiFieldError>()
        .toList(growable: false);
  }

  static String? _safeBackendMessage(
    Map<String, dynamic>? body,
    List<ApiFieldError> fieldErrors,
  ) {
    if (fieldErrors.isNotEmpty) return fieldErrors.first.message;
    final message = body?['message'];
    return message is String && _isSafe(message) ? message.trim() : null;
  }

  static bool _isSafe(String message) {
    final normalized = message.trim();
    return normalized.isNotEmpty &&
        normalized.length <= 240 &&
        !_technicalTerms.hasMatch(normalized);
  }

  static bool _isInactiveAccount(Map<String, dynamic>? body) {
    final message = body?['message'];
    if (message is! String) return false;
    final normalized = message.trim().toLowerCase();
    return normalized.contains('cuenta') && normalized.contains('inactiva');
  }
}
