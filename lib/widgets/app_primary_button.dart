import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.enabled = true,
    this.icon,
    super.key,
  });

  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool enabled;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final spacing =
        Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final canPress = enabled && !isLoading;

    return Semantics(
      button: true,
      enabled: canPress,
      label: isLoading ? '$text. Cargando' : text,
      child: ExcludeSemantics(
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: canPress ? onPressed : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(kMinInteractiveDimension),
              padding: EdgeInsets.symmetric(
                horizontal: spacing.large,
                vertical: spacing.medium,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: isLoading ? 0 : 1,
                  child: _ButtonLabel(text: text, icon: icon),
                ),
                if (isLoading)
                  const SizedBox.square(
                    dimension: kMinInteractiveDimension / 2,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ButtonLabel extends StatelessWidget {
  const _ButtonLabel({required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (icon == null) return Text(text);

    final spacing =
        Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon),
        SizedBox(width: spacing.small),
        Flexible(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
