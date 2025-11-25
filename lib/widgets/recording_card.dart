import 'dart:async';
import 'package:flutter/material.dart';
import '../models/transcription_history.dart';
import '../services/snackbar_service.dart';
import '../utils/constants.dart';
import 'waveform_display_widget.dart';

class RecordingCard extends StatefulWidget {
  final TranscriptionHistory history;
  final VoidCallback onPlay;
  final VoidCallback onTranscribe;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onRename;
  final VoidCallback? onExport;
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
    this.isPlaying = false,
  });

  @override
  State<RecordingCard> createState() => _RecordingCardState();
}

class _RecordingCardState extends State<RecordingCard> {
  Timer? _timer;
  late final ValueNotifier<String> _relativeTimeNotifier;

  @override
  void initState() {
    super.initState();
    _relativeTimeNotifier = ValueNotifier(_formatRelativeTime(widget.history.createdAt));
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _relativeTimeNotifier.value = _formatRelativeTime(widget.history.createdAt);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _relativeTimeNotifier.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0 
        ? "${twoDigits(duration.inHours)}:$minutes:$seconds" 
        : "$minutes:$seconds";
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'vor ${difference.inSeconds} Sek.';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return 'vor $minutes Min.';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return 'vor $hours Std.';
    } else if (difference.inDays < 365) {
      final days = difference.inDays;
      return 'vor $days ${days == 1 ? "Tag" : "Tagen"}';
    } else {
      final years = (difference.inDays / 365).floor();
      return 'vor $years ${years == 1 ? "Jahr" : "Jahren"}';
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasTranscription = widget.history.transcription != null;
    final promptCount = widget.history.promptResults.length;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Name, Prompt Count, and Menu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
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
                        if (promptCount > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                size: 14,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$promptCount Prompt${promptCount != 1 ? 's' : ''}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (widget.onDelete != null || widget.onRename != null || widget.onExport != null)
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 20),
                        padding: EdgeInsets.zero,
                        color: theme.colorScheme.surface,
                      onSelected: (value) {
                        if (value == 'rename') {
                          widget.onRename?.call();
                        } else if (value == 'export') {
                          widget.onExport?.call();
                        } else if (value == 'delete') {
                          widget.onDelete?.call();
                        }
                      },
                      itemBuilder: (context) => [
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
                                const Text('Umbenennen'),
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
                                const Text('Exportieren'),
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
                                  'Löschen',
                                  style: TextStyle(
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.s),
              
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
                        ValueListenableBuilder<String>(
                          valueListenable: _relativeTimeNotifier,
                          builder: (context, relativeTime, _) => Text(
                            relativeTime,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Tooltip(
                      message: 'Alte Aufnahme ohne Audiodatei',
                      child: GestureDetector(
                        onTap: () {
                          SnackBarService().showInfo(
                            context,
                            'Alte Aufnahme: Audiodatei nicht mehr verfügbar',
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
                  const Spacer(),
                  if (!hasTranscription)
                    ActionChip(
                      avatar: const Icon(Icons.transcribe, size: 16),
                      label: const Text('Transkribieren'),
                      onPressed: widget.onTranscribe,
                      visualDensity: VisualDensity.compact,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      side: BorderSide.none,
                    )
                  else
                    Chip(
                      avatar: const Icon(Icons.check_circle, size: 16),
                      label: const Text('Transkribiert'),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
                      side: BorderSide.none,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
