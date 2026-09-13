import '../../models/auth_session.dart';
import '../../models/refreshed_tokens.dart';
import '../../services/auth_service.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource([AuthService? service])
    : _service = service ?? AuthService();
  final AuthService _service;
  AuthService get _delegate => _service;
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
