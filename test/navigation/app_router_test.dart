import 'dart:async';

import 'package:donapp_mobile/data/local/app_database.dart';
import 'package:donapp_mobile/data/local/donation_local_data_source.dart';
import 'package:donapp_mobile/data/remote/donation_remote_data_source.dart';
import 'package:donapp_mobile/models/user_profile.dart';
import 'package:donapp_mobile/models/auth_session.dart';
import 'package:donapp_mobile/models/category.dart';
import 'package:donapp_mobile/models/donation.dart';
import 'package:donapp_mobile/models/request.dart';
import 'package:donapp_mobile/models/refreshed_tokens.dart';
import 'package:donapp_mobile/navigation/app_router.dart';
import 'package:donapp_mobile/repositories/donation_repository.dart';
import 'package:donapp_mobile/screens/home_screen.dart';
import 'package:donapp_mobile/screens/my_donations_screen.dart';
import 'package:donapp_mobile/screens/explore_donations_screen.dart';
import 'package:donapp_mobile/screens/donation_detail_screen.dart';
import 'package:donapp_mobile/screens/create_donation_screen.dart';
import 'package:donapp_mobile/screens/login_screen.dart';
import 'package:donapp_mobile/screens/register_screen.dart';
import 'package:donapp_mobile/screens/request_detail_screen.dart';
import 'package:donapp_mobile/screens/requests_screen.dart';
import 'package:donapp_mobile/screens/welcome_screen.dart';
import 'package:donapp_mobile/services/session_coordinator.dart';
import 'package:donapp_mobile/services/api_client.dart';
import 'package:donapp_mobile/services/api_error_mapper.dart';
import 'package:donapp_mobile/services/api_exception.dart';
import 'package:donapp_mobile/services/auth_service.dart';
import 'package:donapp_mobile/services/auth_state_controller.dart';
import 'package:donapp_mobile/services/category_service.dart';
import 'package:donapp_mobile/services/donation_service.dart';
import 'package:donapp_mobile/services/image_upload_service.dart';
import 'package:donapp_mobile/services/profile_service.dart';
import 'package:donapp_mobile/services/request_service.dart';
import 'package:donapp_mobile/services/token_storage.dart';
import 'package:donapp_mobile/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

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

  testWidgets(
    'wiring real del router conserva caché y muestra banner si falla el pull',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final donations = _ToggleExploreDonationService();
      final categories = _ToggleExploreCategoryService();
      final repository = DonationRepository(
        DonationLocalDataSource(db),
        DonationRemoteDataSource(donations, categories),
      );
      await repository.refreshCategories();
      await repository.refreshExplore(cacheUserId: 1);
      donations.fail = true;
      categories.fail = true;

      await _pumpAuthenticatedRouter(
        tester,
        AppRoutes.explore,
        _ValidSessionCoordinator(),
        donationRepository: repository,
      );
      expect(find.text('Donación desde router'), findsOneWidget);

      await tester.drag(
        find.byKey(const Key('exploreList')),
        const Offset(0, 350),
      );
      await tester.pumpAndSettle();

      expect(find.text('Donación desde router'), findsOneWidget);
      expect(
        find.byKey(const Key('exploreFreshnessIndicator')),
        findsOneWidget,
      );
      expect(find.textContaining('Última sincronización:'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 1));
    },
  );

  testWidgets('/donaciones/mias es privada y se reconstruye desde su URI', (
    tester,
  ) async {
    final unauthenticated = await _pumpAuthenticatedRouter(
      tester,
      AppRoutes.myDonations,
      _NoSessionCoordinator(),
    );
    expect(unauthenticated.router.state.uri.path, AppRoutes.welcome);
    expect(
      unauthenticated.router.state.uri.queryParameters['redirect'],
      AppRoutes.myDonations,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    final authenticated = await _pumpAuthenticatedRouter(
      tester,
      AppRoutes.myDonations,
      _ValidSessionCoordinator(),
      donationService: _EmptyDonationService(),
    );
    expect(authenticated.router.state.uri.path, AppRoutes.myDonations);
    expect(find.byType(MyDonationsScreen), findsOneWidget);
  });

  testWidgets('rutas de solicitudes son privadas y reconstruibles', (
    tester,
  ) async {
    final unauthenticated = await _pumpAuthenticatedRouter(
      tester,
      AppRoutes.sentRequests,
      _NoSessionCoordinator(),
    );
    expect(unauthenticated.router.state.uri.path, AppRoutes.welcome);
    expect(
      unauthenticated.router.state.uri.queryParameters['redirect'],
      AppRoutes.sentRequests,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    final authenticated = await _pumpAuthenticatedRouter(
      tester,
      AppRoutes.receivedRequests,
      _ValidSessionCoordinator(),
      requestService: _EmptyRequestService(),
    );
    expect(authenticated.router.state.uri.path, AppRoutes.receivedRequests);
    expect(find.byType(ReceivedRequestsScreen), findsOneWidget);
  });

  testWidgets('/solicitudes/7 reconstruye detalle solo desde id', (
    tester,
  ) async {
    final harness = await _pumpAuthenticatedRouter(
      tester,
      '/solicitudes/7',
      _ValidSessionCoordinator(),
      requestService: _EmptyRequestService(),
    );
    expect(harness.router.state.uri.path, '/solicitudes/7');
    expect(find.byType(RequestDetailScreen), findsOneWidget);
    expect(find.text('Solicitud de prueba'), findsOneWidget);
  });

  testWidgets('id de solicitud inválido muestra error sin servicio', (
    tester,
  ) async {
    await _pumpAuthenticatedRouter(
      tester,
      '/solicitudes/invalida',
      _ValidSessionCoordinator(),
    );
    expect(find.byKey(const Key('invalidRequestId')), findsOneWidget);
  });

  testWidgets('/donaciones/4 reconstruye el detalle solo desde el id', (
    tester,
  ) async {
    final harness = await _pumpAuthenticatedRouter(
      tester,
      '/donaciones/4',
      _ValidSessionCoordinator(),
      donationService: _EmptyDonationService(),
    );
    expect(harness.router.state.uri.path, '/donaciones/4');
    expect(find.byType(DonationDetailScreen), findsOneWidget);
    expect(find.text('Detalle de prueba'), findsOneWidget);
  });

  testWidgets('id de donación inválido muestra error controlado', (
    tester,
  ) async {
    await _pumpAuthenticatedRouter(
      tester,
      '/donaciones/no-valido',
      _ValidSessionCoordinator(),
    );
    expect(find.byKey(const Key('invalidDonationId')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no autenticado conserva el detalle como destino', (
    tester,
  ) async {
    final harness = await _pumpAuthenticatedRouter(
      tester,
      '/donaciones/4',
      _NoSessionCoordinator(),
    );
    expect(harness.router.state.uri.path, AppRoutes.welcome);
    expect(
      harness.router.state.uri.queryParameters['redirect'],
      '/donaciones/4',
    );
  });

  testWidgets('login regresa al detalle privado pretendido', (tester) async {
    final harness = await _pumpLogin(
      tester,
      AppRoutes.loginLocation(redirect: '/donaciones/4'),
    );
    await _submitLogin(tester);
    expect(harness.router.state.uri.path, '/donaciones/4');
    expect(find.byType(DonationDetailScreen), findsOneWidget);
  });

  test('validador acepta id positivo y rechaza ids inválidos', () {
    expect(AppRoutes.validPrivateRedirect('/donaciones/4'), '/donaciones/4');
    expect(AppRoutes.validPrivateRedirect('/donaciones/0'), isNull);
    expect(AppRoutes.validPrivateRedirect('/donaciones/x'), isNull);
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

  testWidgets('Home -> Explorar conserva Home para Back y muestra flecha', (
    tester,
  ) async {
    final harness = await _pumpAuthenticatedRouter(
      tester,
      AppRoutes.home,
      _ValidSessionCoordinator(),
      donationService: _EmptyDonationService(),
      categoryService: _EmptyCategoryService(),
    );

    await tester.tap(find.byKey(const Key('homeExploreAction')));
    await tester.pumpAndSettle();

    expect(find.byType(BackButton), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(harness.router.state.uri.path, AppRoutes.home);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('Home -> Mis donaciones usa push y Back vuelve a Home', (
    tester,
  ) async {
    final harness = await _pumpAuthenticatedRouter(
      tester,
      AppRoutes.home,
      _ValidSessionCoordinator(),
      donationService: _EmptyDonationService(),
    );
    await tester.tap(find.byKey(const Key('homeMyDonationsAction')));
    await tester.pumpAndSettle();
    expect(harness.router.state.uri.path, AppRoutes.myDonations);
    expect(find.byType(BackButton), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(harness.router.state.uri.path, AppRoutes.home);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('Home -> Solicitudes y Back vuelve a Home', (tester) async {
    final harness = await _pumpAuthenticatedRouter(
      tester,
      AppRoutes.home,
      _ValidSessionCoordinator(),
      requestService: _EmptyRequestService(),
    );
    await tester.tap(find.byKey(const Key('homeRequestAction')));
    await tester.pumpAndSettle();
    expect(harness.router.state.uri.path, AppRoutes.sentRequests);
    expect(find.byType(SentRequestsScreen), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(harness.router.state.uri.path, AppRoutes.home);
  });

  testWidgets('/donaciones/nueva es privada y reconstruye Crear', (
    tester,
  ) async {
    final unauthenticated = await _pumpAuthenticatedRouter(
      tester,
      AppRoutes.createDonation,
      _NoSessionCoordinator(),
    );
    expect(unauthenticated.router.state.uri.path, AppRoutes.welcome);
    expect(
      unauthenticated.router.state.uri.queryParameters['redirect'],
      AppRoutes.createDonation,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    final authenticated = await _pumpAuthenticatedRouter(
      tester,
      AppRoutes.createDonation,
      _ValidSessionCoordinator(),
      categoryService: _EmptyCategoryService(),
      galleryPicker: _EmptyGalleryPicker(),
    );
    expect(authenticated.router.state.uri.path, AppRoutes.createDonation);
    expect(find.byType(CreateDonationScreen), findsOneWidget);
  });

  testWidgets('Home abre Crear donación', (tester) async {
    final harness = await _pumpAuthenticatedRouter(
      tester,
      AppRoutes.home,
      _ValidSessionCoordinator(),
      categoryService: _EmptyCategoryService(),
      galleryPicker: _EmptyGalleryPicker(),
    );
    await tester.tap(find.byKey(const Key('homeDonateAction')));
    await tester.pumpAndSettle();
    expect(harness.router.state.uri.path, AppRoutes.createDonation);
    expect(find.byType(CreateDonationScreen), findsOneWidget);
  });

  testWidgets('Home -> Publicar conserva Home para Back y muestra flecha', (
    tester,
  ) async {
    final harness = await _pumpAuthenticatedRouter(
      tester,
      AppRoutes.home,
      _ValidSessionCoordinator(),
      categoryService: _EmptyCategoryService(),
      galleryPicker: _EmptyGalleryPicker(),
    );

    await tester.tap(find.byKey(const Key('homeDonateAction')));
    await tester.pumpAndSettle();

    expect(find.byType(BackButton), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(harness.router.state.uri.path, AppRoutes.home);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('Explore navega al detalle por id sin transportar objetos', (
    tester,
  ) async {
    final harness = await _pumpAuthenticatedRouter(
      tester,
      AppRoutes.explore,
      _ValidSessionCoordinator(),
      donationService: _SingleDonationService(),
      categoryService: _EmptyCategoryService(),
    );

    await tester.tap(find.byKey(const ValueKey('donationCard-4')));
    await tester.pumpAndSettle();

    expect(harness.router.state.uri.path, '/donaciones/4');
    expect(find.byType(DonationDetailScreen), findsOneWidget);
  });

  testWidgets('Home -> Explorar -> Detalle vuelve primero a Explorar', (
    tester,
  ) async {
    final harness = await _pumpAuthenticatedRouter(
      tester,
      AppRoutes.home,
      _ValidSessionCoordinator(),
      donationService: _SingleDonationService(),
      categoryService: _EmptyCategoryService(),
    );

    await tester.tap(find.byKey(const Key('homeExploreAction')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('donationCard-4')));
    await tester.pumpAndSettle();

    expect(find.byType(DonationDetailScreen), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(harness.router.state.uri.path, AppRoutes.explore);
    expect(find.byType(ExploreDonationsScreen), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
  });

  for (final directLocation in [
    AppRoutes.explore,
    AppRoutes.createDonation,
    '/donaciones/4',
  ]) {
    testWidgets('$directLocation directo no muestra una flecha falsa', (
      tester,
    ) async {
      await _pumpAuthenticatedRouter(
        tester,
        directLocation,
        _ValidSessionCoordinator(),
        donationService: _EmptyDonationService(),
        categoryService: _EmptyCategoryService(),
        galleryPicker: _EmptyGalleryPicker(),
      );

      expect(find.byType(BackButton), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

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

  testWidgets('autenticado no puede volver a Login con Back', (tester) async {
    final harness = await _pumpAuthenticatedRouter(
      tester,
      AppRoutes.login,
      _ValidSessionCoordinator(),
    );

    expect(harness.router.state.uri.path, AppRoutes.home);
    expect(find.byType(LoginScreen), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

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

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('401 definitivo sale de ruta privada y conserva redirect', (
    tester,
  ) async {
    final storage = _ExpiringTokenStorage();
    final coordinator = SessionCoordinator(
      tokenStorage: storage,
      authService: _RejectingRefreshAuthService(),
      profileService: _SuccessfulProfileService(),
    );
    final authState = AuthStateController(sessionCoordinator: coordinator);
    await authState.restore();
    final router = createAppRouter(
      authState: authState,
      initialLocation: '/donaciones/4',
      authService: _SuccessfulLoginService(),
      profileService: _SuccessfulProfileService(),
      tokenStorage: storage,
      donationService: _EmptyDonationService(),
      requestService: _EmptyRequestService(),
    );
    addTearDown(router.dispose);
    addTearDown(authState.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/donaciones/4');

    await expectLater(
      coordinator.recoverAfterUnauthorized('old-access'),
      throwsA(isA<ApiException>()),
    );
    await tester.pumpAndSettle();

    expect(authState.status, AuthStatus.unauthenticated);
    expect(router.state.uri.path, AppRoutes.welcome);
    expect(router.state.uri.queryParameters['redirect'], '/donaciones/4');

    await tester.tap(find.byKey(const Key('welcomeLoginButton')));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.login);
    expect(router.state.uri.queryParameters['redirect'], '/donaciones/4');
    await _submitLogin(tester);
    expect(router.state.uri.path, '/donaciones/4');
  });

  testWidgets('segundo 401 sale de ruta privada y conserva redirect', (
    tester,
  ) async {
    final storage = _ExpiringTokenStorage();
    final coordinator = SessionCoordinator(
      tokenStorage: storage,
      authService: _SuccessfulRefreshAuthService(),
      profileService: _SuccessfulProfileService(),
    );
    final authState = AuthStateController(sessionCoordinator: coordinator);
    await authState.restore();
    final router = createAppRouter(
      authState: authState,
      initialLocation: '/donaciones/4',
      authService: _SuccessfulLoginService(),
      profileService: _SuccessfulProfileService(),
      tokenStorage: storage,
      donationService: _EmptyDonationService(),
      requestService: _EmptyRequestService(),
    );
    addTearDown(router.dispose);
    addTearDown(authState.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    await tester.pumpAndSettle();

    var requestCount = 0;
    final client = ApiClient(
      client: MockClient((_) async {
        requestCount++;
        return http.Response(
          '{"success":false,"message":"Access token inválido."}',
          401,
        );
      }),
      endpointBuilder: (path) => Uri.parse('https://example.test$path'),
      sessionRecovery: coordinator,
    );
    await expectLater(
      client.get(
        '/protegido',
        headers: const {'Authorization': 'Bearer old-access'},
        successStatusCodes: const {200},
        context: ApiRequestContext.protectedSession,
      ),
      throwsA(isA<ApiException>()),
    );
    await tester.pumpAndSettle();

    expect(requestCount, 2);
    expect(storage.accessToken, isNull);
    expect(storage.refreshToken, isNull);
    expect(authState.status, AuthStatus.unauthenticated);
    expect(authState.profile, isNull);
    expect(router.state.uri.path, AppRoutes.welcome);
    expect(router.state.uri.queryParameters['redirect'], '/donaciones/4');

    await tester.tap(find.byKey(const Key('welcomeLoginButton')));
    await tester.pumpAndSettle();
    await _submitLogin(tester);
    expect(router.state.uri.path, '/donaciones/4');
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

  testWidgets('login regresa al destino pretendido /donaciones/mias', (
    tester,
  ) async {
    final harness = await _pumpLogin(
      tester,
      AppRoutes.loginLocation(redirect: AppRoutes.myDonations),
    );
    await _submitLogin(tester);
    expect(harness.router.state.uri.path, AppRoutes.myDonations);
    expect(find.byType(MyDonationsScreen), findsOneWidget);
  });

  testWidgets('login regresa al detalle de solicitud pretendido', (
    tester,
  ) async {
    final harness = await _pumpLogin(
      tester,
      AppRoutes.loginLocation(redirect: '/solicitudes/7'),
    );
    await _submitLogin(tester);
    expect(harness.router.state.uri.path, '/solicitudes/7');
    expect(find.byType(RequestDetailScreen), findsOneWidget);
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
    requestService: _EmptyRequestService(),
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
  DonationRepository? donationRepository,
  RequestService? requestService,
  CategoryService? categoryService,
  ImageUploadService? imageUploadService,
  DonationGalleryPicker? galleryPicker,
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
    donationRepository: donationRepository,
    requestService: requestService,
    categoryService: categoryService,
    imageUploadService: imageUploadService,
    galleryPicker: galleryPicker,
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

class _ExpiringTokenStorage extends TokenStorage {
  String? accessToken = 'old-access';
  String? refreshToken = 'old-refresh';

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
  }

  @override
  Future<void> clearTokens() async {
    accessToken = null;
    refreshToken = null;
  }
}

class _RejectingRefreshAuthService extends AuthService {
  @override
  Future<RefreshedTokens> refresh(String refreshToken) {
    throw const ApiException(
      ApiErrorType.authentication,
      'Sesión inválida.',
      statusCode: 401,
    );
  }
}

class _SuccessfulRefreshAuthService extends AuthService {
  @override
  Future<RefreshedTokens> refresh(String refreshToken) async =>
      const RefreshedTokens(
        accessToken: 'new-access',
        refreshToken: 'new-refresh',
        accessTokenExpiresIn: 900,
        refreshTokenExpiresIn: 604800,
      );
}

class _EmptyDonationService extends DonationService {
  @override
  Future<DonationPage> getOwnDonations({
    int page = 1,
    int limit = 20,
    DonationStatus? status,
  }) async => DonationPage(
    donations: const [],
    pagination: DonationPagination(
      page: page,
      limit: limit,
      total: 0,
      totalPages: 0,
    ),
  );

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

  @override
  Future<DonationDetail> getDonationById(int id) async => DonationDetail(
    id: id,
    titulo: 'Detalle de prueba',
    descripcion: 'Descripción real de prueba',
    ciudad: 'Bogotá',
    estado: DonationStatus.publicada,
    createdAt: DateTime.utc(2026, 8, 20),
    updatedAt: DateTime.utc(2026, 8, 21),
    categoriaId: 4,
    categoriaNombre: 'Muebles',
    imagenes: const [],
  );
}

class _EmptyRequestService extends RequestService {
  @override
  Future<RequestPage<SentRequestListItem>> getSentRequests({
    int page = 1,
    int limit = 20,
    RequestStatus? status,
  }) async => RequestPage(
    requests: const [],
    pagination: RequestPagination(
      page: page,
      limit: limit,
      total: 0,
      totalPages: 0,
    ),
  );

  @override
  Future<RequestPage<ReceivedRequestListItem>> getReceivedRequests({
    int page = 1,
    int limit = 20,
    RequestStatus? status,
  }) async => RequestPage(
    requests: const [],
    pagination: RequestPagination(
      page: page,
      limit: limit,
      total: 0,
      totalPages: 0,
    ),
  );

  @override
  Future<RequestDetail> getRequestById(int id) async => RequestDetail(
    id: id,
    status: RequestStatus.pendiente,
    cancellationCause: null,
    acceptedAt: null,
    rejectedAt: null,
    cancelledAt: null,
    createdAt: DateTime.utc(2026, 8, 20),
    updatedAt: DateTime.utc(2026, 8, 20),
    donation: const RequestDonationSummary(
      id: 4,
      title: 'Solicitud de prueba',
      status: RequestDonationStatus.publicada,
      mainImage: null,
    ),
    actor: RequestActor.applicant,
    otherUser: const RequestUserSummary(
      id: 2,
      visibleName: 'ana',
      profilePhoto: null,
      city: 'Bogotá',
    ),
  );
}

class _SingleDonationService extends _EmptyDonationService {
  @override
  Future<DonationPage> getAvailableDonations({
    int page = 1,
    int limit = 20,
    int? categoryId,
  }) async => DonationPage(
    donations: [
      DonationListItem(
        id: 4,
        titulo: 'Detalle de prueba',
        ciudad: 'Bogotá',
        estado: DonationStatus.publicada,
        createdAt: DateTime.utc(2026, 8, 20),
        updatedAt: DateTime.utc(2026, 8, 21),
        categoriaId: 4,
        categoriaNombre: 'Muebles',
        imagenPrincipal: null,
        cantidadImagenes: 0,
      ),
    ],
    pagination: DonationPagination(
      page: page,
      limit: limit,
      total: 1,
      totalPages: 1,
    ),
  );
}

class _EmptyCategoryService extends CategoryService {
  @override
  Future<List<Category>> getCategories() async => const [];
}

class _ToggleExploreDonationService extends DonationService {
  bool fail = false;

  @override
  Future<DonationPage> getAvailableDonations({
    int page = 1,
    int limit = 20,
    int? categoryId,
  }) async {
    if (fail) {
      throw const ApiException(ApiErrorType.network, 'Sin conexión');
    }
    return DonationPage(
      donations: [
        DonationListItem(
          id: 41,
          titulo: 'Donación desde router',
          ciudad: 'Bogotá',
          estado: DonationStatus.publicada,
          createdAt: DateTime.utc(2026, 9, 1),
          updatedAt: DateTime.utc(2026, 9, 1),
          categoriaId: 4,
          categoriaNombre: 'Muebles',
          imagenPrincipal: null,
          cantidadImagenes: 0,
        ),
      ],
      pagination: DonationPagination(
        page: page,
        limit: limit,
        total: 1,
        totalPages: 1,
      ),
    );
  }
}

class _ToggleExploreCategoryService extends CategoryService {
  bool fail = false;

  @override
  Future<List<Category>> getCategories() async {
    if (fail) {
      throw const ApiException(ApiErrorType.network, 'Sin conexión');
    }
    return const [Category(id: 4, nombre: 'Muebles', descripcion: null)];
  }
}

class _EmptyGalleryPicker implements DonationGalleryPicker {
  @override
  Future<List<XFile>> pickImages() async => const [];
  @override
  Future<List<XFile>> retrieveLostImages() async => const [];
}
