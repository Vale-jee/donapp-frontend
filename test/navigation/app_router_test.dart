import 'package:donapp_mobile/models/user_profile.dart';
import 'package:donapp_mobile/models/auth_session.dart';
import 'package:donapp_mobile/navigation/app_router.dart';
import 'package:donapp_mobile/screens/home_screen.dart';
import 'package:donapp_mobile/screens/login_screen.dart';
import 'package:donapp_mobile/screens/register_screen.dart';
import 'package:donapp_mobile/screens/welcome_screen.dart';
import 'package:donapp_mobile/services/session_coordinator.dart';
import 'package:donapp_mobile/services/auth_service.dart';
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
    expect(_emailController(tester).text, isEmpty);
  });

  testWidgets('/login reconstruye el correo desde el query parameter', (
    tester,
  ) async {
    await _pumpRoute(tester, '/login?email=prueba%40gmail.com');

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(_emailController(tester).text, 'prueba@gmail.com');
  });

  testWidgets('decodifica correctamente caracteres especiales del correo', (
    tester,
  ) async {
    const email = 'prueba+etiqueta@gmail.com';
    final location = AppRoutes.loginLocation(email: email);

    expect(location, contains('prueba%2Betiqueta%40gmail.com'));
    await _pumpRoute(tester, location);

    expect(_emailController(tester).text, email);
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

  testWidgets('Registro abre Login con el correo incluido en la URI', (
    tester,
  ) async {
    final router = createAppRouter(
      initialLocation: AppRoutes.welcome,
      authService: _SuccessfulRegisterService(),
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );

    await tester.tap(find.byKey(const Key('welcomeRegisterButton')));
    await tester.pumpAndSettle();
    await _fillValidRegistration(tester, email: ' ANA+PRUEBA@EXAMPLE.COM ');
    final registerButton = find.byKey(const Key('registerButton'));
    await tester.ensureVisible(registerButton);
    await tester.tap(registerButton);
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(_emailController(tester).text, 'ana+prueba@example.com');
    final uri = router.state.uri;
    expect(uri.path, AppRoutes.login);
    expect(uri.queryParameters['email'], 'ana+prueba@example.com');
    expect(uri.toString(), contains('ana%2Bprueba%40example.com'));
  });
}

TextEditingController _emailController(WidgetTester tester) {
  return tester
      .widget<TextFormField>(find.byKey(const Key('emailField')))
      .controller!;
}

Future<void> _fillValidRegistration(
  WidgetTester tester, {
  required String email,
}) async {
  await tester.enterText(
    find.byKey(const Key('registerFullNameField')),
    'Ana Prueba',
  );
  await tester.enterText(
    find.byKey(const Key('registerUsernameField')),
    'ana.prueba',
  );
  await tester.enterText(find.byKey(const Key('registerEmailField')), email);
  await tester.enterText(find.byKey(const Key('registerCityField')), 'Bogotá');
  await tester.enterText(
    find.byKey(const Key('registerPasswordField')),
    'Clave1234',
  );
  await tester.enterText(
    find.byKey(const Key('registerConfirmPasswordField')),
    'Clave1234',
  );
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

class _SuccessfulRegisterService extends AuthService {
  @override
  Future<void> register({
    required String nombreCompleto,
    required String nombreVisible,
    required String email,
    required String password,
    required String ciudad,
  }) async {}

  @override
  Future<AuthSession> login(String email, String password) {
    throw UnimplementedError();
  }
}
