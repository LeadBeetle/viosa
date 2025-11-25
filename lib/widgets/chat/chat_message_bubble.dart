import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../models/chat_message.dart';
import '../../utils/constants.dart';
import '../../services/snackbar_service.dart';

/// Widget for displaying a single chat message
class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isStreaming;
  final String? streamingContent;

  const ChatMessageBubble({
    super.key,
    required this.message,
    this.isStreaming = false,
    this.streamingContent,
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
            child: GestureDetector(
              onLongPress: () => _copyToClipboard(context, content),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: BoxDecoration(
                  color: isUser
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHigh,
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
                    if (isUser)
                      Text(
                        content,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      )
                    else
                      MarkdownBody(
                        data: content,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet(
                          p: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                          code: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                          ),
                          codeblockDecoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(AppRadius.small),
                          ),
                        ),
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
    SnackBarService().showSuccess(context, 'In Zwischenablage kopiert');
  }
}
