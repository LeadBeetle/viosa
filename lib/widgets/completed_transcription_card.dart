import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/transcription_result.dart';
import '../models/speaker.dart';
import '../providers/settings_provider.dart';
import 'collapsible_text_section.dart';
import 'info_chip.dart';
import '../utils/constants.dart';

/// Card widget for displaying completed transcription with apply prompt button
class CompletedTranscriptionCard extends StatefulWidget {
  final TranscriptionResult transcriptionResult;
  final bool isPromptActive;
  final VoidCallback onApplyPrompt;
  final int promptResultCount;
  final VoidCallback? onRetranscribe;

  const CompletedTranscriptionCard({
    super.key,
    required this.transcriptionResult,
    required this.isPromptActive,
    required this.onApplyPrompt,
    this.promptResultCount = 0,
    this.onRetranscribe,
  });

  @override
  State<CompletedTranscriptionCard> createState() => _CompletedTranscriptionCardState();
}

class _CompletedTranscriptionCardState extends State<CompletedTranscriptionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _showSuccessAnimation = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CompletedTranscriptionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPromptActive && !oldWidget.isPromptActive) {
      _animationController.repeat();
    } else if (!widget.isPromptActive && oldWidget.isPromptActive) {
      _animationController.stop();
      _animationController.reset();

      setState(() {
        _showSuccessAnimation = true;
      });
      HapticFeedback.heavyImpact();

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _showSuccessAnimation = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Consumer<SettingsProvider>(
          builder: (context, settings, _) => CollapsibleTextSection(
            title: 'Transkription',
            content: widget.transcriptionResult.text,
            isExpanded: false,
            contentStyle: TextStyle(
              fontSize: settings.textSize,
              height: 1.5,
            ),
            headerActions: widget.onRetranscribe != null
                ? [
                    IconButton(
                      icon: const Icon(Icons.refresh, size: AppIconSize.medium),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        widget.onRetranscribe!();
                      },
                      tooltip: 'Erneut transkribieren',
                    ),
                  ]
                : null,
            metadata: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.transcriptionResult.speakers.isNotEmpty) ...[
                  _buildSpeakersRow(context),
                  const SizedBox(height: AppSpacing.s),
                ],
                Wrap(
                  spacing: AppSpacing.s,
                  runSpacing: AppSpacing.s,
                  children: [
                    InfoChip(
                      label: 'Sprache: ${widget.transcriptionResult.language}',
                      icon: Icons.language,
                    ),
                    InfoChip(
                      label: 'Modell: ${widget.transcriptionResult.modelUsed}',
                      icon: Icons.memory,
                    ),
                    InfoChip(
                      label: '${widget.transcriptionResult.wordCount} Wörter',
                      icon: Icons.text_fields,
                    ),
                    InfoChip(
                      label: '${widget.transcriptionResult.characterCount} Zeichen',
                      icon: Icons.abc,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        _buildPromptButton(),
        if (widget.promptResultCount == 0 && !widget.isPromptActive && !_showSuccessAnimation) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Verarbeite die Transkription mit einem KI-Prompt',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppConstants.defaultPadding),
      ],
    );
  }

  Widget _buildSpeakersRow(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Icon(
            Icons.people,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'Sprecher: ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: widget.transcriptionResult.speakers
                .map((speaker) => _buildSpeakerChip(context, speaker))
                .toList(),
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

  Widget _buildPromptButton() {
    final bool hasResults = widget.promptResultCount > 0;

    String buttonText;
    IconData iconData;

    if (_showSuccessAnimation) {
      buttonText = 'Erfolgreich!';
      iconData = Icons.check_circle;
    } else if (widget.isPromptActive) {
      buttonText = 'Wird generiert...';
      iconData = Icons.hourglass_empty;
    } else if (hasResults) {
      buttonText = 'Weiteres Prompt anwenden';
      iconData = Icons.add_circle;
    } else {
      buttonText = 'Prompt anwenden';
      iconData = Icons.auto_awesome;
    }

    Widget buttonIcon;
    if (_showSuccessAnimation) {
      buttonIcon = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 400),
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
            ),
          );
        },
      );
    } else if (widget.isPromptActive) {
      buttonIcon = RotationTransition(
        turns: _animationController,
        child: const Icon(Icons.hourglass_empty),
      );
    } else {
      buttonIcon = Icon(iconData);
    }

    return ElevatedButton.icon(
      onPressed: widget.isPromptActive || _showSuccessAnimation
          ? null
          : () {
              HapticFeedback.mediumImpact();
              widget.onApplyPrompt();
            },
      icon: buttonIcon,
      label: Text(buttonText),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(16),
        backgroundColor: _showSuccessAnimation ? Colors.green.shade100 : null,
      ),
    );
  }

}
