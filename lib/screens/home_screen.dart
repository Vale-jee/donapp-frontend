import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/user_profile.dart';
import '../navigation/app_router.dart';
import '../services/auth_state_controller.dart';
import '../services/session_coordinator.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'welcome_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.profile,
    this.sessionCoordinator,
    this.authState,
    super.key,
  });

  final UserProfile profile;
  final SessionCoordinator? sessionCoordinator;
  final AuthStateController? authState;

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
      if (widget.authState case final authState?) {
        await authState.logout();
      } else {
        await _sessionCoordinator.logout();
      }
    } catch (_) {
      // SessionCoordinator always removes local tokens in its finally block.
    }

    if (!mounted) return;
    if (GoRouter.maybeOf(context) != null && widget.authState != null) return;
    await Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppSpacing>() ?? const AppSpacing();
    final colors =
        theme.extension<AppColorTokens>() ?? const AppColorTokens.standard();

    return Scaffold(
      appBar: AppBar(
        title: const Text('DonApp'),
        backgroundColor: theme.colorScheme.surface,
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
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [theme.colorScheme.surface, colors.background],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(spacing.large),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '¡Hola, ${widget.profile.nombreVisible}! 👋',
                      key: const Key('homeGreeting'),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: spacing.small),
                    Text(
                      'Gracias por ser parte del cambio.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    SizedBox(height: spacing.extraLarge),
                    Text(
                      '¿Qué quieres hacer hoy?',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: spacing.large),
                    _ActionGrid(spacing: spacing),
                    SizedBox(height: spacing.extraLarge),
                    const _CommunityCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.spacing});

  final AppSpacing spacing;

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).extension<AppColorTokens>() ??
        const AppColorTokens.standard();
    final actions = [
      _HomeAction(
        key: const Key('homeDonateAction'),
        icon: Icons.volunteer_activism_outlined,
        title: 'Donar',
        description: 'Comparte algo que ya no necesitas.',
        accent: colors.accentCoral,
        onTap: null,
      ),
      _HomeAction(
        key: const Key('homeRequestAction'),
        icon: Icons.handshake_outlined,
        title: 'Solicitar',
        description: 'Encuentra apoyo dentro de tu comunidad.',
        accent: colors.accentYellow,
      ),
      _HomeAction(
        key: const Key('homeExploreAction'),
        icon: Icons.explore_outlined,
        title: 'Explorar',
        description: 'Descubre donaciones disponibles cerca de ti.',
        accent: colors.accentBlue,
        onTap: () => context.go(AppRoutes.explore),
      ),
      _HomeAction(
        key: const Key('homeMyDonationsAction'),
        icon: Icons.inventory_2_outlined,
        title: 'Mis donaciones',
        description: 'Consulta lo que has compartido.',
        accent: Theme.of(context).colorScheme.primary,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 280 ? 2 : 1;
        final width = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - spacing.medium) / 2;
        return Wrap(
          spacing: spacing.medium,
          runSpacing: spacing.medium,
          children: actions
              .map((action) => SizedBox(width: width, child: action))
              .toList(growable: false),
        );
      },
    );
  }
}

class _HomeAction extends StatelessWidget {
  const _HomeAction({
    required this.icon,
    required this.title,
    required this.description,
    required this.accent,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppSpacing>() ?? const AppSpacing();
    final radius = theme.extension<AppRadius>() ?? const AppRadius();
    final colors =
        theme.extension<AppColorTokens>() ?? const AppColorTokens.standard();
    final content = Padding(
      padding: EdgeInsets.all(spacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(radius.field),
            ),
            child: Padding(
              padding: EdgeInsets.all(spacing.small),
              child: Icon(icon, color: accent),
            ),
          ),
          SizedBox(height: spacing.medium),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: spacing.small),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          if (onTap == null) ...[
            SizedBox(height: spacing.medium),
            Text(
              'Próximamente',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );

    return Semantics(
      button: true,
      enabled: onTap != null,
      label: onTap == null
          ? '$title. $description. Próximamente.'
          : '$title. $description.',
      child: ExcludeSemantics(
        child: Card(
          elevation: 2,
          shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.12),
          clipBehavior: Clip.antiAlias,
          child: onTap == null
              ? content
              : InkWell(onTap: onTap, child: content),
        ),
      ),
    );
  }
}

class _CommunityCard extends StatelessWidget {
  const _CommunityCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppSpacing>() ?? const AppSpacing();
    final radius = theme.extension<AppRadius>() ?? const AppRadius();
    final colors =
        theme.extension<AppColorTokens>() ?? const AppColorTokens.standard();

    return Semantics(
      container: true,
      label: 'Pequeñas acciones, grandes cambios. Gracias por ayudar a tu comunidad.',
      child: ExcludeSemantics(
        child: Card(
          elevation: 2,
          shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius.featuredCard),
          ),
          child: Padding(
            padding: EdgeInsets.all(spacing.large),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.background,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(spacing.medium),
                    child: Icon(
                      Icons.favorite_outline,
                      color: colors.accentCoral,
                    ),
                  ),
                ),
                SizedBox(width: spacing.medium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pequeñas acciones, grandes cambios',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: spacing.small),
                      Text(
                        'Gracias por ayudar a tu comunidad.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
