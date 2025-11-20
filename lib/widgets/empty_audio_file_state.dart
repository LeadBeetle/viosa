import 'package:flutter/material.dart';

/// Widget displayed when no audio file is selected
/// Provides visual guidance to the user
class EmptyAudioFileState extends StatelessWidget {
  const EmptyAudioFileState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Image.asset(
              'assets/viosa_icon.png',
              width: 120,
              height: 120,
              opacity: const AlwaysStoppedAnimation(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Keine Audio-Datei ausgewählt',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tippen Sie auf das Symbol unten rechts, um eine Audio-Datei auszuwählen',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
