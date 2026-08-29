import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

class DonationCard extends StatelessWidget {
  const DonationCard({
    required this.image,
    required this.title,
    required this.category,
    required this.location,
    required this.status,
    this.imageFit = BoxFit.cover,
    this.onTap,
    this.subtitle,
    super.key,
  });

  final ImageProvider<Object>? image;
  final String title;
  final String category;
  final String location;
  final String status;
  final BoxFit imageFit;
  final VoidCallback? onTap;
  final String? subtitle;

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
          '$title. Categoría: $category. Ubicación: $location. Estado: $status',
      child: ExcludeSemantics(
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: _OptionalInkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(radius.card),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _DonationImage(image: image, fit: imageFit),
                ),
                Padding(
                  padding: EdgeInsets.all(spacing.medium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleLarge),
                      if (subtitle != null) ...[
                        SizedBox(height: spacing.small),
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                      SizedBox(height: spacing.medium),
                      _Metadata(icon: Icons.category_outlined, text: category),
                      SizedBox(height: spacing.small),
                      _Metadata(
                        icon: Icons.location_on_outlined,
                        text: location,
                      ),
                      SizedBox(height: spacing.medium),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(radius.field),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: spacing.medium,
                            vertical: spacing.small,
                          ),
                          child: Text(
                            status,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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

class _OptionalInkWell extends StatelessWidget {
  const _OptionalInkWell({
    required this.onTap,
    required this.borderRadius,
    required this.child,
  });

  final VoidCallback? onTap;
  final BorderRadius borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) => onTap == null
      ? child
      : InkWell(onTap: onTap, borderRadius: borderRadius, child: child);
}

class _DonationImage extends StatelessWidget {
  const _DonationImage({required this.image, required this.fit});

  final ImageProvider<Object>? image;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (image == null) return const _ImagePlaceholder();
    final colors =
        Theme.of(context).extension<AppColorTokens>() ??
        const AppColorTokens.standard();
    return ColoredBox(
      key: const Key('donationCardImageViewport'),
      color: colors.background,
      child: Image(
        key: const Key('donationCardImage'),
        image: image!,
        fit: fit,
        excludeFromSemantics: true,
        errorBuilder: (context, error, stackTrace) => const _ImagePlaceholder(),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).extension<AppColorTokens>() ??
        const AppColorTokens.standard();
    return ColoredBox(
      key: const Key('donationImagePlaceholder'),
      color: colors.background,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: colors.textSecondary,
        ),
      ),
    );
  }
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
