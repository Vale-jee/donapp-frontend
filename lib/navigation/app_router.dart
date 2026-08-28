import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/user_profile.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/session_gate.dart';
import '../screens/welcome_screen.dart';
import '../services/auth_service.dart';
import '../services/session_coordinator.dart';

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
  SessionCoordinator? sessionCoordinator,
  AuthService? authService,
  String initialLocation = AppRoutes.root,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: AppRoutes.root,
        builder: (context, state) =>
            SessionGate(coordinator: sessionCoordinator),
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
          initialEmail: state.uri.queryParameters['email'],
        ),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => RegisterScreen(authService: authService),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is UserProfile) return HomeScreen(profile: extra);
          return SessionGate(coordinator: sessionCoordinator);
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
