import 'dart:async';

import 'package:flutter/material.dart';

import 'navigation/app_router.dart';
import 'services/auth_state_controller.dart';
import 'services/session_coordinator.dart';
import 'services/offline_donations.dart';
import 'theme/app_theme.dart';

void main() => runApp(const DonApp());

class DonApp extends StatefulWidget {
  const DonApp({this.sessionCoordinator, this.offlineFactory, super.key});

  final SessionCoordinator? sessionCoordinator;
  final OfflineDonations Function(AuthStateController)? offlineFactory;

  @override
  State<DonApp> createState() => _DonAppState();
}

class _DonAppState extends State<DonApp> {
  late final _authState = AuthStateController(
    sessionCoordinator: widget.sessionCoordinator,
  );
  late final _offline =
      widget.offlineFactory?.call(_authState) ??
      OfflineDonations(authState: _authState);
  late final _router = createAppRouter(
    authState: _authState,
    offlineRepository: () => _offline.repository,
  );

  @override
  void initState() {
    super.initState();
    // Register before routing starts session restoration.
    _offline;
  }

  @override
  void dispose() {
    _router.dispose();
    unawaited(_offline.dispose());
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
