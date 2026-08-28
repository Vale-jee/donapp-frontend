class RefreshedTokens {
  const RefreshedTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresIn,
    required this.refreshTokenExpiresIn,
  });

  final String accessToken;
  final String refreshToken;
  final int accessTokenExpiresIn;
  final int refreshTokenExpiresIn;

  factory RefreshedTokens.fromJson(Map<String, dynamic> json) {
    return RefreshedTokens(
      accessToken: _requiredString(json, 'accessToken'),
      refreshToken: _requiredString(json, 'refreshToken'),
      accessTokenExpiresIn: _requiredInt(json, 'accessTokenExpiresIn'),
      refreshTokenExpiresIn: _requiredInt(json, 'refreshTokenExpiresIn'),
    );
  }
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('$key tiene un formato inválido.');
  }
  return value;
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int) {
    throw FormatException('$key tiene un formato inválido.');
  }
  return value;
}
