import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../mixins/copyable_content_mixin.dart';
import '../utils/markdown_styles.dart';
import '../utils/constants.dart';
import '../l10n/l10n.dart';

/// A collapsible text section widget with expand/collapse functionality
/// Optimized for displaying long text content with better UX
class CollapsibleTextSection extends StatefulWidget {
  final String title;
  final String content;
  final bool isExpanded;
  final int previewLines;
  final TextStyle? contentStyle;
  final bool showCopyButton;
  final Widget? metadata;
  final Widget? actionButton;
  final VoidCallback? onExpandChanged;
  final double maxExpandedHeight;
  final List<Widget>? headerActions;

  const CollapsibleTextSection({
    super.key,
    required this.title,
    required this.content,
    this.isExpanded = false,
    this.previewLines = 7,
    this.contentStyle,
    this.showCopyButton = true,
    this.metadata,
    this.actionButton,
    this.onExpandChanged,
    this.maxExpandedHeight = 600,
    this.headerActions,
  });

  @override
  State<CollapsibleTextSection> createState() => _CollapsibleTextSectionState();
}

class _CollapsibleTextSectionState extends State<CollapsibleTextSection>
    with CopyableContentMixin {
  late bool _isExpanded;
  final ScrollController _scrollController = ScrollController();

  String? _cachedContent;
  List<String>? _cachedLines;

  List<String> get _lines {
    if (_cachedContent != widget.content) {
      _cachedContent = widget.content;
      _cachedLines = widget.content.split('\n');
    }
    return _cachedLines!;
  }

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    widget.onExpandChanged?.call();
  }


  Widget _buildContent() {
    final textStyle = widget.contentStyle ??
        const TextStyle(
          fontSize: 16,
          height: 1.5,
        );

    if (_isExpanded) {
      // Show full content with scrolling
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
    } else {
      // Show preview (first N lines or limited by character count)
      // If text has few newlines (long continuous text), limit by character count
      String previewText;
      bool hasMore;

      if (_lines.length <= 3 && widget.content.length > 500) {
        // Long continuous text without many line breaks
        const maxPreviewChars = 500;
        previewText = widget.content.substring(0, maxPreviewChars.clamp(0, widget.content.length));
        hasMore = widget.content.length > maxPreviewChars;
      } else {
        // Normal text with line breaks
        previewText = _lines.take(widget.previewLines).join('\n');
        hasMore = _lines.length > widget.previewLines;
      }

      return MarkdownBody(
        data: hasMore ? '$previewText...' : previewText,
        selectable: true,
        styleSheet: MarkdownStyles.custom(textStyle),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasMoreLines = _lines.length > widget.previewLines;

    // Also check if content is long enough to warrant expansion
    // (handles cases where text is one long line that wraps)
    final isLongContent = widget.content.length > 500;
    final shouldShowExpandButton = hasMoreLines || isLongContent;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                // Collapse button (only visible when expanded)
                if (_isExpanded)
                  IconButton(
                    icon: const Icon(Icons.expand_less),
                    onPressed: _toggleExpand,
                    tooltip: context.l10n.collapse,
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Content
            _buildContent(),

            // "Show more" button (only if collapsed and has more content)
            if (!_isExpanded && shouldShowExpandButton) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: _toggleExpand,
                  icon: const Icon(Icons.expand_more),
                  label: Text(context.l10n.showMore),
                ),
              ),
            ],

            // "Show less" button (only if expanded and has more content)
            if (_isExpanded && shouldShowExpandButton) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: _toggleExpand,
                  icon: const Icon(Icons.expand_less),
                  label: Text(context.l10n.showLess),
                ),
              ),
            ],

            // Metadata and action button row at the end
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
