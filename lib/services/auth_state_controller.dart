import 'package:flutter/foundation.dart';

import '../models/user_profile.dart';
import 'session_coordinator.dart';

enum AuthStatus { restoring, authenticated, unauthenticated, recoverableError }

class AuthStateController extends ChangeNotifier {
  AuthStateController({SessionCoordinator? sessionCoordinator})
    : _sessionCoordinator = sessionCoordinator ?? SessionCoordinator();

  final SessionCoordinator _sessionCoordinator;
  AuthStatus _status = AuthStatus.restoring;
  UserProfile? _profile;
  String? _message;
  Future<void>? _restoreInProgress;

  AuthStatus get status => _status;
  UserProfile? get profile => _profile;
  String? get message => _message;

  Future<void> restore() {
    final inProgress = _restoreInProgress;
    if (inProgress != null) return inProgress;

    _setState(AuthStatus.restoring);
    final restoration = _restore();
    _restoreInProgress = restoration;
    return restoration.whenComplete(() {
      if (identical(_restoreInProgress, restoration)) {
        _restoreInProgress = null;
      }
    });
  }

  Future<void> _restore() async {
    try {
      final result = await _sessionCoordinator.restoreSession();
      switch (result.status) {
        case SessionRestoreStatus.valid:
          _setState(AuthStatus.authenticated, profile: result.profile);
        case SessionRestoreStatus.noSession:
        case SessionRestoreStatus.invalid:
          _setState(AuthStatus.unauthenticated);
        case SessionRestoreStatus.recoverableError:
          _setState(AuthStatus.recoverableError, message: result.message);
      }
    } on Object {
      _setState(
        AuthStatus.recoverableError,
        message: 'Verifica tu conexión e intenta nuevamente.',
      );
    }
  }

  void authenticated(UserProfile profile) {
    _setState(AuthStatus.authenticated, profile: profile);
  }

  Future<void> logout() async {
    try {
      await _sessionCoordinator.logout();
    } finally {
      _setState(AuthStatus.unauthenticated);
    }
  }

  void _setState(AuthStatus status, {UserProfile? profile, String? message}) {
    final nextProfile = status == AuthStatus.authenticated ? profile : null;
    final nextMessage = status == AuthStatus.recoverableError ? message : null;
    if (_status == status &&
        identical(_profile, nextProfile) &&
        _message == nextMessage) {
      return;
    }
    _status = status;
    _profile = nextProfile;
    _message = nextMessage;
    notifyListeners();
  }
}
