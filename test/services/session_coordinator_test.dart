import 'dart:async';

import 'package:donapp_mobile/models/refreshed_tokens.dart';
import 'package:donapp_mobile/models/user_profile.dart';
import 'package:donapp_mobile/services/api_exception.dart';
import 'package:donapp_mobile/services/auth_state_controller.dart';
import 'package:donapp_mobile/services/auth_service.dart';
import 'package:donapp_mobile/services/profile_service.dart';
import 'package:donapp_mobile/services/session_coordinator.dart';
import 'package:donapp_mobile/services/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SessionCoordinator.recoverAfterUnauthorized', () {
    test('rota y guarda ambos tokens', () async {
      final storage = _completeStorage();
      final auth = _FakeAuthService();
      final coordinator = _coordinator(storage: storage, authService: auth);

      final accessToken = await coordinator.recoverAfterUnauthorized(
        'old-access',
      );

      expect(accessToken, 'new-access');
      expect(auth.refreshCount, 1);
      expect(storage.savedPairs, [('new-access', 'new-refresh')]);
    });

    test('dos 401 simultáneos comparten una sola rotación', () async {
      final storage = _completeStorage();
      final pending = Completer<RefreshedTokens>();
      final auth = _FakeAuthService(refreshResult: pending.future);
      final coordinator = _coordinator(storage: storage, authService: auth);

      final first = coordinator.recoverAfterUnauthorized('old-access');
      final second = coordinator.recoverAfterUnauthorized('old-access');
      await Future<void>.delayed(Duration.zero);
      expect(auth.refreshCount, 1);

      pending.complete(_refreshed);
      expect(await Future.wait([first, second]), ['new-access', 'new-access']);
      expect(auth.refreshCount, 1);
    });

    test('un 401 tardío reutiliza el token ya rotado', () async {
      final storage = _completeStorage();
      final auth = _FakeAuthService();
      final coordinator = _coordinator(storage: storage, authService: auth);

      await coordinator.recoverAfterUnauthorized('old-access');
      final token = await coordinator.recoverAfterUnauthorized('old-access');

      expect(token, 'new-access');
      expect(auth.refreshCount, 1);
    });

    test('refresh 401 limpia tokens y notifica invalidación', () async {
      final storage = _completeStorage();
      final coordinator = _coordinator(
        storage: storage,
        authService: _FakeAuthService(refreshError: _authentication),
      );
      var invalidations = 0;
      coordinator.addSessionInvalidatedListener(() => invalidations++);

      await expectLater(
        coordinator.recoverAfterUnauthorized('old-access'),
        throwsA(
          isA<ApiException>().having(
            (error) => error.type,
            'type',
            ApiErrorType.authentication,
          ),
        ),
      );
      expect(storage.accessToken, isNull);
      expect(storage.refreshToken, isNull);
      expect(storage.clearCount, 1);
      expect(invalidations, 1);
    });

    test('refresh definitivo actualiza AuthStateController', () async {
      final storage = _completeStorage();
      final coordinator = _coordinator(
        storage: storage,
        authService: _FakeAuthService(refreshError: _authentication),
      );
      final authState = AuthStateController(sessionCoordinator: coordinator);
      addTearDown(authState.dispose);
      await authState.restore();
      expect(authState.status, AuthStatus.authenticated);

      await expectLater(
        coordinator.recoverAfterUnauthorized('old-access'),
        throwsA(isA<ApiException>()),
      );

      expect(authState.status, AuthStatus.unauthenticated);
      expect(authState.profile, isNull);
    });

    test('fallo recuperable conserva tokens y no invalida sesión', () async {
      final storage = _completeStorage();
      final coordinator = _coordinator(
        storage: storage,
        authService: _FakeAuthService(refreshError: _network),
      );
      var invalidations = 0;
      coordinator.addSessionInvalidatedListener(() => invalidations++);

      await expectLater(
        coordinator.recoverAfterUnauthorized('old-access'),
        throwsA(same(_network)),
      );
      expect(storage.accessToken, 'old-access');
      expect(storage.refreshToken, 'old-refresh');
      expect(storage.clearCount, 0);
      expect(invalidations, 0);
    });

    test('cuenta inactiva limpia tokens e invalida sesión', () async {
      final storage = _completeStorage();
      final coordinator = _coordinator(storage: storage);
      var invalidations = 0;
      coordinator.addSessionInvalidatedListener(() => invalidations++);

      await expectLater(
        coordinator.invalidateInactiveAccount(_inactive),
        throwsA(same(_inactive)),
      );

      expect(storage.accessToken, isNull);
      expect(storage.refreshToken, isNull);
      expect(invalidations, 1);
    });
  });

  group('SessionCoordinator.restoreSession', () {
    test('distingue cuando no hay tokens', () async {
      final storage = _FakeTokenStorage();
      final result = await _coordinator(storage: storage).restoreSession();

      expect(result.status, SessionRestoreStatus.noSession);
      expect(storage.clearCount, 0);
    });

    for (final partial in [
      (access: 'access', refresh: null),
      (access: null, refresh: 'refresh'),
    ]) {
      test('limpia almacenamiento parcial $partial', () async {
        final storage = _FakeTokenStorage(
          accessToken: partial.access,
          refreshToken: partial.refresh,
        );
        final result = await _coordinator(storage: storage).restoreSession();

        expect(result.status, SessionRestoreStatus.invalid);
        expect(storage.clearCount, 1);
      });
    }

    test('devuelve perfil cuando el access token es válido', () async {
      final storage = _completeStorage();
      final profileService = _FakeProfileService((token) async {
        expect(token, 'old-access');
        return _profile;
      });
      final result = await _coordinator(
        storage: storage,
        profileService: profileService,
      ).restoreSession();

      expect(result.status, SessionRestoreStatus.valid);
      expect(result.profile, same(_profile));
    });

    test('renueva una vez ante 401 y usa el access nuevo', () async {
      final storage = _completeStorage();
      final auth = _FakeAuthService();
      final requestedTokens = <String>[];
      final profileService = _FakeProfileService((token) async {
        requestedTokens.add(token);
        if (token == 'old-access') throw _authentication;
        return _profile;
      });
      final result = await _coordinator(
        storage: storage,
        authService: auth,
        profileService: profileService,
      ).restoreSession();

      expect(result.status, SessionRestoreStatus.valid);
      expect(auth.refreshCount, 1);
      expect(requestedTokens, ['old-access', 'new-access']);
    });

    test('guarda inmediatamente ambos tokens rotados', () async {
      final storage = _completeStorage();
      final result = await _coordinator(
        storage: storage,
        authService: _FakeAuthService(),
        profileService: _expiredThenValidProfile(),
      ).restoreSession();

      expect(result.status, SessionRestoreStatus.valid);
      expect(storage.accessToken, 'new-access');
      expect(storage.refreshToken, 'new-refresh');
      expect(storage.savedPairs, [('new-access', 'new-refresh')]);
    });

    test('limpia tokens cuando también falla el refresh con 401', () async {
      final storage = _completeStorage();
      final auth = _FakeAuthService(refreshError: _authentication);
      final result = await _coordinator(
        storage: storage,
        authService: auth,
        profileService: _expiredProfile(),
      ).restoreSession();

      expect(result.status, SessionRestoreStatus.invalid);
      expect(storage.clearCount, 1);
    });

    test('no renueva y limpia ante cuenta inactiva', () async {
      final storage = _completeStorage();
      final auth = _FakeAuthService();
      final profile = _FakeProfileService((_) async => throw _inactive);
      final result = await _coordinator(
        storage: storage,
        authService: auth,
        profileService: profile,
      ).restoreSession();

      expect(result.status, SessionRestoreStatus.invalid);
      expect(auth.refreshCount, 0);
      expect(storage.clearCount, 1);
    });

    for (final error in [_timeout, _network]) {
      test('conserva tokens ante error recuperable ${error.type}', () async {
        final storage = _completeStorage();
        final result = await _coordinator(
          storage: storage,
          profileService: _FakeProfileService((_) async => throw error),
        ).restoreSession();

        expect(result.status, SessionRestoreStatus.recoverableError);
        expect(storage.clearCount, 0);
        expect(storage.accessToken, 'old-access');
        expect(storage.refreshToken, 'old-refresh');
      });
    }

    test('limpia ante respuesta de refresh inválida', () async {
      final storage = _completeStorage();
      final auth = _FakeAuthService(refreshError: _unexpected);
      final result = await _coordinator(
        storage: storage,
        authService: auth,
        profileService: _expiredProfile(),
      ).restoreSession();

      expect(result.status, SessionRestoreStatus.invalid);
      expect(storage.clearCount, 1);
    });

    test(
      'conserva tokens nuevos si perfil falla por red tras refresh',
      () async {
        final storage = _completeStorage();
        final profile = _FakeProfileService((token) async {
          if (token == 'old-access') throw _authentication;
          throw _network;
        });
        final result = await _coordinator(
          storage: storage,
          authService: _FakeAuthService(),
          profileService: profile,
        ).restoreSession();

        expect(result.status, SessionRestoreStatus.recoverableError);
        expect(storage.accessToken, 'new-access');
        expect(storage.refreshToken, 'new-refresh');
        expect(storage.clearCount, 0);
      },
    );

    test(
      'comparte una restauración concurrente y evita refresh duplicado',
      () async {
        final storage = _completeStorage();
        final completer = Completer<RefreshedTokens>();
        final auth = _FakeAuthService(refreshResult: completer.future);
        final coordinator = _coordinator(
          storage: storage,
          authService: auth,
          profileService: _expiredThenValidProfile(),
        );

        final first = coordinator.restoreSession();
        final second = coordinator.restoreSession();
        await Future<void>.delayed(Duration.zero);
        expect(auth.refreshCount, 1);
        completer.complete(_refreshed);

        final results = await Future.wait([first, second]);
        expect(
          results.every(
            (result) => result.status == SessionRestoreStatus.valid,
          ),
          isTrue,
        );
        expect(auth.refreshCount, 1);
      },
    );
  });

  group('SessionCoordinator.logout', () {
    test('revoca en backend y borra tokens locales', () async {
      final storage = _completeStorage();
      final auth = _FakeAuthService();
      await _coordinator(storage: storage, authService: auth).logout();

      expect(auth.logoutTokens, ['old-refresh']);
      expect(storage.clearCount, 1);
    });

    test('borra tokens locales aunque no haya conexión', () async {
      final storage = _completeStorage();
      final auth = _FakeAuthService(logoutError: _network);

      await expectLater(
        _coordinator(storage: storage, authService: auth).logout(),
        throwsA(same(_network)),
      );
      expect(storage.clearCount, 1);
      expect(storage.accessToken, isNull);
      expect(storage.refreshToken, isNull);
    });
  });
}

