import '../models/user_profile.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'auth_service.dart';
import 'profile_service.dart';
import 'token_storage.dart';

enum SessionRestoreStatus { valid, noSession, invalid, recoverableError }

class SessionRestoreResult {
  const SessionRestoreResult._(this.status, {this.profile, this.message});

  const SessionRestoreResult.valid(UserProfile profile)
    : this._(SessionRestoreStatus.valid, profile: profile);

  const SessionRestoreResult.noSession()
    : this._(SessionRestoreStatus.noSession);

  const SessionRestoreResult.invalid() : this._(SessionRestoreStatus.invalid);

  const SessionRestoreResult.recoverableError(String message)
    : this._(SessionRestoreStatus.recoverableError, message: message);

  final SessionRestoreStatus status;
  final UserProfile? profile;
  final String? message;
}

class SessionCoordinator implements SessionRecovery {
  SessionCoordinator({
    AuthService? authService,
    ProfileService? profileService,
    TokenStorage? tokenStorage,
  }) : _authService = authService ?? AuthService(),
       _profileService = profileService ?? ProfileService(),
       _tokenStorage = tokenStorage ?? TokenStorage();

  final AuthService _authService;
  final ProfileService _profileService;
  final TokenStorage _tokenStorage;
  Future<SessionRestoreResult>? _restoreInProgress;
  Future<String>? _refreshInProgress;
  final List<void Function()> _sessionInvalidatedListeners = [];

  TokenStorage get tokenStorage => _tokenStorage;

  void addSessionInvalidatedListener(void Function() listener) {
    _sessionInvalidatedListeners.add(listener);
  }

  void removeSessionInvalidatedListener(void Function() listener) {
    _sessionInvalidatedListeners.remove(listener);
  }

  @override
  Future<String> recoverAfterUnauthorized(String failedAccessToken) async {
    final currentAccessToken = await _tokenStorage.readAccessToken();
    if (currentAccessToken != null &&
        currentAccessToken.isNotEmpty &&
        currentAccessToken != failedAccessToken) {
      return currentAccessToken;
    }

    final inProgress = _refreshInProgress;
    if (inProgress != null) return inProgress;

    final refresh = _refreshAccessToken();
    _refreshInProgress = refresh;
    return refresh.whenComplete(() {
      if (identical(_refreshInProgress, refresh)) _refreshInProgress = null;
    });
  }

  @override
  Future<Never> invalidateInactiveAccount(ApiException cause) async {
    await _invalidateSession(cause);
    throw cause;
  }

  Future<String> _refreshAccessToken() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return _invalidateSession();
    }

    try {
      final refreshed = await _authService.refresh(refreshToken);
      await _tokenStorage.saveTokens(
        accessToken: refreshed.accessToken,
        refreshToken: refreshed.refreshToken,
      );
      return refreshed.accessToken;
    } on ApiException catch (error) {
      if (_isRecoverable(error)) rethrow;
      return _invalidateSession(error);
    } on Object {
      return _invalidateSession();
    }
  }

  Future<String> _invalidateSession([ApiException? cause]) async {
    await _tokenStorage.clearTokens();
    for (final listener in List.of(_sessionInvalidatedListeners)) {
      listener();
    }
    throw cause?.type == ApiErrorType.inactiveAccount
        ? cause!
        : const ApiException(
            ApiErrorType.authentication,
            'Tu sesión ya no es válida. Inicia sesión nuevamente.',
            statusCode: 401,
          );
  }

  Future<SessionRestoreResult> restoreSession() {
    final inProgress = _restoreInProgress;
    if (inProgress != null) return inProgress;

    final restore = _restore();
    _restoreInProgress = restore;
    return restore.whenComplete(() {
      if (identical(_restoreInProgress, restore)) {
        _restoreInProgress = null;
      }
    });
  }

  Future<SessionRestoreResult> _restore() async {
    final accessToken = await _tokenStorage.readAccessToken();
    final refreshToken = await _tokenStorage.readRefreshToken();

    if (accessToken == null && refreshToken == null) {
      return const SessionRestoreResult.noSession();
    }
    if (accessToken == null || refreshToken == null) {
      await _tokenStorage.clearTokens();
      return const SessionRestoreResult.invalid();
    }

    try {
      final profile = await _profileService.getProfile(accessToken);
      return SessionRestoreResult.valid(profile);
    } on ApiException catch (error) {
      if (_isRecoverable(error)) {
        return SessionRestoreResult.recoverableError(error.message);
      }
      if (error.type == ApiErrorType.inactiveAccount) {
        await _tokenStorage.clearTokens();
        return const SessionRestoreResult.invalid();
      }
      if (error.type != ApiErrorType.authentication) {
        return SessionRestoreResult.recoverableError(error.message);
      }
    }

    return _refreshAndRestoreProfile(refreshToken);
  }

  Future<SessionRestoreResult> _refreshAndRestoreProfile(
    String refreshToken,
  ) async {
    try {
      final refreshed = await _authService.refresh(refreshToken);
      await _tokenStorage.saveTokens(
        accessToken: refreshed.accessToken,
        refreshToken: refreshed.refreshToken,
      );

      try {
        final profile = await _profileService.getProfile(refreshed.accessToken);
        return SessionRestoreResult.valid(profile);
      } on ApiException catch (error) {
        if (_isRecoverable(error)) {
          return SessionRestoreResult.recoverableError(error.message);
        }
        if (error.type == ApiErrorType.authentication ||
            error.type == ApiErrorType.inactiveAccount) {
          await _tokenStorage.clearTokens();
          return const SessionRestoreResult.invalid();
        }
        return SessionRestoreResult.recoverableError(error.message);
      }
    } on ApiException catch (error) {
      if (_isRecoverable(error)) {
        return SessionRestoreResult.recoverableError(error.message);
      }
      await _tokenStorage.clearTokens();
      return const SessionRestoreResult.invalid();
    } on Object {
      await _tokenStorage.clearTokens();
      return const SessionRestoreResult.invalid();
    }
  }

  Future<void> logout() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    try {
      if (refreshToken != null) await _authService.logout(refreshToken);
    } finally {
      await _tokenStorage.clearTokens();
    }
  }

  bool _isRecoverable(ApiException error) {
    return error.type == ApiErrorType.network ||
        error.type == ApiErrorType.timeout ||
        error.type == ApiErrorType.server;
  }
}
