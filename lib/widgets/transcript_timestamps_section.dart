import 'package:flutter/material.dart';

import '../models/transcript_segment.dart';
import '../utils/constants.dart';
import '../utils/duration_formatter.dart';
import '../l10n/l10n.dart';

/// Zeigt die Zeitmarken eines Transkripts und springt beim Antippen
/// an die passende Stelle der Audiodatei.
class TranscriptTimestampsSection extends StatefulWidget {
  final List<TranscriptSegment> segments;
  final ValueChanged<Duration>? onSeek;
  final Duration position;

  /// Language the speech-to-text model reported, shown next to the count
  final String? detectedLanguage;

  const TranscriptTimestampsSection({
    super.key,
    required this.segments,
    this.onSeek,
    this.position = Duration.zero,
    this.detectedLanguage,
  });

  @override
  State<TranscriptTimestampsSection> createState() =>
      _TranscriptTimestampsSectionState();
}

class _TranscriptTimestampsSectionState
    extends State<TranscriptTimestampsSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.segments.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: const Icon(Icons.schedule),
            title: Text(context.l10n.timestamps),
            subtitle: Text(_subtitle(context)),
            trailing: Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
            ),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
          ),
          if (_isExpanded)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: AppSpacing.s),
                itemCount: widget.segments.length,
                itemBuilder: (context, index) {
                  final segment = widget.segments[index];
                  final isActive = widget.position >= segment.start &&
                      widget.position < segment.end;

                  return ListTile(
                    dense: true,
                    selected: isActive,
                    leading: Text(
                      DurationFormatter.position(segment.start),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    title: Text(
                      segment.speaker == null || segment.speaker!.isEmpty
                          ? segment.text
                          : '${segment.speaker}: ${segment.text}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: widget.onSeek == null
                        ? null
                        : Tooltip(
                            message: context.l10n.jumpToPosition,
                            child: const Icon(
                              Icons.play_arrow,
                              size: AppIconSize.small,
                            ),
                          ),
                    onTap: widget.onSeek == null
                        ? null
                        : () => widget.onSeek!(segment.start),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  String _subtitle(BuildContext context) {
    final count = '${widget.segments.length}';
    final language = widget.detectedLanguage;
    if (language == null || language.isEmpty) return count;

    return '$count · ${context.l10n.detectedLanguageLabel(language)}';
  }
}