SessionCoordinator _coordinator({
  required _FakeTokenStorage storage,
  _FakeAuthService? authService,
  _FakeProfileService? profileService,
}) {
  return SessionCoordinator(
    tokenStorage: storage,
    authService: authService ?? _FakeAuthService(),
    profileService:
        profileService ?? _FakeProfileService((_) async => _profile),
  );
}

_FakeTokenStorage _completeStorage() =>
    _FakeTokenStorage(accessToken: 'old-access', refreshToken: 'old-refresh');

_FakeProfileService _expiredProfile() =>
    _FakeProfileService((_) async => throw _authentication);

_FakeProfileService _expiredThenValidProfile() =>
    _FakeProfileService((token) async {
      if (token == 'old-access') throw _authentication;
      return _profile;
    });

const _refreshed = RefreshedTokens(
  accessToken: 'new-access',
  refreshToken: 'new-refresh',
  accessTokenExpiresIn: 900,
  refreshTokenExpiresIn: 604800,
);

final _profile = UserProfile(
  id: 1,
  nombreCompleto: 'Ana Pérez',
  nombreVisible: 'ana',
  email: 'ana@example.com',
  ciudad: 'Bogotá',
  telefono: null,
  fotoPerfil: null,
  activo: true,
  createdAt: DateTime.utc(2026, 8, 15),
  updatedAt: DateTime.utc(2026, 8, 15),
  rol: const ProfileRole(codigo: 'USUARIO', nombre: 'Usuario'),
);

