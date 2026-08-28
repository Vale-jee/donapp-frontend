import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../navigation/app_router.dart';
import '../models/user_profile.dart';
import '../services/session_coordinator.dart';
import '../theme/app_spacing.dart';
import 'welcome_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.profile, this.sessionCoordinator, super.key});

  final UserProfile profile;
  final SessionCoordinator? sessionCoordinator;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final SessionCoordinator _sessionCoordinator;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _sessionCoordinator = widget.sessionCoordinator ?? SessionCoordinator();
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);

    try {
      await _sessionCoordinator.logout();
    } catch (_) {
      // SessionCoordinator always removes local tokens in its finally block.
    }

    if (!mounted) return;
    if (GoRouter.maybeOf(context) case final router?) {
      router.go(AppRoutes.welcome);
      return;
    }
    await Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final spacing =
        Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();

    return Scaffold(
      appBar: AppBar(
        title: const Text('DonApp'),
        actions: [
          Semantics(
            button: true,
            enabled: !_isLoggingOut,
            label: _isLoggingOut ? 'Cerrar sesión. Cargando' : 'Cerrar sesión',
            child: ExcludeSemantics(
              child: IconButton(
                key: const Key('logoutButton'),
                tooltip: 'Cerrar sesión',
                onPressed: _isLoggingOut ? null : _logout,
                icon: _isLoggingOut
                    ? SizedBox.square(
                        dimension: spacing.large,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Hola, ${widget.profile.nombreVisible}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('${widget.profile.nombreCompleto} · ${widget.profile.ciudad}'),
            const SizedBox(height: 8),
            Text(
              'Tu perfil está conectado. Muy pronto podrás compartir y encontrar artículos dentro de tu comunidad.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 28),
            const _FutureArea(
              icon: Icons.volunteer_activism_outlined,
              title: 'Publicar una donación',
            ),
            const _FutureArea(
              icon: Icons.search_outlined,
              title: 'Buscar donaciones',
            ),
            const _FutureArea(
              icon: Icons.handshake_outlined,
              title: 'Solicitar una donación',
            ),
          ],
        ),
      ),
    );
  }
}

class _FutureArea extends StatelessWidget {
  const _FutureArea({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: const Text('Próximamente'),
      ),
    );
  }
}
