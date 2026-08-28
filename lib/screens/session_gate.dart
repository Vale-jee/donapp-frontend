import 'package:flutter/material.dart';

import '../services/session_coordinator.dart';
import '../widgets/app_content_state.dart';
import 'home_screen.dart';
import 'welcome_screen.dart';

class SessionGate extends StatefulWidget {
  const SessionGate({this.coordinator, super.key});

  final SessionCoordinator? coordinator;

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  late final SessionCoordinator _coordinator;
  late Future<SessionRestoreResult> _restoration;

  @override
  void initState() {
    super.initState();
    _coordinator = widget.coordinator ?? SessionCoordinator();
    _restoration = _coordinator.restoreSession();
  }

  void _retry() {
    setState(() {
      _restoration = _coordinator.restoreSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SessionRestoreResult>(
      future: _restoration,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _SessionStateScaffold(
            child: AppContentState(
              key: Key('sessionLoading'),
              type: AppContentStateType.loading,
              title: 'Comprobando tu sesión',
            ),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return _SessionStateScaffold(
            child: AppContentState(
              key: const Key('sessionError'),
              type: AppContentStateType.error,
              title: 'No pudimos comprobar tu sesión',
              message: 'Verifica tu conexión e intenta nuevamente.',
              actionText: 'Reintentar',
              onAction: _retry,
            ),
          );
        }

        final result = snapshot.data!;
        return switch (result.status) {
          SessionRestoreStatus.valid => HomeScreen(profile: result.profile!),
          SessionRestoreStatus.noSession ||
          SessionRestoreStatus.invalid => const WelcomeScreen(),
          SessionRestoreStatus.recoverableError => _SessionStateScaffold(
            child: AppContentState(
              key: const Key('sessionError'),
              type: AppContentStateType.error,
              title: 'No pudimos comprobar tu sesión',
              message: result.message,
              actionText: 'Reintentar',
              onAction: _retry,
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
