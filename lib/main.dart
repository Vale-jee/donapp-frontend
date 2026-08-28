import 'package:flutter/material.dart';

import 'navigation/app_router.dart';
import 'services/auth_state_controller.dart';
import 'services/session_coordinator.dart';
import 'theme/app_theme.dart';

void main() => runApp(const DonApp());

class DonApp extends StatefulWidget {
  const DonApp({this.sessionCoordinator, super.key});

  final SessionCoordinator? sessionCoordinator;

  @override
  State<DonApp> createState() => _DonAppState();
}

class _DonAppState extends State<DonApp> {
  late final _authState = AuthStateController(
    sessionCoordinator: widget.sessionCoordinator,
  );
  late final _router = createAppRouter(authState: _authState);

  @override
  void dispose() {
    _router.dispose();
    _authState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'DonApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
