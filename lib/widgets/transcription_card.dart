import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../models/transcription_result.dart';
import '../models/speaker.dart';
import '../utils/constants.dart';
import '../utils/markdown_styles.dart';
import '../services/snackbar_service.dart';

/// Widget displaying transcription results
/// Follows Single Responsibility Principle: Only displays transcription data
class TranscriptionCard extends StatelessWidget {
  final TranscriptionResult result;
  final VoidCallback? onApplyPrompt;

  const TranscriptionCard({
    super.key,
    required this.result,
    this.onApplyPrompt,
  });

  Future<void> _copyToClipboard(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      SnackBarService().showInfo(context, 'In Zwischenablage kopiert');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppConstants.cardElevation,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.tertiary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Transkriptions-Ergebnis',
                    style: Theme.of(context).textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () => _copyToClipboard(context, result.text),
                  tooltip: 'In Zwischenablage kopieren',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MarkdownBody(
                    data: result.text,
                    selectable: true,
                    styleSheet: MarkdownStyles.standard(context),
                  ),
                  const SizedBox(height: 16),
                  Divider(color: Theme.of(context).colorScheme.outlineVariant),
                  const SizedBox(height: 8),
                  if (result.speakers.isNotEmpty) ...[
                    _buildSpeakersRow(context, result.speakers),
                    const SizedBox(height: 8),
                  ],
                  _buildMetadataRow(
                    context,
                    Icons.language,
                    'Sprache',
                    result.languageName,
                  ),
                  const SizedBox(height: 8),
                  _buildMetadataRow(
                    context,
                    Icons.model_training,
                    'Modell',
                    result.modelUsed,
                  ),
                  const SizedBox(height: 8),
                  _buildMetadataRow(
                    context,
                    Icons.access_time,
                    'Zeit',
                    result.formattedTimestamp,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (onApplyPrompt != null)
              FilledButton.icon(
                onPressed: onApplyPrompt,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Prompt'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeakersRow(BuildContext context, List<Speaker> speakers) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.people,
          size: 16,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 8),
        Text(
          'Sprecher: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
        ),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: speakers.map((speaker) => _buildSpeakerChip(context, speaker)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeakerChip(BuildContext context, Speaker speaker) {
    final color = speaker.color != null
        ? Color(int.parse(speaker.color!.replaceFirst('#', '0xFF')))
        : Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        speaker.label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }

  Widget _buildMetadataRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
