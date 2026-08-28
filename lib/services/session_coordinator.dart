import '../models/user_profile.dart';
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

class SessionCoordinator {
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
