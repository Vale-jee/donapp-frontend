import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../repositories/profile_repository.dart';
import '../services/api_exception.dart';
import '../services/auth_state_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_content_state.dart';
import '../widgets/app_primary_button.dart';

String _profileInitials(UserProfile? profile) {
  final source = (profile?.nombreVisible.trim().isNotEmpty ?? false)
    ? profile!.nombreVisible.trim()
    : profile?.nombreCompleto.trim() ?? '';
  final words = source
    .split(RegExp(r'\s+'))
    .where((word) => word.isNotEmpty)
    .toList(growable: false);
  if (words.isEmpty) return '?';
  if (words.length == 1) return words.first.characters.first.toUpperCase();
  return '${words.first.characters.first}${words.last.characters.first}'
    .toUpperCase();
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    required this.profile,
    required this.profileRepository,
    this.authState,
    super.key,
  });

  final UserProfile profile;
  final ProfileRepository profileRepository;
  final AuthStateController? authState;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _fullNameController = TextEditingController();
  late final _visibleNameController = TextEditingController();
  late final _emailController = TextEditingController();
  late final _cityController = TextEditingController();
  late final _phoneController = TextEditingController();

  UserProfile? _profile;
  bool _loading = true;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _applyProfile(widget.profile);
    _loadProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _visibleNameController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final profile = await widget.profileRepository.getAuthenticatedProfile();
      if (!mounted) return;
      _applyProfile(profile);
      setState(() => _loading = false);
      widget.authState?.authenticated(profile);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'No pudimos cargar tu perfil. Intenta nuevamente.';
      });
    }
  }

  void _applyProfile(UserProfile profile) {
    _profile = profile;
    _fullNameController.text = profile.nombreCompleto;
    _visibleNameController.text = profile.nombreVisible;
    _emailController.text = profile.email;
    _cityController.text = profile.ciudad;
    _phoneController.text = profile.telefono ?? '';
  }

  String? _required(String? value, String label) =>
      value == null || value.trim().isEmpty ? '$label es obligatorio.' : null;

  String? _validateVisibleName(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.length < 3) return 'Usa al menos 3 caracteres.';
    if (normalized.length > 30) return 'Usa máximo 30 caracteres.';
    if (!RegExp(r'^[\p{L}\p{N}._]+$', unicode: true).hasMatch(normalized)) {
      return 'Usa letras, números, punto o guion bajo.';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) return null;
    if (!RegExp(r'^\+?\d{7,15}$').hasMatch(phone)) {
      return 'Usa entre 7 y 15 dígitos, con + solo al inicio.';
    }
    return null;
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) return;
    final profile = _profile;
    if (profile == null) return;
    final changes = <String, dynamic>{};
    final fullName = _fullNameController.text.trim();
    final visibleName = _visibleNameController.text.trim().toLowerCase();
    final city = _cityController.text.trim();
    final phone = _phoneController.text.trim();
    if (fullName != profile.nombreCompleto) {
      changes['nombreCompleto'] = fullName;
    }
    if (visibleName != profile.nombreVisible) {
      changes['nombreVisible'] = visibleName;
    }
    if (city != profile.ciudad) changes['ciudad'] = city;
    if (phone != (profile.telefono ?? '')) {
      changes['telefono'] = phone.isEmpty ? null : phone;
    }
    if (changes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay cambios para guardar.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final updatedProfile = await widget.profileRepository.updateProfile(
        changes: changes,
      );
      if (!mounted) return;
      _applyProfile(updatedProfile);
      widget.authState?.authenticated(updatedProfile);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado correctamente.')),
      );
      setState(() => _saving = false);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pudimos actualizar tu perfil. Intenta nuevamente.'),
        ),
      );
    }
  }

  void _showPasswordChangePlaceholder() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('El cambio de contraseña estará disponible próximamente.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppSpacing>() ?? const AppSpacing();
    final colors =
        theme.extension<AppColorTokens>() ?? const AppColorTokens.standard();
    final radius = theme.extension<AppRadius>() ?? const AppRadius();
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: AppContentState(
                  type: AppContentStateType.loading,
                  title: 'Cargando perfil',
                ),
              )
            : _errorMessage != null
            ? Center(
                child: AppContentState(
                  type: AppContentStateType.error,
                  title: 'No pudimos cargar tu perfil',
                  message: _errorMessage,
                  actionText: 'Reintentar',
                  onAction: _loadProfile,
                ),
              )
            : SingleChildScrollView(
                padding: EdgeInsets.all(spacing.large),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Card(
                      elevation: 1,
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: EdgeInsets.all(spacing.large),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: theme.colorScheme.primary,
                                    foregroundColor: theme.colorScheme.primary,
                                    child: Text(
                                      _profileInitials(_profile),
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            color: theme.colorScheme.onPrimary,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ),
                                  SizedBox(width: spacing.medium),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Información personal',
                                          style: theme.textTheme.titleLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                        SizedBox(height: spacing.small),
                                        Text(
                                          'Mantén tus datos actualizados.',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color: colors.textSecondary,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.person_outline,
                                    color: theme.colorScheme.primary,
                                  ),
                                ],
                              ),
                              SizedBox(height: spacing.extraLarge),
                              _ProfileField(
                                label: 'Nombre completo',
                                controller: _fullNameController,
                                enabled: !_saving,
                                validator: (value) =>
                                    _required(value, 'El nombre completo'),
                              ),
                              SizedBox(height: spacing.large),
                              _ProfileField(
                                label: 'Nombre visible',
                                controller: _visibleNameController,
                                enabled: !_saving,
                                validator: _validateVisibleName,
                              ),
                              SizedBox(height: spacing.large),
                              _ProfileField(
                                label: 'Correo electrónico',
                                controller: _emailController,
                                enabled: false,
                                helperText: 'El correo no se puede editar aquí.',
                                fieldKey: const Key('profileEmailField'),
                              ),
                              SizedBox(height: spacing.large),
                              _ProfileField(
                                label: 'Ciudad',
                                controller: _cityController,
                                enabled: !_saving,
                                validator: (value) =>
                                    _required(value, 'La ciudad'),
                              ),
                              SizedBox(height: spacing.large),
                              _ProfileField(
                                label: 'Teléfono (opcional)',
                                controller: _phoneController,
                                enabled: !_saving,
                                keyboardType: TextInputType.phone,
                                validator: _validatePhone,
                              ),
                              SizedBox(height: spacing.extraLarge),
                              AppPrimaryButton(
                                text: 'Guardar cambios',
                                isLoading: _saving,
                                onPressed: _save,
                              ),
                              SizedBox(height: spacing.small),
                              OutlinedButton.icon(
                                key: const Key('changePasswordButton'),
                                onPressed: _saving
                                    ? null
                                    : _showPasswordChangePlaceholder,
                                icon: const Icon(Icons.lock_reset_outlined),
                                label: const Text('Cambiar contraseña'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: theme.colorScheme.primary,
                                  side: BorderSide(
                                    color: theme.colorScheme.primary,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(radius.button),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    vertical: spacing.medium,
                                  ),
                                ),
                              ),
                              SizedBox(height: spacing.large),
                              Text(
                                'Rol',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: spacing.small),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Chip(
                                  avatar: Icon(
                                    Icons.verified_user_outlined,
                                    size: 18,
                                    color: theme.colorScheme.primary,
                                  ),
                                  label: Text(_profile?.rol.nombre ?? ''),
                                  backgroundColor: colors.background,
                                  side: BorderSide.none,
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: spacing.small,
                                  ),
                                ),
                              ),
                            ],
                          ),
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

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.controller,
    this.enabled = true,
    this.validator,
    this.keyboardType,
    this.helperText,
    this.fieldKey,
  });

  final String label;
  final TextEditingController controller;
  final bool enabled;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final String? helperText;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    final spacing =
        Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: spacing.small),
        TextFormField(
          key: fieldKey,
          controller: controller,
          enabled: enabled,
          readOnly: !enabled,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: label,
            helperText: helperText,
            prefixIcon: Icon(
              enabled ? Icons.edit_outlined : Icons.lock_outline,
              color: enabled
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: spacing.medium,
              vertical: spacing.medium,
            ),
          ),
        ),
      ],
    );
  }
}
