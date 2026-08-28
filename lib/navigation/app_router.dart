import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/user_profile.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/session_gate.dart';
import '../screens/welcome_screen.dart';
import '../services/session_coordinator.dart';

abstract final class AppRoutes {
  static const root = '/';
  static const welcome = '/bienvenida';
  static const login = '/login';
  static const register = '/registro';
  static const nestedRegister = '/bienvenida/registro';
  static const home = '/inicio';
}

GoRouter createAppRouter({
  SessionCoordinator? sessionCoordinator,
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
        builder: (context, state) => const WelcomeScreen(),
        routes: [
          GoRoute(
            path: 'registro',
            builder: (context, state) => const RegisterScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => LoginScreen(
          initialEmail: state.extra is String ? state.extra! as String : null,
        ),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
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
