import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/home_screen.dart';
import '../screens/explore_donations_screen.dart';
import '../screens/donation_detail_screen.dart';
import '../screens/create_donation_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/session_gate.dart';
import '../screens/welcome_screen.dart';
import '../services/auth_service.dart';
import '../services/auth_state_controller.dart';
import '../services/category_service.dart';
import '../services/donation_service.dart';
import '../services/image_upload_service.dart';
import '../services/profile_service.dart';
import '../services/token_storage.dart';

abstract final class AppRoutes {
  static const root = '/';
  static const welcome = '/bienvenida';
  static const login = '/login';
  static const register = '/registro';
  static const nestedRegister = '/bienvenida/registro';
  static const home = '/inicio';
  static const explore = '/explorar';
  static const createDonation = '/donaciones/nueva';
  static const donationDetailPattern = '/donaciones/:id';

  static String donationDetailLocation(int id) => '/donaciones/$id';

  static String rootLocation({String? redirect}) =>
      _location(root, redirect: redirect);

  static String welcomeLocation({String? redirect}) =>
      _location(welcome, redirect: redirect);

  static String loginLocation({String? email, String? redirect}) {
    return Uri(
      path: login,
      queryParameters: {'email': ?email, 'redirect': ?redirect},
    ).toString();
  }

  static String registerLocation({String? redirect}) =>
      _location(register, redirect: redirect);

  static String nestedRegisterLocation({String? redirect}) =>
      _location(nestedRegister, redirect: redirect);

  static String? validPrivateRedirect(String? value) {
    if (value == null || value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.scheme.isNotEmpty ||
        uri.hasAuthority ||
        uri.fragment.isNotEmpty ||
        !_isPrivateUri(uri)) {
      return null;
    }
    return uri.toString();
  }

  static String _location(String path, {String? redirect}) => Uri(
    path: path,
    queryParameters: redirect == null ? null : {'redirect': redirect},
  ).toString();
}

GoRouter createAppRouter({
  required AuthStateController authState,
  AuthService? authService,
  ProfileService? profileService,
  TokenStorage? tokenStorage,
  DonationService? donationService,
  CategoryService? categoryService,
  ImageUploadService? imageUploadService,
  DonationGalleryPicker? galleryPicker,
  String initialLocation = AppRoutes.root,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: authState,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isPublic = _publicLocations.contains(location);
      final requestedRedirect = state.uri.queryParameters['redirect'];
      final validRedirect = AppRoutes.validPrivateRedirect(requestedRedirect);
      final requestedPrivateLocation = _isPrivateUri(state.uri)
          ? state.uri.toString()
          : null;

      return switch (authState.status) {
        AuthStatus.restoring || AuthStatus.recoverableError =>
          location == AppRoutes.root
              ? null
              : AppRoutes.rootLocation(
                  redirect: requestedPrivateLocation ?? validRedirect,
                ),
        AuthStatus.unauthenticated =>
          _isPrivateUri(state.uri)
              ? authState.consumeExplicitLogout()
                    ? AppRoutes.welcome
                    : AppRoutes.welcomeLocation(
                        redirect: requestedPrivateLocation,
                      )
              : location == AppRoutes.root
              ? AppRoutes.welcomeLocation(redirect: validRedirect)
              : requestedRedirect != null && validRedirect == null
              ? _publicLocationWithoutRedirect(state)
              : null,
        AuthStatus.authenticated =>
          isPublic || location == AppRoutes.root
              ? validRedirect ?? AppRoutes.home
              : null,
      };
    },
    routes: [
      GoRoute(
        path: AppRoutes.root,
        builder: (context, state) => SessionGate(authState: authState),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => WelcomeScreen(
          authService: authService,
          redirectLocation: AppRoutes.validPrivateRedirect(
            state.uri.queryParameters['redirect'],
          ),
        ),
        routes: [
          GoRoute(
            path: 'registro',
            builder: (context, state) => RegisterScreen(
              authService: authService,
              redirectLocation: AppRoutes.validPrivateRedirect(
                state.uri.queryParameters['redirect'],
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => LoginScreen(
          authService: authService,
          profileService: profileService,
          tokenStorage: tokenStorage,
          authState: authState,
          initialEmail: state.uri.queryParameters['email'],
          redirectLocation: AppRoutes.validPrivateRedirect(
            state.uri.queryParameters['redirect'],
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => RegisterScreen(
          authService: authService,
          redirectLocation: AppRoutes.validPrivateRedirect(
            state.uri.queryParameters['redirect'],
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) =>
            HomeScreen(profile: authState.profile!, authState: authState),
      ),
      GoRoute(
        path: AppRoutes.explore,
        builder: (context, state) => ExploreDonationsScreen(
          donationService: donationService,
          categoryService: categoryService,
        ),
      ),
      GoRoute(
        path: AppRoutes.createDonation,
        builder: (context, state) => CreateDonationScreen(
          donationService: donationService,
          categoryService: categoryService,
          imageUploadService: imageUploadService,
          galleryPicker: galleryPicker,
        ),
      ),
      GoRoute(
        path: AppRoutes.donationDetailPattern,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null || id <= 0) return const _InvalidDonationRoute();
          return DonationDetailScreen(
            donationId: id,
            donationService: donationService,
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: SafeArea(
        child: Center(
          child: Text(
            'Ruta no encontrada',
            key: const Key('routeNotFound'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      ),
    ),
  );
}

const _publicLocations = {
  AppRoutes.welcome,
  AppRoutes.login,
  AppRoutes.register,
  AppRoutes.nestedRegister,
};

bool _isPrivateUri(Uri uri) {
  if (_privateLocations.contains(uri.path)) return true;
  final segments = uri.pathSegments;
  final id = segments.length == 2 && segments.first == 'donaciones'
      ? int.tryParse(segments.last)
      : null;
  return id != null && id > 0;
}

const _privateLocations = {
  AppRoutes.home,
  AppRoutes.explore,
  AppRoutes.createDonation,
};

class _InvalidDonationRoute extends StatelessWidget {
  const _InvalidDonationRoute();

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: SafeArea(
      child: Center(
        child: Text(
          'La donación solicitada no es válida.',
          key: Key('invalidDonationId'),
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}

String _publicLocationWithoutRedirect(GoRouterState state) {
  return switch (state.matchedLocation) {
    AppRoutes.login => AppRoutes.loginLocation(
      email: state.uri.queryParameters['email'],
    ),
    AppRoutes.register => AppRoutes.register,
    AppRoutes.nestedRegister => AppRoutes.nestedRegister,
    _ => AppRoutes.welcome,
  };
}