const _authentication = ApiException(
  ApiErrorType.authentication,
  'Sesión inválida.',
  statusCode: 401,
);
const _inactive = ApiException(
  ApiErrorType.inactiveAccount,
  'Cuenta inactiva.',
  statusCode: 403,
);
const _timeout = ApiException(ApiErrorType.timeout, 'Tiempo agotado.');
const _network = ApiException(ApiErrorType.network, 'Sin conexión.');
const _unexpected = ApiException(
  ApiErrorType.unexpectedResponse,
  'Respuesta inesperada.',
);

class _FakeTokenStorage extends TokenStorage {
  _FakeTokenStorage({this.accessToken, this.refreshToken});

  String? accessToken;
  String? refreshToken;
  int clearCount = 0;
  final savedPairs = <(String, String)>[];

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
    savedPairs.add((accessToken, refreshToken));
  }

  @override
  Future<void> clearTokens() async {
    clearCount++;
    accessToken = null;
    refreshToken = null;
  }
}

class _FakeAuthService extends AuthService {
  _FakeAuthService({this.refreshError, this.logoutError, this.refreshResult});

  final ApiException? refreshError;
  final ApiException? logoutError;
  final Future<RefreshedTokens>? refreshResult;
  int refreshCount = 0;
  final logoutTokens = <String>[];

  @override
  Future<RefreshedTokens> refresh(String refreshToken) async {
    refreshCount++;
    if (refreshError case final error?) throw error;
    return refreshResult == null ? _refreshed : await refreshResult!;
  }

  @override
  Future<void> logout(String refreshToken) async {
    logoutTokens.add(refreshToken);
    if (logoutError case final error?) throw error;
  }
}

class _FakeProfileService extends ProfileService {
  _FakeProfileService(this.handler);

  final Future<UserProfile> Function(String token) handler;

  @override
  Future<UserProfile> getProfile(String accessToken) => handler(accessToken);
}
