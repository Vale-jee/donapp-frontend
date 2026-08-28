import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/session_gate.dart';
import '../screens/welcome_screen.dart';
import '../services/auth_service.dart';
import '../services/auth_state_controller.dart';
import '../services/profile_service.dart';
import '../services/token_storage.dart';

abstract final class AppRoutes {
  static const root = '/';
  static const welcome = '/bienvenida';
  static const login = '/login';
  static const register = '/registro';
  static const nestedRegister = '/bienvenida/registro';
  static const home = '/inicio';

  static String loginLocation({String? email}) {
    return Uri(
      path: login,
      queryParameters: email == null ? null : {'email': email},
    ).toString();
  }
}

GoRouter createAppRouter({
  required AuthStateController authState,
  AuthService? authService,
  ProfileService? profileService,
  TokenStorage? tokenStorage,
  String initialLocation = AppRoutes.root,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: authState,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isPublic = _publicLocations.contains(location);

      return switch (authState.status) {
        AuthStatus.restoring || AuthStatus.recoverableError =>
          location == AppRoutes.root ? null : AppRoutes.root,
        AuthStatus.unauthenticated =>
          _isPrivateLocation(location)
              ? AppRoutes.welcome
              : location == AppRoutes.root
              ? AppRoutes.welcome
              : null,
        AuthStatus.authenticated =>
          isPublic || location == AppRoutes.root ? AppRoutes.home : null,
      };
    },
    routes: [
      GoRoute(
        path: AppRoutes.root,
        builder: (context, state) => SessionGate(authState: authState),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => WelcomeScreen(authService: authService),
        routes: [
          GoRoute(
            path: 'registro',
            builder: (context, state) =>
                RegisterScreen(authService: authService),
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
        ),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => RegisterScreen(authService: authService),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) =>
            HomeScreen(profile: authState.profile!, authState: authState),
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

bool _isPrivateLocation(String location) {
  return location == AppRoutes.home;
}
