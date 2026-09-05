import 'package:flutter/material.dart';

import '../../utils/constants.dart';

/// Überschrift einer einzelnen Einstellung mit Symbol.
class SettingHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const SettingHeader({
    super.key,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: AppIconSize.medium,
          color: Theme.of(context)
              .colorScheme
              .primary
              .withValues(alpha: AppOpacity.secondary),
        ),
        const SizedBox(width: AppSpacing.s),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }
}

/// Erläuterung unter einer Einstellung, am Text der Überschrift ausgerichtet.
class SettingDescription extends StatelessWidget {
  final String description;

  const SettingDescription(this.description, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.indent),
      child: Text(
        description,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: AppOpacity.secondary),
            ),
      ),
    );
  }
}
