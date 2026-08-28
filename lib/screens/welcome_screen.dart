import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../navigation/app_router.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_primary_button.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({this.authService, super.key});

  final AuthService? authService;

  Future<void> _openLogin(BuildContext context, {String? initialEmail}) {
    if (GoRouter.maybeOf(context) case final router?) {
      return router.push<void>(AppRoutes.login, extra: initialEmail);
    }
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            LoginScreen(authService: authService, initialEmail: initialEmail),
      ),
    );
  }

  Future<void> _openRegister(BuildContext context) async {
    final router = GoRouter.maybeOf(context);
    final email = router != null
        ? await router.push<String>(AppRoutes.nestedRegister)
        : await Navigator.of(context).push<String>(
            MaterialPageRoute<String>(
              builder: (_) => RegisterScreen(authService: authService),
            ),
          );
    if (!context.mounted || email == null) return;
    await _openLogin(context, initialEmail: email);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppSpacing>() ?? const AppSpacing();
    final radius = theme.extension<AppRadius>() ?? const AppRadius();
    final colors =
        theme.extension<AppColorTokens>() ?? const AppColorTokens.standard();

    return Scaffold(
      body: DecoratedBox(
        key: const Key('welcomeBackground'),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.background, theme.colorScheme.surface],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(spacing.large),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final iconSize =
                        (constraints.maxWidth - spacing.extraLarge * 4)
                            .clamp(
                              spacing.extraLarge * 4,
                              spacing.extraLarge * 7,
                            )
                            .toDouble();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: SizedBox.square(
                            dimension: iconSize,
                            child: Image.asset(
                              'assets/branding/donapp_icon.png',
                              key: const Key('donAppBrandingImage'),
                              fit: BoxFit.contain,
                              excludeFromSemantics: true,
                            ),
                          ),
                        ),
                        SizedBox(height: spacing.large),
                        Text(
                          'DonApp',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineLarge?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: spacing.medium),
                        Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: spacing.extraLarge * 10,
                            ),
                            child: Text(
                              'Conecta lo que puedes donar con quienes lo necesitan.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: spacing.extraLarge),
                        AppPrimaryButton(
                          key: const Key('welcomeLoginButton'),
                          text: 'Iniciar sesión',
                          onPressed: () => _openLogin(context),
                        ),
                        SizedBox(height: spacing.medium),
                        OutlinedButton(
                          key: const Key('welcomeRegisterButton'),
                          onPressed: () => _openRegister(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.primary,
                            minimumSize: const Size.fromHeight(
                              kMinInteractiveDimension,
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: spacing.large,
                              vertical: spacing.medium,
                            ),
                            side: BorderSide(color: theme.colorScheme.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                radius.button,
                              ),
                            ),
                          ),
                          child: const Text('Registrarse'),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
