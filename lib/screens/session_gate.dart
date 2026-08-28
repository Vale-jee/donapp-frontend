import 'dart:async';

import 'package:flutter/material.dart';

import '../services/auth_state_controller.dart';
import '../services/session_coordinator.dart';
import '../widgets/app_content_state.dart';
import 'home_screen.dart';
import 'welcome_screen.dart';

class SessionGate extends StatefulWidget {
  const SessionGate({this.authState, this.coordinator, super.key})
    : assert(authState == null || coordinator == null);

  final AuthStateController? authState;
  final SessionCoordinator? coordinator;

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  late final AuthStateController _authState;
  late final bool _ownsAuthState;

  @override
  void initState() {
    super.initState();
    _ownsAuthState = widget.authState == null;
    _authState =
        widget.authState ??
        AuthStateController(sessionCoordinator: widget.coordinator);
    unawaited(_authState.restore());
  }

  @override
  void dispose() {
    if (_ownsAuthState) _authState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _authState,
      builder: (context, child) {
        return switch (_authState.status) {
          AuthStatus.restoring => const _SessionStateScaffold(
            child: AppContentState(
              key: Key('sessionLoading'),
              type: AppContentStateType.loading,
              title: 'Comprobando tu sesión',
            ),
          ),
          AuthStatus.recoverableError => _SessionStateScaffold(
            child: AppContentState(
              key: const Key('sessionError'),
              type: AppContentStateType.error,
              title: 'No pudimos comprobar tu sesión',
              message: _authState.message,
              actionText: 'Reintentar',
              onAction: _authState.restore,
            ),
          ),
          AuthStatus.authenticated =>
            _ownsAuthState
                ? HomeScreen(profile: _authState.profile!)
                : const _SessionStateScaffold(
                    child: AppContentState(
                      type: AppContentStateType.loading,
                      title: 'Abriendo DonApp',
                    ),
                  ),
          AuthStatus.unauthenticated =>
            _ownsAuthState
                ? const WelcomeScreen()
                : const _SessionStateScaffold(
                    child: AppContentState(
                      type: AppContentStateType.loading,
                      title: 'Abriendo DonApp',
                    ),
                  ),
        };
      },
    );
  }
}

class _SessionStateScaffold extends StatelessWidget {
  const _SessionStateScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(child: SingleChildScrollView(child: child)),
      ),
    );
  }
}
