import 'dart:async';

import 'package:donapp_mobile/models/user_profile.dart';
import 'package:donapp_mobile/models/auth_session.dart';
import 'package:donapp_mobile/models/category.dart';
import 'package:donapp_mobile/models/donation.dart';
import 'package:donapp_mobile/navigation/app_router.dart';
import 'package:donapp_mobile/screens/home_screen.dart';
import 'package:donapp_mobile/screens/explore_donations_screen.dart';
import 'package:donapp_mobile/screens/login_screen.dart';
import 'package:donapp_mobile/screens/register_screen.dart';
import 'package:donapp_mobile/screens/welcome_screen.dart';
import 'package:donapp_mobile/services/session_coordinator.dart';
import 'package:donapp_mobile/services/auth_service.dart';
import 'package:donapp_mobile/services/auth_state_controller.dart';
import 'package:donapp_mobile/services/category_service.dart';
import 'package:donapp_mobile/services/donation_service.dart';
import 'package:donapp_mobile/services/profile_service.dart';
import 'package:donapp_mobile/services/token_storage.dart';
import 'package:donapp_mobile/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('/ reconstruye SessionGate sin datos previos', (tester) async {
    await _pumpRoute(
      tester,
      AppRoutes.root,
      sessionCoordinator: _NoSessionCoordinator(),
    );
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

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

  testWidgets('/inicio se reconstruye sin extra y restaura la sesión', (
    tester,
  ) async {
    await _pumpRoute(
      tester,
      AppRoutes.home,
      sessionCoordinator: _ValidSessionCoordinator(),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('no autenticado intentando /inicio va a Bienvenida', (
    tester,
  ) async {
    final harness = await _pumpAuthenticatedRouter(
      tester,
      AppRoutes.home,
      _NoSessionCoordinator(),
    );

    expect(harness.router.state.uri.path, AppRoutes.welcome);
    expect(
      harness.router.state.uri.queryParameters['redirect'],
      AppRoutes.home,
    );
    expect(find.byType(WelcomeScreen), findsOneWidget);
  });

  testWidgets('no autenticado conserva /explorar como destino', (tester) async {
    final harness = await _pumpAuthenticatedRouter(
      tester,
      AppRoutes.explore,
      _NoSessionCoordinator(),
    );

    expect(harness.router.state.uri.path, AppRoutes.welcome);
    expect(
      harness.router.state.uri.queryParameters['redirect'],
      AppRoutes.explore,
    );
  });

  testWidgets('autenticado puede entrar directamente en /explorar', (
    tester,
  ) async {
    final harness = await _pumpAuthenticatedRouter(
      tester,
      AppRoutes.explore,
      _ValidSessionCoordinator(),
      donationService: _EmptyDonationService(),
      categoryService: _EmptyCategoryService(),
    );

    expect(harness.router.state.uri.path, AppRoutes.explore);
    expect(find.byType(ExploreDonationsScreen), findsOneWidget);
  });

  testWidgets('Home navega a /explorar', (tester) async {
    final harness = await _pumpAuthenticatedRouter(
      tester,
      AppRoutes.home,
      _ValidSessionCoordinator(),
      donationService: _EmptyDonationService(),
      categoryService: _EmptyCategoryService(),
    );

    await tester.tap(find.byKey(const Key('homeExploreAction')));
    await tester.pumpAndSettle();

    expect(harness.router.state.uri.path, AppRoutes.explore);
    expect(find.byType(ExploreDonationsScreen), findsOneWidget);
  });

  testWidgets('Bienvenida conserva el destino al abrir Login', (tester) async {
    final harness = await _pumpAuthenticatedRouter(
      tester,
      AppRoutes.home,
      _NoSessionCoordinator(),
    );

    await tester.tap(find.byKey(const Key('welcomeLoginButton')));
    await tester.pumpAndSettle();

    expect(harness.router.state.uri.path, AppRoutes.login);
    expect(
      harness.router.state.uri.queryParameters['redirect'],
      AppRoutes.home,
    );
  });

  for (final publicLocation in [
    AppRoutes.login,
    AppRoutes.register,
    AppRoutes.welcome,
    AppRoutes.nestedRegister,
  ]) {
    testWidgets('autenticado en $publicLocation va a /inicio', (tester) async {
      final harness = await _pumpAuthenticatedRouter(
        tester,
        publicLocation,
        _ValidSessionCoordinator(),
      );

      expect(harness.router.state.uri.path, AppRoutes.home);
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  }

  testWidgets('restoring muestra carga sin flash de acceso', (tester) async {
    final coordinator = _PendingSessionCoordinator();
    final authState = AuthStateController(sessionCoordinator: coordinator);
    final router = createAppRouter(
      authState: authState,
      initialLocation: AppRoutes.home,
    );
    addTearDown(router.dispose);
    addTearDown(authState.dispose);

    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    await tester.pump();

    expect(router.state.uri.path, AppRoutes.root);
    expect(find.byKey(const Key('sessionLoading')), findsOneWidget);
    expect(find.byType(WelcomeScreen), findsNothing);
    expect(find.byType(LoginScreen), findsNothing);
    expect(find.byType(HomeScreen), findsNothing);

    coordinator.complete(_profileResult());
    await tester.pumpAndSettle();

    expect(router.state.uri.path, AppRoutes.home);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('logout actualiza estado y sale de /inicio', (tester) async {
    final coordinator = _ValidSessionCoordinator();
    final harness = await _pumpAuthenticatedRouter(
      tester,
      AppRoutes.home,
      coordinator,
    );

    await tester.tap(find.byKey(const Key('logoutButton')));
    await tester.pumpAndSettle();

    expect(coordinator.logoutCalls, 1);
    expect(harness.authState.status, AuthStatus.unauthenticated);
    expect(harness.router.state.uri.path, AppRoutes.welcome);
    expect(harness.router.state.uri.queryParameters['redirect'], isNull);
    expect(find.byType(WelcomeScreen), findsOneWidget);
  });

  testWidgets('error recuperable permanece en / sin loop', (tester) async {
    final coordinator = _RecoverableSessionCoordinator();
    final authState = AuthStateController(sessionCoordinator: coordinator);
    final router = createAppRouter(
      authState: authState,
      initialLocation: AppRoutes.home,
    );
    addTearDown(router.dispose);
    addTearDown(authState.dispose);

    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    await tester.pumpAndSettle();
    await tester.pump();

    expect(authState.status, AuthStatus.recoverableError);
    expect(router.state.uri.path, AppRoutes.root);
    expect(find.byKey(const Key('sessionError')), findsOneWidget);
    expect(coordinator.restoreCalls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no inicia restauraciones simultáneas innecesarias', (
    tester,
  ) async {
    final coordinator = _PendingSessionCoordinator();
    final authState = AuthStateController(sessionCoordinator: coordinator);
    final router = createAppRouter(
      authState: authState,
      initialLocation: AppRoutes.root,
    );
    addTearDown(router.dispose);
    addTearDown(authState.dispose);

    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    await tester.pump();
    final duplicateRestore = authState.restore();
    await tester.pump();

    expect(coordinator.restoreCalls, 1);
    coordinator.complete(const SessionRestoreResult.noSession());
    await duplicateRestore;
    await tester.pumpAndSettle();

    expect(coordinator.restoreCalls, 1);
    expect(router.state.uri.path, AppRoutes.welcome);
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
    final authState = AuthStateController(
      sessionCoordinator: _NoSessionCoordinator(),
    );
    await authState.restore();
    final router = createAppRouter(
      authState: authState,
      initialLocation: AppRoutes.welcomeLocation(redirect: AppRoutes.home),
      authService: _SuccessfulRegisterService(),
    );
    addTearDown(router.dispose);
    addTearDown(authState.dispose);
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
    expect(uri.queryParameters['redirect'], AppRoutes.home);
    expect(uri.toString(), contains('ana%2Bprueba%40example.com'));
  });

  testWidgets('login correcto usa un redirect privado vÃ¡lido', (tester) async {
    final harness = await _pumpLogin(
      tester,
      AppRoutes.loginLocation(redirect: '/inicio?seccion=recientes'),
    );

    await _submitLogin(tester);

    expect(harness.router.state.uri.toString(), '/inicio?seccion=recientes');
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('login regresa al destino pretendido /explorar', (tester) async {
    final harness = await _pumpLogin(
      tester,
      AppRoutes.loginLocation(redirect: AppRoutes.explore),
    );

    await _submitLogin(tester);

    expect(harness.router.state.uri.path, AppRoutes.explore);
    expect(find.byType(ExploreDonationsScreen), findsOneWidget);
  });

  for (final invalidRedirect in [
    'https://evil.example/inicio',
    AppRoutes.login,
    '/ruta-inexistente',
  ]) {
    testWidgets('rechaza redirect no permitido: $invalidRedirect', (
      tester,
    ) async {
      final harness = await _pumpLogin(
        tester,
        AppRoutes.loginLocation(redirect: invalidRedirect),
      );

      expect(harness.router.state.uri.queryParameters['redirect'], isNull);
      await _submitLogin(tester);

      expect(harness.router.state.uri.path, AppRoutes.home);
    });
  }

  testWidgets('conserva query parameters de una URI privada', (tester) async {
    final harness = await _pumpAuthenticatedRouter(
      tester,
      '/inicio?filtro=disponibles&orden=reciente',
      _NoSessionCoordinator(),
    );

    expect(harness.router.state.uri.path, AppRoutes.welcome);
    expect(
      harness.router.state.uri.queryParameters['redirect'],
      '/inicio?filtro=disponibles&orden=reciente',
    );
  });

  testWidgets('login correcto actualiza autenticación y abre /inicio', (
    tester,
  ) async {
    final authState = AuthStateController(
      sessionCoordinator: _NoSessionCoordinator(),
    );
    await authState.restore();
    final router = createAppRouter(
      authState: authState,
      initialLocation: AppRoutes.login,
      authService: _SuccessfulLoginService(),
      profileService: _SuccessfulProfileService(),
      tokenStorage: _MemoryTokenStorage(),
    );
    addTearDown(router.dispose);
    addTearDown(authState.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );

    await tester.enterText(
      find.byKey(const Key('emailField')),
      'ana@example.com',
    );
    await tester.enterText(find.byKey(const Key('passwordField')), 'Clave1234');
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pumpAndSettle();

    expect(authState.status, AuthStatus.authenticated);
    expect(router.state.uri.path, AppRoutes.home);
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}

Future<({AuthStateController authState, GoRouter router})> _pumpLogin(
  WidgetTester tester,
  String initialLocation,
) async {
  return _pumpAuthenticatedRouter(
    tester,
    initialLocation,
    _NoSessionCoordinator(),
    authService: _SuccessfulLoginService(),
    profileService: _SuccessfulProfileService(),
    tokenStorage: _MemoryTokenStorage(),
    donationService: _EmptyDonationService(),
    categoryService: _EmptyCategoryService(),
  );
}

Future<void> _submitLogin(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('emailField')),
    'ana@example.com',
  );
  await tester.enterText(find.byKey(const Key('passwordField')), 'Clave1234');
  await tester.tap(find.byKey(const Key('loginButton')));
  await tester.pumpAndSettle();
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
  final authState = AuthStateController(
    sessionCoordinator: sessionCoordinator ?? _NoSessionCoordinator(),
  );
  await authState.restore();
  final router = createAppRouter(
    authState: authState,
    initialLocation: location,
  );
  addTearDown(router.dispose);
  addTearDown(authState.dispose);

  await tester.pumpWidget(
    MaterialApp.router(theme: AppTheme.light, routerConfig: router),
  );
  await tester.pump();
}

Future<({AuthStateController authState, GoRouter router})>
_pumpAuthenticatedRouter(
  WidgetTester tester,
  String location,
  SessionCoordinator coordinator, {
  AuthService? authService,
  ProfileService? profileService,
  TokenStorage? tokenStorage,
  DonationService? donationService,
  CategoryService? categoryService,
}) async {
  final authState = AuthStateController(sessionCoordinator: coordinator);
  await authState.restore();
  final router = createAppRouter(
    authState: authState,
    initialLocation: location,
    authService: authService,
    profileService: profileService,
    tokenStorage: tokenStorage,
    donationService: donationService,
    categoryService: categoryService,
  );
  addTearDown(router.dispose);
  addTearDown(authState.dispose);
  await tester.pumpWidget(
    MaterialApp.router(theme: AppTheme.light, routerConfig: router),
  );
  await tester.pumpAndSettle();
  return (authState: authState, router: router);
}

class _ValidSessionCoordinator extends SessionCoordinator {
  int logoutCalls = 0;

  @override
  Future<SessionRestoreResult> restoreSession() async {
    return _profileResult();
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
  }
}

class _NoSessionCoordinator extends SessionCoordinator {
  @override
  Future<SessionRestoreResult> restoreSession() async {
    return const SessionRestoreResult.noSession();
  }
}

class _RecoverableSessionCoordinator extends SessionCoordinator {
  int restoreCalls = 0;

  @override
  Future<SessionRestoreResult> restoreSession() async {
    restoreCalls++;
    return const SessionRestoreResult.recoverableError(
      'Verifica tu conexión e intenta nuevamente.',
    );
  }
}

class _PendingSessionCoordinator extends SessionCoordinator {
  final _completer = Completer<SessionRestoreResult>();
  int restoreCalls = 0;

  @override
  Future<SessionRestoreResult> restoreSession() {
    restoreCalls++;
    return _completer.future;
  }

  void complete(SessionRestoreResult result) => _completer.complete(result);
}

SessionRestoreResult _profileResult() {
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

class _SuccessfulLoginService extends AuthService {
  @override
  Future<AuthSession> login(String email, String password) async {
    return const AuthSession(
      accessToken: 'access',
      refreshToken: 'refresh',
      accessTokenExpiresIn: 900,
      refreshTokenExpiresIn: 604800,
      usuario: AuthUser(
        id: 1,
        nombreVisible: 'ana',
        fotoPerfil: null,
        rol: AuthRole(codigo: 'USUARIO', nombre: 'Usuario'),
      ),
    );
  }
}

class _SuccessfulProfileService extends ProfileService {
  @override
  Future<UserProfile> getProfile(String accessToken) async {
    return _profileResult().profile!;
  }
}

class _MemoryTokenStorage extends TokenStorage {
  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {}
}

class _EmptyDonationService extends DonationService {
  @override
  Future<DonationPage> getAvailableDonations({
    int page = 1,
    int limit = 20,
    int? categoryId,
  }) async {
    return DonationPage(
      donations: const [],
      pagination: DonationPagination(
        page: page,
        limit: limit,
        total: 0,
        totalPages: 0,
      ),
    );
  }
}

class _EmptyCategoryService extends CategoryService {
  @override
  Future<List<Category>> getCategories() async => const [];
}
