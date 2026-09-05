import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../../models/chat_message.dart';
import '../../l10n/l10n.dart';
import '../../utils/constants.dart';
import '../../services/snackbar_service.dart';
import '../expandable_content.dart';

/// Widget for displaying a single chat message
class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isStreaming;
  final String? streamingContent;
  final VoidCallback? onRegenerate;

  const ChatMessageBubble({
    super.key,
    required this.message,
    this.isStreaming = false,
    this.streamingContent,
    this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;
    final content = isStreaming ? (streamingContent ?? '') : message.content;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                Icons.smart_toy_outlined,
                size: 18,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: AppSpacing.s),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(AppRadius.large),
                      topRight: const Radius.circular(AppRadius.large),
                      bottomLeft: Radius.circular(isUser ? AppRadius.large : 4),
                      bottomRight: Radius.circular(isUser ? 4 : AppRadius.large),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MessageContent(
                        content: content,
                        isUser: isUser,
                        isStreaming: isStreaming,
                        bubbleColor: theme.colorScheme.surfaceContainerHigh,
                      ),
                      if (isStreaming) ...[
                        const SizedBox(height: AppSpacing.xs),
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                      if (message.referencedContexts?.isNotEmpty == true) ...[
                        const SizedBox(height: AppSpacing.s),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: message.referencedContexts!.map((ctx) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondaryContainer
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '@$ctx',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSecondaryContainer,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!isStreaming) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ActionButton(
                        icon: Icons.copy_outlined,
                        tooltip: context.l10n.copy,
                        onPressed: () => _copyToClipboard(context, content),
                      ),
                      if (!isUser && onRegenerate != null) ...[
                        const SizedBox(width: 2),
                        _ActionButton(
                          icon: Icons.refresh,
                          tooltip: context.l10n.regenerate,
                          onPressed: onRegenerate!,
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: AppSpacing.s),
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primary,
              child: Icon(
                Icons.person,
                size: 18,
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String content) {
    Clipboard.setData(ClipboardData(text: content));
    SnackBarService().showSuccess(context, context.l10n.copiedToClipboard);
  }
}

class _MessageContent extends StatelessWidget {
  final String content;
  final bool isUser;
  final bool isStreaming;
  final Color bubbleColor;

  const _MessageContent({
    required this.content,
    required this.isUser,
    required this.isStreaming,
    required this.bubbleColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isUser) {
      return Text(
        content,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      );
    }

    final markdownWidget = MarkdownBody(
      data: content,
      selectable: true,
      styleSheet: _buildMarkdownStyleSheet(theme),
    );

    final collapsedMarkdownWidget = MarkdownBody(
      data: content,
      selectable: false,
      styleSheet: _buildMarkdownStyleSheet(theme),
    );

    if (isStreaming) {
      return markdownWidget;
    }

    return ExpandableContent(
      content: content,
      fadeColor: bubbleColor,
      collapsedChild: collapsedMarkdownWidget,
      child: markdownWidget,
    );
  }

  MarkdownStyleSheet _buildMarkdownStyleSheet(ThemeData theme) {
    return MarkdownStyleSheet(
      p: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
      code: theme.textTheme.bodySmall?.copyWith(
        fontFamily: 'monospace',
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
      ),
      codeblockDecoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.small),
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              icon,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
