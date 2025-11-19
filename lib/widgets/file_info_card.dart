import 'package:flutter/material.dart';
import '../models/audio_file.dart';
import '../utils/constants.dart';

/// Widget displaying file information with optional rename action
/// Follows Single Responsibility Principle: Only displays file info
class FileInfoCard extends StatelessWidget {
  final AudioFile file;
  final VoidCallback? onRename;

  const FileInfoCard({
    super.key,
    required this.file,
    this.onRename,
  });

  IconData _getIconForExtension(String extension) {
    switch (extension.toLowerCase()) {
      case 'mp3':
      case 'mpeg':
        return Icons.music_note;
      case 'wav':
        return Icons.graphic_eq;
      case 'mp4':
      case 'm4a':
        return Icons.audio_file;
      default:
        return Icons.audio_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppConstants.cardElevation,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              ),
              child: Icon(
                _getIconForExtension(file.extension),
                size: 32,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${file.formattedSize} • ${file.extension.toUpperCase()}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                  ),
                ],
              ),
            ),
            if (onRename != null)
              IconButton(
                onPressed: onRename,
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Umbenennen',
              ),
          ],
        ),
      ),
    );
  }
}
