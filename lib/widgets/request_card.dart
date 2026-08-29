import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

class RequestCard extends StatelessWidget {
  const RequestCard({
    required this.image,
    required this.donationTitle,
    required this.personName,
    required this.profileImage,
    required this.personCity,
    required this.requestStatus,
    required this.donationStatus,
    required this.date,
    this.cancellationCause,
    this.onTap,
    super.key,
  });

  final ImageProvider<Object>? image;
  final String donationTitle;
  final String personName;
  final ImageProvider<Object>? profileImage;
  final String personCity;
  final String requestStatus;
  final String donationStatus;
  final String date;
  final String? cancellationCause;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppSpacing>() ?? const AppSpacing();
    final radius = theme.extension<AppRadius>() ?? const AppRadius();
    final colors =
        theme.extension<AppColorTokens>() ?? const AppColorTokens.standard();
    return Semantics(
      button: true,
      enabled: onTap != null,
      label:
          '$donationTitle. $personName, $personCity. Solicitud: $requestStatus. Donación: $donationStatus. Fecha: $date.',
      child: ExcludeSemantics(
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ColoredBox(
                    color: colors.background,
                    child: image == null
                        ? const _RequestImagePlaceholder()
                        : Image(
                            key: const Key('requestCardImage'),
                            image: image!,
                            fit: BoxFit.contain,
                            excludeFromSemantics: true,
                            errorBuilder: (_, _, _) =>
                                const _RequestImagePlaceholder(),
                          ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(spacing.medium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        donationTitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: spacing.medium),
                      Row(
                        children: [
                          CircleAvatar(
                            key: const Key('requestUserAvatar'),
                            backgroundColor: theme.colorScheme.primaryContainer,
                            backgroundImage: profileImage,
                            child: profileImage == null
                                ? const Icon(Icons.person_outline)
                                : null,
                          ),
                          SizedBox(width: spacing.small),
                          Expanded(child: Text(personName)),
                        ],
                      ),
                      SizedBox(height: spacing.small),
                      _Metadata(
                        icon: Icons.location_on_outlined,
                        text: personCity,
                      ),
                      SizedBox(height: spacing.small),
                      _Metadata(
                        icon: Icons.calendar_today_outlined,
                        text: date,
                      ),
                      SizedBox(height: spacing.medium),
                      Wrap(
                        spacing: spacing.small,
                        runSpacing: spacing.small,
                        children: [
                          _StatusChip(label: requestStatus, primary: true),
                          _StatusChip(
                            label: 'Donación: $donationStatus',
                            primary: false,
                          ),
                        ],
                      ),
                      if (cancellationCause case final cause?) ...[
                        SizedBox(height: spacing.medium),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.background,
                            borderRadius: BorderRadius.circular(radius.field),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(spacing.small),
                            child: Text(cause),
                          ),
                        ),
                      ],
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.primary});
  final String label;
  final bool primary;
  @override
  Widget build(BuildContext context) => Chip(
    label: Text(label),
    backgroundColor: primary
        ? Theme.of(context).colorScheme.primaryContainer
        : Theme.of(context).colorScheme.surface,
  );
}

class _Metadata extends StatelessWidget {
  const _Metadata({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) {
    final spacing =
        Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    return Row(
      children: [
        Icon(icon),
        SizedBox(width: spacing.small),
        Expanded(child: Text(text)),
      ],
    );
  }
}

class _RequestImagePlaceholder extends StatelessWidget {
  const _RequestImagePlaceholder();
  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).extension<AppColorTokens>() ??
        const AppColorTokens.standard();
    return Center(
      key: const Key('requestImagePlaceholder'),
      child: Icon(
        Icons.image_not_supported_outlined,
        color: colors.textSecondary,
      ),
    );
  }
}
