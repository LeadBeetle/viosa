import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../mixins/copyable_content_mixin.dart';
import '../utils/markdown_styles.dart';
import '../utils/constants.dart';
import '../l10n/l10n.dart';
import 'expandable_content.dart';

/// A collapsible text section widget with expand/collapse functionality
/// Optimized for displaying long text content with better UX
class CollapsibleTextSection extends StatefulWidget {
  final String title;
  final String content;
  final bool isExpanded;
  final TextStyle? contentStyle;
  final bool showCopyButton;
  final Widget? metadata;
  final Widget? actionButton;
  final VoidCallback? onExpandChanged;
  final double maxExpandedHeight;
  final double collapsedHeight;
  final int characterThreshold;
  final List<Widget>? headerActions;

  const CollapsibleTextSection({
    super.key,
    required this.title,
    required this.content,
    this.isExpanded = false,
    this.contentStyle,
    this.showCopyButton = true,
    this.metadata,
    this.actionButton,
    this.onExpandChanged,
    this.maxExpandedHeight = 600,
    this.collapsedHeight = kDefaultCollapsedHeight,
    this.characterThreshold = kDefaultCharacterThreshold,
    this.headerActions,
  });

  @override
  State<CollapsibleTextSection> createState() => _CollapsibleTextSectionState();
}

class _CollapsibleTextSectionState extends State<CollapsibleTextSection>
    with CopyableContentMixin {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildExpandedContent(TextStyle textStyle) {
    return Container(
      constraints: BoxConstraints(maxHeight: widget.maxExpandedHeight),
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: MarkdownBody(
              data: widget.content,
              selectable: true,
              styleSheet: MarkdownStyles.custom(textStyle),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedContent(TextStyle textStyle) {
    return MarkdownBody(
      data: widget.content,
      selectable: false,
      styleSheet: MarkdownStyles.custom(textStyle),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = widget.contentStyle ??
        const TextStyle(
          fontSize: 16,
          height: 1.5,
        );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (widget.headerActions != null) ...widget.headerActions!,
                if (widget.showCopyButton)
                  IconButton(
                    icon: const Icon(Icons.copy, size: AppIconSize.medium),
                    onPressed: () => copyToClipboard(widget.content),
                    tooltip: context.l10n.copy,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ExpandableContent(
              content: widget.content,
              collapsedHeight: widget.collapsedHeight,
              characterThreshold: widget.characterThreshold,
              fadeColor: theme.cardColor,
              initiallyExpanded: widget.isExpanded,
              onExpandedChanged: (_) => widget.onExpandChanged?.call(),
              collapsedChild: _buildCollapsedContent(textStyle),
              child: _buildExpandedContent(textStyle),
            ),
            if (widget.metadata != null || widget.actionButton != null) ...[
              const Divider(height: AppSpacing.l),
              Row(
                children: [
                  if (widget.metadata != null)
                    Expanded(child: widget.metadata!),
                  if (widget.actionButton != null) ...[
                    const SizedBox(width: AppSpacing.s),
                    widget.actionButton!,
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
