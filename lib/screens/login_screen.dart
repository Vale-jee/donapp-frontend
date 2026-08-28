import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../navigation/app_router.dart';
import '../services/api_exception.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/token_storage.dart';
import '../widgets/app_password_field.dart';
import '../widgets/app_primary_button.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    this.authService,
    this.profileService,
    this.tokenStorage,
    this.initialEmail,
    super.key,
  });

  final AuthService? authService;
  final ProfileService? profileService;
  final TokenStorage? tokenStorage;
  final String? initialEmail;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AuthService _authService;
  late final ProfileService _profileService;
  late final TokenStorage _tokenStorage;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _profileService = widget.profileService ?? ProfileService();
    _tokenStorage = widget.tokenStorage ?? TokenStorage();
    _emailController.text = widget.initialEmail?.trim().toLowerCase() ?? '';
  }

  @override
  void dispose() {
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

  Future<void> _submit() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final session = await _authService.login(
        _emailController.text,
        _passwordController.text,
      );
      await _tokenStorage.saveTokens(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
      final profile = await _profileService.getProfile(session.accessToken);
      if (!mounted) return;
      if (GoRouter.maybeOf(context) case final router?) {
        router.go(AppRoutes.home, extra: profile);
        return;
      }
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => HomeScreen(profile: profile)),
      );
    } on ApiException catch (error) {
      if (error.type == ApiErrorType.authentication ||
          error.type == ApiErrorType.inactiveAccount) {
        await _tokenStorage.clearTokens();
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
  }

  Future<void> _openRegister() async {
    final router = GoRouter.maybeOf(context);
    final email = router != null
        ? await router.push<String>(AppRoutes.register)
        : await Navigator.of(context).push<String>(
            MaterialPageRoute<String>(
              builder: (_) => RegisterScreen(authService: _authService),
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
