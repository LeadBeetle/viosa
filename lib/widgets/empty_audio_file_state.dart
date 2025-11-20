import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Widget displayed when no audio file is selected
/// Provides visual guidance to the user
class EmptyAudioFileState extends StatelessWidget {
  const EmptyAudioFileState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Image.asset(
              'assets/viosa_icon.png',
              width: AppIconSize.logo,
              height: AppIconSize.logo,
              opacity: const AlwaysStoppedAnimation(0.5),
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              'Keine Audio-Datei ausgewählt',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: AppOpacity.secondary),
                  ),
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              'Tippen Sie auf das Symbol unten rechts, um eine Audio-Datei auszuwählen',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: AppOpacity.tertiary),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
