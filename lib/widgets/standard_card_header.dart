import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Standard card header widget for consistent UI across all cards
class StandardCardHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? backgroundColor;

  const StandardCardHeader({
    super.key,
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? theme.colorScheme.primary;
    final effectiveBackgroundColor = backgroundColor ?? theme.colorScheme.primaryContainer.withValues(alpha: 0.3);

    final content = Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.s),
          decoration: BoxDecoration(
            color: effectiveBackgroundColor,
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
          child: Icon(
            icon,
            size: AppIconSize.medium,
            color: effectiveIconColor,
          ),
        ),
        const SizedBox(width: AppSpacing.m),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.s),
          trailing!,
        ],
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: content,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: content,
    );
  }
}
