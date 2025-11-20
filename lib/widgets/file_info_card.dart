import 'package:flutter/material.dart';
import '../models/audio_file.dart';
import '../utils/constants.dart';
import '../utils/audio_utils.dart';

/// Widget displaying file information with optional rename action
/// Follows Single Responsibility Principle: Only displays file info
class FileInfoCard extends StatelessWidget {
  final AudioFile file;
  final VoidCallback? onRename;
  final Duration? duration;

  const FileInfoCard({
    super.key,
    required this.file,
    this.onRename,
    this.duration,
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

  String _getFileNameWithoutExtension() {
    if (file.name.contains('.')) {
      return file.name.substring(0, file.name.lastIndexOf('.'));
    }
    return file.name;
  }

  String _buildFileInfo() {
    final parts = <String>[
      file.formattedSize,
      file.extension.toUpperCase(),
    ];

    if (duration != null && duration != Duration.zero) {
      parts.add(AudioUtils.formatDuration(duration!));
    }

    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _getIconForExtension(file.extension),
              size: AppIconSize.large,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Text(
                _getFileNameWithoutExtension(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onRename != null)
              IconButton(
                onPressed: onRename,
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Umbenennen',
                iconSize: AppIconSize.medium,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
        Padding(
          padding: EdgeInsets.only(left: AppIconSize.large + AppSpacing.m),
          child: Text(
            _buildFileInfo(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: AppOpacity.secondary),
                ),
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        Divider(
          height: 1,
          thickness: 1,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ],
    );
  }
}
