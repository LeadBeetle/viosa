import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/snackbar_service.dart';

/// A full-screen dialog for displaying markdown content
/// Similar to the PromptEditDialog but for viewing markdown
class MarkdownViewDialog extends StatelessWidget {
  final String title;
  final String content;
  final TextStyle? contentStyle;

  const MarkdownViewDialog({
    super.key,
    required this.title,
    required this.content,
    this.contentStyle,
  });

  /// Shows the dialog
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String content,
    TextStyle? contentStyle,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MarkdownViewDialog(
        title: title,
        content: content,
        contentStyle: contentStyle,
      ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: content));
    SnackBarService().showInfo(context, 'In Zwischenablage kopiert');
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
          ),
          child: Column(
            children: [
              // Handle bar for dragging
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () => _copyToClipboard(context),
                      tooltip: 'Kopieren',
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Schließen',
                    ),
                  ],
                ),
              ),

              const Divider(),

              // Content
              Expanded(
                child: Scrollbar(
                  controller: scrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16.0),
                    child: Builder(
                      builder: (context) {
                        final textStyle = contentStyle ??
                            TextStyle(
                              fontSize: 16,
                              height: 1.5,
                            );
                        return MarkdownBody(
                          data: content,
                          selectable: true,
                          styleSheet: MarkdownStyleSheet(
                            p: textStyle,
                            h1: textStyle.copyWith(
                              fontSize: (textStyle.fontSize ?? 16) * 1.5,
                              fontWeight: FontWeight.bold,
                            ),
                            h2: textStyle.copyWith(
                              fontSize: (textStyle.fontSize ?? 16) * 1.3,
                              fontWeight: FontWeight.bold,
                            ),
                            h3: textStyle.copyWith(
                              fontSize: (textStyle.fontSize ?? 16) * 1.1,
                              fontWeight: FontWeight.bold,
                            ),
                            code: textStyle.copyWith(
                              fontFamily: 'monospace',
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHigh,
                            ),
                            codeblockDecoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            listBullet: textStyle,
                            blockquote: textStyle.copyWith(
                              fontStyle: FontStyle.italic,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                            blockquoteDecoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color:
                                      Theme.of(context).colorScheme.primary,
                                  width: 4,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}