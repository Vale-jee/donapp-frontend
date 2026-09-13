import '../data/local/session_local_data_source.dart';
import '../services/token_storage.dart';

class SessionRepository {
  SessionRepository({SessionLocalDataSource? local})
    : _local = local ?? SessionLocalDataSource();
  factory SessionRepository.fromStorage(TokenStorage storage) =>
      SessionRepository(local: SessionLocalDataSource(storage));
  final SessionLocalDataSource _local;
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) => _local.saveTokens(accessToken: accessToken, refreshToken: refreshToken);
  Future<void> clearTokens() => _local.clearTokens();
  Future<String?> readAccessToken() => _local.readAccessToken();
  Future<String?> readRefreshToken() => _local.readRefreshToken();
}
