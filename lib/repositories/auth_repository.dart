import '../models/auth_session.dart';
import '../models/refreshed_tokens.dart';
import '../services/auth_service.dart';
import '../data/remote/auth_remote_data_source.dart';

class AuthRepository {
  AuthRepository({AuthRemoteDataSource? remote})
    : _remote = remote ?? AuthRemoteDataSource();
  final AuthRemoteDataSource _remote;
  AuthRemoteDataSource get _delegate => _remote;
  factory AuthRepository.fromService(AuthService service) =>
      AuthRepository(remote: AuthRemoteDataSource(service));
  Future<AuthSession> login(String email, String password) =>
      _delegate.login(email, password);
  Future<void> register({
    required String nombreCompleto,
    required String nombreVisible,
    required String email,
    required String password,
    required String ciudad,
  }) => _delegate.register(
    nombreCompleto: nombreCompleto,
    nombreVisible: nombreVisible,
    email: email,
    password: password,
    ciudad: ciudad,
  );
  Future<RefreshedTokens> refresh(String refreshToken) =>
      _delegate.refresh(refreshToken);
  Future<void> logout(String refreshToken) => _delegate.logout(refreshToken);
}
