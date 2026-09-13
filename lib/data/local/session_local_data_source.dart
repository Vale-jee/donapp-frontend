import '../../services/token_storage.dart';

class SessionLocalDataSource {
  SessionLocalDataSource([TokenStorage? storage])
    : _storage = storage ?? TokenStorage();
  final TokenStorage _storage;
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) =>
      _storage.saveTokens(accessToken: accessToken, refreshToken: refreshToken);
  Future<void> clearTokens() => _storage.clearTokens();
  Future<String?> readAccessToken() => _storage.readAccessToken();
  Future<String?> readRefreshToken() => _storage.readRefreshToken();
}
