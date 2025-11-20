import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// A styled info chip that displays a label with an optional icon
/// Uses consistent design system constants for spacing and styling
class InfoChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final Color? textColor;

  const InfoChip({
    super.key,
    required this.label,
    this.icon,
    this.iconColor,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBackgroundColor = backgroundColor ??
        theme.colorScheme.surfaceContainerHighest;
    final effectiveTextColor = textColor ??
        theme.colorScheme.onSurface;
    final effectiveIconColor = iconColor ??
        theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s + 2,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: AppIconSize.small,
              color: effectiveIconColor,
            ),
            const SizedBox(width: AppSpacing.xs + 2),
          ],
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: effectiveTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
