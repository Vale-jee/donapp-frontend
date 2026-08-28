import 'package:donapp_mobile/models/user_profile.dart';
import 'package:donapp_mobile/navigation/app_router.dart';
import 'package:donapp_mobile/screens/home_screen.dart';
import 'package:donapp_mobile/screens/login_screen.dart';
import 'package:donapp_mobile/screens/register_screen.dart';
import 'package:donapp_mobile/screens/welcome_screen.dart';
import 'package:donapp_mobile/services/session_coordinator.dart';
import 'package:donapp_mobile/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('/bienvenida abre WelcomeScreen', (tester) async {
    await _pumpRoute(tester, AppRoutes.welcome);

    expect(find.byType(WelcomeScreen), findsOneWidget);
  });

  testWidgets('/login abre LoginScreen', (tester) async {
    await _pumpRoute(tester, AppRoutes.login);

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('/registro abre RegisterScreen', (tester) async {
    await _pumpRoute(tester, AppRoutes.register);

    expect(find.byType(RegisterScreen), findsOneWidget);
  });

  testWidgets('/inicio abre HomeScreen con una sesión válida', (tester) async {
    await _pumpRoute(
      tester,
      AppRoutes.home,
      sessionCoordinator: _ValidSessionCoordinator(),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('reconoce la ruta anidada /bienvenida/registro', (tester) async {
    await _pumpRoute(tester, AppRoutes.nestedRegister);

    expect(find.byType(RegisterScreen), findsOneWidget);
  });

  testWidgets('una ruta inexistente muestra un error controlado', (
    tester,
  ) async {
    await _pumpRoute(tester, '/ruta-inexistente');

    expect(find.byKey(const Key('routeNotFound')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpRoute(
  WidgetTester tester,
  String location, {
  SessionCoordinator? sessionCoordinator,
}) async {
  final router = createAppRouter(
    initialLocation: location,
    sessionCoordinator: sessionCoordinator,
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    MaterialApp.router(theme: AppTheme.light, routerConfig: router),
  );
  await tester.pump();
}

class _ValidSessionCoordinator extends SessionCoordinator {
  @override
  Future<SessionRestoreResult> restoreSession() async {
    return SessionRestoreResult.valid(
      UserProfile(
        id: 1,
        nombreCompleto: 'Ana Prueba',
        nombreVisible: 'ana',
        email: 'ana@example.com',
        ciudad: 'Bogotá',
        telefono: null,
        fotoPerfil: null,
        activo: true,
        createdAt: DateTime.utc(2026, 8, 15),
        updatedAt: DateTime.utc(2026, 8, 15),
        rol: const ProfileRole(codigo: 'USUARIO', nombre: 'Usuario'),
      ),
    );
  }
}
