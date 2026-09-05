import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../providers/prompts_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/transcription/i_speech_to_text_service.dart';
import '../../utils/constants.dart';
import 'setting_header.dart';

/// Bündelt die Einstellungen, die eine Transkription steuern:
/// Sprechertrennung, Transkriptionsstil, Schlüsselwörter sowie die
/// automatische Transkription und den Prompt danach.
class TranscriptionOptionsSection extends StatefulWidget {
  const TranscriptionOptionsSection({super.key});

  @override
  State<TranscriptionOptionsSection> createState() =>
      _TranscriptionOptionsSectionState();
}

class _TranscriptionOptionsSectionState
    extends State<TranscriptionOptionsSection> {
  final TextEditingController _keywordController = TextEditingController();

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[
      _buildSpeakerDiarizationToggle(context),
      _buildTranscribeStyleSelector(context),
      _buildKeywordsEditor(context),
      _buildAutoTranscribeToggle(context),
      _buildAutoPromptSelector(context),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final section in sections) ...[
          const SizedBox(height: AppSpacing.m),
          const Divider(),
          const SizedBox(height: AppSpacing.s),
          section,
        ],
      ],
    );
  }

  Widget _buildSpeakerDiarizationToggle(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: SettingHeader(
                icon: Icons.record_voice_over,
                title: context.l10n.speakerDiarization,
              ),
            ),
            Switch(
              value: settingsProvider.speakerDiarization,
              onChanged: settingsProvider.saveSpeakerDiarization,
            ),
          ],
        ),
        SettingDescription(context.l10n.speakerDiarizationDescription),
      ],
    );
  }

  Widget _buildTranscribeStyleSelector(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingHeader(icon: Icons.tune, title: context.l10n.transcribeStyle),
        const SizedBox(height: AppSpacing.s),
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.indent),
          child: SegmentedButton<TranscribeStyle>(
            segments: [
              ButtonSegment(
                value: TranscribeStyle.clean,
                label: Text(context.l10n.transcribeStyleClean),
              ),
              ButtonSegment(
                value: TranscribeStyle.verbatim,
                label: Text(context.l10n.transcribeStyleVerbatim),
              ),
            ],
            selected: {settingsProvider.transcribeStyle},
            onSelectionChanged: (selection) {
              settingsProvider.saveTranscribeStyle(selection.first);
            },
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        SettingDescription(context.l10n.transcribeStyleDescription),
      ],
    );
  }

  Widget _buildKeywordsEditor(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final keywords = settingsProvider.keywords;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingHeader(icon: Icons.sell_outlined, title: context.l10n.keywords),
        const SizedBox(height: AppSpacing.s),
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.indent),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _keywordController,
                decoration: InputDecoration(
                  hintText: context.l10n.keywordsHint,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _addKeyword(settingsProvider),
                  ),
                ),
                onSubmitted: (_) => _addKeyword(settingsProvider),
              ),
              const SizedBox(height: AppSpacing.s),
              if (keywords.isEmpty)
                Text(
                  context.l10n.keywordsEmpty,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: AppOpacity.secondary),
                      ),
                )
              else
                Wrap(
                  spacing: AppSpacing.s,
                  runSpacing: AppSpacing.xs,
                  children: keywords
                      .map(
                        (keyword) => InputChip(
                          label: Text(keyword),
                          onDeleted: () {
                            final remaining = List<String>.from(keywords)
                              ..remove(keyword);
                            settingsProvider.saveKeywords(remaining);
                          },
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        SettingDescription(context.l10n.keywordsDescription),
      ],
    );
  }

  Future<void> _addKeyword(SettingsProvider settingsProvider) async {
    final keyword = _keywordController.text.trim();
    if (keyword.isEmpty) return;

    final keywords = List<String>.from(settingsProvider.keywords);
    if (!keywords.contains(keyword)) {
      keywords.add(keyword);
      await settingsProvider.saveKeywords(keywords);
    }

    _keywordController.clear();
  }

  Widget _buildAutoTranscribeToggle(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: SettingHeader(
                icon: Icons.play_circle_outline,
                title: context.l10n.autoTranscribe,
              ),
            ),
            Switch(
              value: settingsProvider.autoTranscribe,
              onChanged: settingsProvider.saveAutoTranscribe,
            ),
          ],
        ),
        SettingDescription(context.l10n.autoTranscribeDescription),
      ],
    );
  }

  Widget _buildAutoPromptSelector(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final promptsProvider = context.watch<PromptsProvider>();
    final prompts = promptsProvider.getAllPrompts(context.l10n);
    final selectedId = prompts.any((p) => p.id == settingsProvider.autoPromptId)
        ? settingsProvider.autoPromptId
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingHeader(
          icon: Icons.auto_awesome,
          title: context.l10n.autoPrompt,
        ),
        const SizedBox(height: AppSpacing.s),
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.indent),
          child: DropdownButtonFormField<String?>(
            initialValue: selectedId,
            isExpanded: true,
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text(context.l10n.autoPromptDisabled),
              ),
              ...prompts.map(
                (prompt) => DropdownMenuItem<String?>(
                  value: prompt.id,
                  child: Text(prompt.name, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            onChanged: (value) => settingsProvider.saveAutoPromptId(value),
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        SettingDescription(context.l10n.autoPromptDescription),
      ],
    );
  }
}
