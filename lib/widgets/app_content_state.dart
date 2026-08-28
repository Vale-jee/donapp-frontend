import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

enum AppContentStateType { loading, empty, error }

class AppContentState extends StatelessWidget {
  const AppContentState({
    required this.type,
    required this.title,
    this.message,
    this.icon,
    this.actionText,
    this.onAction,
    super.key,
  });

  final AppContentStateType type;
  final String title;
  final String? message;
  final IconData? icon;
  final String? actionText;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppSpacing>() ?? const AppSpacing();
    final stateIcon = icon ?? _defaultIcon;
    final showAction = actionText != null && onAction != null;

    return Semantics(
      container: true,
      liveRegion: type != AppContentStateType.empty,
      child: Padding(
        padding: EdgeInsets.all(spacing.large),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (type == AppContentStateType.loading)
              const CircularProgressIndicator(semanticsLabel: 'Cargando')
            else
              Icon(
                stateIcon,
                size: kMinInteractiveDimension,
                color: type == AppContentStateType.error
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
              ),
            SizedBox(height: spacing.medium),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            if (message != null) ...[
              SizedBox(height: spacing.small),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
            ],
            if (showAction) ...[
              SizedBox(height: spacing.medium),
              OutlinedButton(onPressed: onAction, child: Text(actionText!)),
            ],
          ],
        ),
      ),
    );
  }

  IconData get _defaultIcon {
    return switch (type) {
      AppContentStateType.loading => Icons.hourglass_empty,
      AppContentStateType.empty => Icons.inbox_outlined,
      AppContentStateType.error => Icons.error_outline,
    };
  }
}
