import 'package:flutter/material.dart';

import '../models/transcript_segment.dart';
import '../utils/constants.dart';
import '../l10n/l10n.dart';

/// Zeigt die Zeitmarken eines Transkripts und springt beim Antippen
/// an die passende Stelle der Audiodatei.
class TranscriptTimestampsSection extends StatefulWidget {
  final List<TranscriptSegment> segments;
  final ValueChanged<Duration>? onSeek;
  final Duration position;

  const TranscriptTimestampsSection({
    super.key,
    required this.segments,
    this.onSeek,
    this.position = Duration.zero,
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
            subtitle: Text('${widget.segments.length}'),
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
                      _formatPosition(segment.start),
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

  String _formatPosition(Duration position) {
    final hours = position.inHours;
    final minutes = position.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = position.inSeconds.remainder(60).toString().padLeft(2, '0');

    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}
