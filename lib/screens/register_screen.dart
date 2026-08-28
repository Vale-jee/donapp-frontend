import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../navigation/app_router.dart';
import '../services/api_exception.dart';
import '../services/auth_service.dart';
import '../widgets/app_password_field.dart';
import '../widgets/app_primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({this.authService, this.redirectLocation, super.key});

  final AuthService? authService;
  final String? redirectLocation;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCompletoController = TextEditingController();
  final _nombreVisibleController = TextEditingController();
  final _emailController = TextEditingController();
  final _ciudadController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  late final AuthService _authService;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
  }

  @override
  void dispose() {
    _nombreCompletoController.dispose();
    _nombreVisibleController.dispose();
    _emailController.dispose();
    _ciudadController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _requiredText(
    String? value,
    String field,
    int maxLength, {
    bool feminine = false,
  }) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return '$field es ${feminine ? 'obligatoria' : 'obligatorio'}.';
    }
    if (normalized.length > maxLength) {
      return '$field no puede superar $maxLength caracteres.';
    }
    return null;
  }

  String? _validateUsername(String? value) {
    final username = value?.trim() ?? '';
    if (username.isEmpty) return 'El nombre de usuario es obligatorio.';
    if (username.length < 3) return 'Debe tener al menos 3 caracteres.';
    if (username.length > 30) return 'No puede superar 30 caracteres.';
    if (!RegExp(r'^[\p{L}\p{N}._]+$', unicode: true).hasMatch(username)) {
      return 'Usa solo letras, números, punto y guion bajo.';
    }
    return null;
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
    final password = value ?? '';
    if (password.isEmpty) return 'La contraseña es obligatoria.';
    if (password.length < 8) return 'Debe tener al menos 8 caracteres.';
    if (!RegExp(r'\p{L}', unicode: true).hasMatch(password)) {
      return 'Debe incluir al menos una letra.';
    }
    if (!RegExp(r'\d').hasMatch(password)) {
      return 'Debe incluir al menos un número.';
    }
    if (utf8.encode(password).length > 72) {
      return 'La contraseña no puede superar 72 bytes.';
    }
    return null;
  }

  String? _validateConfirmation(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirma la contraseña.';
    }
    if (value != _passwordController.text) {
      return 'Las contraseñas no coinciden.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.register(
        nombreCompleto: _nombreCompletoController.text,
        nombreVisible: _nombreVisibleController.text,
        email: _emailController.text,
        password: _passwordController.text,
        ciudad: _ciudadController.text,
      );
      if (!mounted) return;
      final email = _emailController.text.trim().toLowerCase();
      if (GoRouter.maybeOf(context) case final router?) {
        if (router.canPop()) {
          router.pop(email);
        } else {
          router.go(
            AppRoutes.loginLocation(
              email: email,
              redirect: widget.redirectLocation,
            ),
          );
        }
      } else {
        Navigator.of(context).pop(email);
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'No fue posible crear la cuenta. Intenta nuevamente.';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
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
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'DonApp',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Crea tu cuenta para publicar y solicitar donaciones.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 28),
                      _textField(
                        key: const Key('registerFullNameField'),
                        controller: _nombreCompletoController,
                        label: 'Nombre completo',
                        icon: Icons.badge_outlined,
                        validator: (value) =>
                            _requiredText(value, 'El nombre completo', 100),
                      ),
                      _textField(
                        key: const Key('registerUsernameField'),
                        controller: _nombreVisibleController,
                        label: 'Nombre de usuario',
                        icon: Icons.person_outline,
                        validator: _validateUsername,
                      ),
                      _textField(
                        key: const Key('registerEmailField'),
                        controller: _emailController,
                        label: 'Correo electrónico',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        validator: _validateEmail,
                      ),
                      _textField(
                        key: const Key('registerCityField'),
                        controller: _ciudadController,
                        label: 'Ciudad',
                        icon: Icons.location_city_outlined,
                        validator: (value) => _requiredText(
                          value,
                          'La ciudad',
                          100,
                          feminine: true,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: AppPasswordField(
                          fieldKey: const Key('registerPasswordField'),
                          controller: _passwordController,
                          enabled: !_isLoading,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.newPassword],
                          validator: _validatePassword,
                        ),
                      ),
                      AppPasswordField(
                        fieldKey: const Key('registerConfirmPasswordField'),
                        label: 'Confirmar contraseña',
                        controller: _confirmPasswordController,
                        enabled: !_isLoading,
                        autofillHints: const [AutofillHints.newPassword],
                        validator: _validateConfirmation,
                      ),
                      if (_errorMessage case final message?) ...[
                        const SizedBox(height: 16),
                        Text(
                          message,
                          key: const Key('registerError'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      AppPrimaryButton(
                        key: const Key('registerButton'),
                        text: 'Crear cuenta',
                        onPressed: _submit,
                        isLoading: _isLoading,
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

  Widget _textField({
    required Key key,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    Iterable<String>? autofillHints,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        key: key,
        controller: controller,
        enabled: !_isLoading,
        keyboardType: keyboardType,
        textInputAction: TextInputAction.next,
        autofillHints: autofillHints,
        autocorrect: false,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        validator: validator,
      ),
    );
  }
}
