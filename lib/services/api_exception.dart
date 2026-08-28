enum ApiErrorType {
  validation,
  invalidCredentials,
  inactiveAccount,
  authentication,
  forbidden,
  notFound,
  conflict,
  rateLimited,
  server,
  network,
  timeout,
  unexpectedResponse,
  configuration,
}

class ApiFieldError {
  const ApiFieldError({required this.field, required this.message});

  final String field;
  final String message;
}

class ApiException implements Exception {
  const ApiException(
    this.type,
    this.message, {
    this.statusCode,
    this.fieldErrors = const [],
  });

  final ApiErrorType type;
  final String message;
  final int? statusCode;
  final List<ApiFieldError> fieldErrors;

  @override
  String toString() => message;
}
