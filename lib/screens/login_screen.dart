import '../services/read_cancellation.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../navigation/app_router.dart';
import '../services/api_exception.dart';
import '../repositories/auth_repository.dart';
import '../services/auth_state_controller.dart';
import '../repositories/profile_repository.dart';
import '../repositories/session_repository.dart';
import '../widgets/app_password_field.dart';
import '../widgets/app_primary_button.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    this.authRepository,
    this.profileRepository,
    this.sessionRepository,
    this.authState,
    this.initialEmail,
    this.redirectLocation,
    super.key,
  });

  final AuthRepository? authRepository;
  final ProfileRepository? profileRepository;
  final SessionRepository? sessionRepository;
  final AuthStateController? authState;
  final String? initialEmail;
  final String? redirectLocation;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _reads = ReadCancellation();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AuthRepository _authRepository;
  late final ProfileRepository _profileRepository;
  late final SessionRepository _sessionRepository;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _authRepository = widget.authRepository ?? AuthRepository();
    _profileRepository = widget.profileRepository ?? ProfileRepository();
    _sessionRepository = widget.sessionRepository ?? SessionRepository();
    _emailController.text = widget.initialEmail?.trim().toLowerCase() ?? '';
  }

  @override
  void dispose() {
    _reads.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'El correo electrónico es obligatorio.';
    if (email.length > 254 ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Ingresa un correo electrónico válido.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'La contraseña es obligatoria.';
    return null;
  }

  Future<void> _submit() => _reads.run(() async {
    if (!mounted) return;
    if (_isLoading || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final session = await _authRepository.login(
        _emailController.text,
        _passwordController.text,
      );
      await _sessionRepository.saveTokens(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
      final profile = await _profileRepository.getProfile(session.accessToken);
      if (!mounted) return;
      if (GoRouter.maybeOf(context) != null && widget.authState != null) {
        widget.authState!.authenticated(profile);
        return;
      }
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => HomeScreen(profile: profile)),
      );
    } on RequestCancelled {
      return;
    } on ApiException catch (error) {
      if (error.type == ApiErrorType.authentication ||
          error.type == ApiErrorType.inactiveAccount) {
        await _sessionRepository.clearTokens();
      }
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'No fue posible iniciar sesión. Intenta nuevamente.';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  });

  Future<void> _openRegister() async {
    final router = GoRouter.maybeOf(context);
    final email = router != null
        ? await router.push<String>(
            AppRoutes.registerLocation(redirect: widget.redirectLocation),
          )
        : await Navigator.of(context).push<String>(
            MaterialPageRoute<String>(
              builder: (_) => RegisterScreen(authRepository: _authRepository),
            ),
          );
    if (!mounted || email == null) return;
    _emailController.text = email;
    _passwordController.clear();
    setState(() {
      _errorMessage = null;
      _successMessage =
          'Cuenta creada correctamente. Ahora puedes iniciar sesión.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.volunteer_activism,
                        size: 72,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'DonApp',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Conecta lo que puedes donar con quienes lo necesitan.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        key: const Key('emailField'),
                        controller: _emailController,
                        enabled: !_isLoading,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 16),
                      AppPasswordField(
                        controller: _passwordController,
                        enabled: !_isLoading,
                        validator: _validatePassword,
                      ),
                      if (_errorMessage case final message?) ...[
                        const SizedBox(height: 16),
                        Text(
                          message,
                          key: const Key('loginError'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      if (_successMessage case final message?) ...[
                        const SizedBox(height: 16),
                        Text(
                          message,
                          key: const Key('loginSuccess'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      AppPrimaryButton(
                        key: const Key('loginButton'),
                        text: 'Iniciar sesión',
                        onPressed: _submit,
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        key: const Key('openRegisterButton'),
                        onPressed: _isLoading ? null : _openRegister,
                        child: const Text('¿No tienes una cuenta? Regístrate'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
