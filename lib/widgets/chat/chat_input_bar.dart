import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../utils/constants.dart';
import 'mention_text_field.dart';
import 'voice_input_button.dart';

/// Chat input bar with text field, voice input, and send button
class ChatInputBar extends StatefulWidget {
  final void Function(String message) onSend;
  final VoidCallback? onStop;
  final List<String> availableMentions;
  final String Function(String contextKey) getDisplayName;
  final bool enabled;
  final bool isStreaming;

  const ChatInputBar({
    super.key,
    required this.onSend,
    this.onStop,
    required this.availableMentions,
    required this.getDisplayName,
    this.enabled = true,
    this.isStreaming = false,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty || !widget.enabled || widget.isStreaming) return;

    widget.onSend(text);
    _controller.clear();
    _focusNode.requestFocus();
  }

  void _handleVoiceResult(String text) {
    _controller.text = text;
    _controller.selection = TextSelection.collapsed(offset: text.length);
  }

  void _handlePartialResult(String text) {
    _controller.text = text;
    _controller.selection = TextSelection.collapsed(offset: text.length);
  }

  void _handleListeningChanged(bool isListening) {
    setState(() {
      _isListening = isListening;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canSend = _controller.text.trim().isNotEmpty &&
        widget.enabled &&
        !widget.isStreaming &&
        !_isListening;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Voice input button
              VoiceInputButton(
                onResult: _handleVoiceResult,
                onPartialResult: _handlePartialResult,
                onListeningChanged: _handleListeningChanged,
                enabled: widget.enabled && !widget.isStreaming,
              ),
              const SizedBox(width: AppSpacing.s),
              // Text input field
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: MentionTextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          availableMentions: widget.availableMentions,
                          getDisplayName: widget.getDisplayName,
                          onSubmit: _handleSend,
                          hintText: _isListening
                              ? context.l10n.speakNow
                              : context.l10n.enterMessage,
                          enabled: widget.enabled && !widget.isStreaming,
                        ),
                      ),
                      // Send button, or stop button while a response streams
                      Padding(
                        padding: const EdgeInsets.only(
                          right: AppSpacing.xs,
                          bottom: AppSpacing.xs,
                        ),
                        child: widget.isStreaming && widget.onStop != null
                            ? IconButton(
                                onPressed: widget.onStop,
                                icon: Icon(
                                  Icons.stop_circle_outlined,
                                  color: theme.colorScheme.error,
                                ),
                                tooltip: context.l10n.stopGeneration,
                                visualDensity: VisualDensity.compact,
                              )
                            : AnimatedOpacity(
                                opacity: canSend ? 1.0 : 0.5,
                                duration: AppDuration.fast,
                                child: IconButton(
                                  onPressed: canSend ? _handleSend : null,
                                  icon: Icon(
                                    Icons.send_rounded,
                                    color: canSend
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
