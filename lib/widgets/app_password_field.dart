import 'package:flutter/material.dart';

class AppPasswordField extends StatefulWidget {
  const AppPasswordField({
    required this.controller,
    required this.enabled,
    required this.validator,
    this.fieldKey = const Key('passwordField'),
    this.label = 'Contraseña',
    this.textInputAction = TextInputAction.done,
    this.autofillHints = const [AutofillHints.password],
    super.key,
  });

  final TextEditingController controller;
  final bool enabled;
  final String? Function(String?) validator;
  final Key fieldKey;
  final String label;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: widget.fieldKey,
      controller: widget.controller,
      enabled: widget.enabled,
      obscureText: _obscureText,
      enableSuggestions: false,
      autocorrect: false,
      autofillHints: widget.autofillHints,
      textInputAction: widget.textInputAction,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: const Icon(Icons.lock_outline),
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          tooltip: _obscureText ? 'Mostrar contraseña' : 'Ocultar contraseña',
          onPressed: widget.enabled
              ? () => setState(() => _obscureText = !_obscureText)
              : null,
          icon: Icon(
            _obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
      ),
      validator: widget.validator,
    );
  }
}
