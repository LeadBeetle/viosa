import 'package:flutter/material.dart';
import '../models/transcription_history.dart';
import '../services/snackbar_service.dart';
import '../utils/constants.dart';
import '../l10n/l10n.dart';
import 'waveform_display_widget.dart';

class RecordingCard extends StatefulWidget {
  final TranscriptionHistory history;
  final VoidCallback onPlay;
  final VoidCallback onTranscribe;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onRename;
  final VoidCallback? onExport;
  final VoidCallback? onChat;
  final bool isPlaying;

  const RecordingCard({
    super.key,
    required this.history,
    required this.onPlay,
    required this.onTranscribe,
    required this.onTap,
    this.onDelete,
    this.onRename,
    this.onExport,
    this.onChat,
    this.isPlaying = false,
  });

  @override
  State<RecordingCard> createState() => _RecordingCardState();
}

class _RecordingCardState extends State<RecordingCard> {

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0 
        ? "${twoDigits(duration.inHours)}:$minutes:$seconds" 
        : "$minutes:$seconds";
  }

  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day.$month.$year, $hour:$minute';
  }

  String _getBaseNameWithoutExtension(String fileName) {
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot > 0) {
      return fileName.substring(0, lastDot);
    }
    return fileName;
  }

  String _getFileExtension(String fileName) {
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot > 0 && lastDot < fileName.length - 1) {
      return fileName.substring(lastDot + 1).toUpperCase();
    }
    return '';
  }

  Widget? _buildStatusWidget(BuildContext context, ThemeData theme, bool hasTranscription) {
    final hasAudioFile = widget.history.audioPath != null;

    if (!hasAudioFile || hasTranscription) {
      return null;
    }

    return IconButton.filled(
      onPressed: widget.onTranscribe,
      icon: const Icon(Icons.text_snippet_outlined),
      tooltip: context.l10n.transcribe,
      style: IconButton.styleFrom(
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
      ),
    );
  }

  void _showContextMenu(BuildContext context, TapDownDetails? details) {
    final theme = Theme.of(context);
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RenderBox cardBox = context.findRenderObject() as RenderBox;

    final RelativeRect position;
    if (details != null) {
      position = RelativeRect.fromRect(
        Rect.fromPoints(details.globalPosition, details.globalPosition),
        Offset.zero & overlay.size,
      );
    } else {
      final cardPosition = cardBox.localToGlobal(Offset.zero);
      position = RelativeRect.fromLTRB(
        cardPosition.dx + cardBox.size.width - 48,
        cardPosition.dy,
        cardPosition.dx + cardBox.size.width,
        cardPosition.dy + 48,
      );
    }

    showMenu<String>(
      context: context,
      position: position,
      color: theme.colorScheme.surface,
      items: [
        if (widget.onChat != null)
          PopupMenuItem<String>(
            value: 'chat',
            child: Row(
              children: [
                Icon(
                  Icons.chat_outlined,
                  color: theme.colorScheme.onSurface,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(context.l10n.chat),
              ],
            ),
          ),
        if (widget.onRename != null)
          PopupMenuItem<String>(
            value: 'rename',
            child: Row(
              children: [
                Icon(
                  Icons.edit_outlined,
                  color: theme.colorScheme.onSurface,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(context.l10n.menuRename),
              ],
            ),
          ),
        if (widget.onExport != null)
          PopupMenuItem<String>(
            value: 'export',
            child: Row(
              children: [
                Icon(
                  Icons.share_outlined,
                  color: theme.colorScheme.onSurface,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(context.l10n.menuExport),
              ],
            ),
          ),
        if (widget.onDelete != null)
          PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                Icon(
                  Icons.delete_outline,
                  color: theme.colorScheme.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  context.l10n.delete,
                  style: TextStyle(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
      ],
    ).then((value) {
      if (value == 'rename') {
        widget.onRename?.call();
      } else if (value == 'export') {
        widget.onExport?.call();
      } else if (value == 'chat') {
        widget.onChat?.call();
      } else if (value == 'delete') {
        widget.onDelete?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasTranscription = widget.history.transcription != null;
    final promptCount = widget.history.promptResults.length;
    final hasContextMenu = widget.onDelete != null || widget.onRename != null || widget.onExport != null || widget.onChat != null;
    final hasInfoRow = promptCount > 0 || widget.history.chatMessageCount > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: hasContextMenu ? () => _showContextMenu(context, null) : null,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Name, Prompt Count, and Info
                  Padding(
                    padding: EdgeInsets.only(right: hasContextMenu ? 32 : 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _getBaseNameWithoutExtension(widget.history.audioFileName),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_getFileExtension(widget.history.audioFileName).isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _getFileExtension(widget.history.audioFileName),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSecondaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (hasInfoRow) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (promptCount > 0) ...[
                                Icon(
                                  Icons.auto_awesome,
                                  size: 14,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  context.l10n.promptCount(promptCount),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                              if (promptCount > 0 && widget.history.chatMessageCount > 0)
                                const SizedBox(width: 12),
                              if (widget.history.chatMessageCount > 0) ...[
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 14,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  context.l10n.messageCount(widget.history.chatMessageCount),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: hasInfoRow ? AppSpacing.s : AppSpacing.m),

                  // Waveform Visualization
                  WaveformDisplayWidget(
                    samples: widget.history.waveform,
                    height: 60,
                    showEmptyState: true,
                  ),
                  const SizedBox(height: AppSpacing.m),

                  // Footer: Controls, Time, and Status
                  Row(
                    children: [
                      if (widget.history.audioPath != null) ...[
                        IconButton.filled(
                          onPressed: widget.onPlay,
                          icon: Icon(widget.isPlaying ? Icons.pause : Icons.play_arrow),
                          style: IconButton.styleFrom(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            foregroundColor: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatDuration(widget.history.duration ?? Duration.zero),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _formatDateTime(widget.history.createdAt),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Tooltip(
                          message: context.l10n.oldRecordingNoAudio,
                          child: GestureDetector(
                            onTap: () {
                              SnackBarService().showInfo(
                                context,
                                context.l10n.oldRecordingAudioUnavailable,
                              );
                            },
                            child: Icon(
                              Icons.info_outline,
                              size: 20,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: AppSpacing.s),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: _buildStatusWidget(context, theme, hasTranscription),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Menu button positioned absolutely - offset to align icon with title
            if (hasContextMenu)
              Positioned(
                top: (AppConstants.defaultPadding - 56 / 2) + 10,
                right: AppConstants.defaultPadding - 56 / 2 + 12,
                child: SizedBox(
                  height: 56,
                  width: 56,
                  child: IconButton(
                    icon: const Icon(Icons.more_vert, size: 24),
                    padding: EdgeInsets.zero,
                    onPressed: () => _showContextMenu(context, null),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
