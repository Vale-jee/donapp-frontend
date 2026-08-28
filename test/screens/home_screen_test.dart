import 'dart:async';

import 'package:donapp_mobile/models/refreshed_tokens.dart';
import 'package:donapp_mobile/models/user_profile.dart';
import 'package:donapp_mobile/screens/home_screen.dart';
import 'package:donapp_mobile/screens/welcome_screen.dart';
import 'package:donapp_mobile/services/api_exception.dart';
import 'package:donapp_mobile/services/auth_service.dart';
import 'package:donapp_mobile/services/session_coordinator.dart';
import 'package:donapp_mobile/services/token_storage.dart';
import 'package:donapp_mobile/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra el perfil real y la estructura principal', (
    tester,
  ) async {
    await tester.pumpWidget(_app(HomeScreen(profile: _profile)));

    expect(find.text('¡Hola, ana! 👋'), findsOneWidget);
    expect(find.text('Gracias por ser parte del cambio.'), findsOneWidget);
    expect(find.text('¿Qué quieres hacer hoy?'), findsOneWidget);
    expect(find.text('Donar'), findsOneWidget);
    expect(find.text('Solicitar'), findsOneWidget);
    expect(find.text('Explorar'), findsOneWidget);
    expect(find.text('Mis donaciones'), findsOneWidget);
    expect(find.text('Pequeñas acciones, grandes cambios'), findsOneWidget);
    expect(find.text('Gracias por ayudar a tu comunidad.'), findsOneWidget);
  });

  testWidgets('los cuatro accesos permanecen no interactivos', (tester) async {
    await tester.pumpWidget(_app(HomeScreen(profile: _profile)));

    for (final key in _actionKeys) {
      final action = find.byKey(key);
      expect(action, findsOneWidget);
      expect(
        find.descendant(of: action, matching: find.byType(InkWell)),
        findsNothing,
      );
    }
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('no muestra estadísticas ficticias', (tester) async {
    await tester.pumpWidget(_app(HomeScreen(profile: _profile)));

    expect(find.textContaining('128'), findsNothing);
    expect(find.textContaining('impacto total'), findsNothing);
    expect(find.textContaining('personas ayudadas'), findsNothing);
  });

  for (final textScale in [1.0, 2.0]) {
    testWidgets('no produce overflow a 240 px con escala de texto $textScale', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(240, 640);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _app(
          MediaQuery(
            data: MediaQueryData(
              size: const Size(240, 640),
              textScaler: TextScaler.linear(textScale),
            ),
            child: HomeScreen(profile: _profile),
          ),
        ),
      );
      await tester.scrollUntilVisible(
        find.text('Gracias por ayudar a tu comunidad.'),
        300,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Gracias por ayudar a tu comunidad.'), findsOneWidget);
    });
  }

  testWidgets('muestra la acción accesible Cerrar sesión', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_app(HomeScreen(profile: _profile)));

    expect(find.byKey(const Key('logoutButton')), findsOneWidget);
    expect(find.byTooltip('Cerrar sesión'), findsOneWidget);
    expect(find.bySemanticsLabel('Cerrar sesión'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('logout correcto ejecuta coordinador y abre Bienvenida', (
    tester,
  ) async {
    final coordinator = _FakeSessionCoordinator();
    await tester.pumpWidget(
      _app(HomeScreen(profile: _profile, sessionCoordinator: coordinator)),
    );

    await tester.tap(find.byKey(const Key('logoutButton')));
    await tester.pumpAndSettle();

    expect(coordinator.logoutCount, 1);
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('logout sin conexión limpia acceso local y abre Bienvenida', (
    tester,
  ) async {
    final storage = _LogoutTokenStorage();
    final coordinator = SessionCoordinator(
      authService: _LogoutAuthService(error: _networkError),
      tokenStorage: storage,
    );
    await tester.pumpWidget(
      _app(HomeScreen(profile: _profile, sessionCoordinator: coordinator)),
    );

    await tester.tap(find.byKey(const Key('logoutButton')));
    await tester.pumpAndSettle();

    expect(storage.clearCount, 1);
    expect(find.byType(WelcomeScreen), findsOneWidget);
  });

  testWidgets('Atrás no permite regresar a Home después del logout', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        HomeScreen(
          profile: _profile,
          sessionCoordinator: _FakeSessionCoordinator(),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('logoutButton')));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('doble pulsación no duplica un logout en curso', (tester) async {
    final pending = Completer<void>();
    final coordinator = _FakeSessionCoordinator(completion: pending.future);
    await tester.pumpWidget(
      _app(HomeScreen(profile: _profile, sessionCoordinator: coordinator)),
    );

    final button = find.byKey(const Key('logoutButton'));
    await tester.tap(button);
    await tester.tap(button);
    await tester.pump();

    expect(coordinator.logoutCount, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    pending.complete();
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsOneWidget);
  });
}

const _actionKeys = [
  Key('homeDonateAction'),
  Key('homeRequestAction'),
  Key('homeExploreAction'),
  Key('homeMyDonationsAction'),
];

Widget _app(Widget home) => MaterialApp(theme: AppTheme.light, home: home);

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

const _networkError = ApiException(ApiErrorType.network, 'Sin conexión.');

class _FakeSessionCoordinator extends SessionCoordinator {
  _FakeSessionCoordinator({this.completion});

  final Future<void>? completion;
  int logoutCount = 0;

  @override
  Future<void> logout() async {
    logoutCount++;
    await completion;
  }
}

class _LogoutAuthService extends AuthService {
  _LogoutAuthService({required this.error});

  final ApiException error;

  @override
  Future<void> logout(String refreshToken) async => throw error;

  @override
  Future<RefreshedTokens> refresh(String refreshToken) {
    throw UnimplementedError();
  }
}

class _LogoutTokenStorage extends TokenStorage {
  int clearCount = 0;

  @override
  Future<String?> readRefreshToken() async => 'refresh-token';

  @override
  Future<void> clearTokens() async {
    clearCount++;
  }
}
