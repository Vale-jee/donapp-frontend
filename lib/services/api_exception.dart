enum ApiErrorType {
  validation,
  invalidCredentials,
  inactiveAccount,
  authentication,
  server,
  network,
  timeout,
  unexpectedResponse,
}

class ApiException implements Exception {
  const ApiException(this.type, this.message);

  final ApiErrorType type;
  final String message;

  @override
  String toString() => message;
}
