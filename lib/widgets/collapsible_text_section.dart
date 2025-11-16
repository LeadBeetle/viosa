import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// A collapsible text section widget with expand/collapse functionality
/// Optimized for displaying long text content with better UX
class CollapsibleTextSection extends StatefulWidget {
  final String title;
  final String content;
  final bool isExpanded;
  final int previewLines;
  final TextStyle? contentStyle;
  final bool showCopyButton;
  final bool enableMarkdown;
  final Widget? metadata;
  final Widget? actionButton;
  final VoidCallback? onExpandChanged;

  const CollapsibleTextSection({
    super.key,
    required this.title,
    required this.content,
    this.isExpanded = false,
    this.previewLines = 3,
    this.contentStyle,
    this.showCopyButton = true,
    this.enableMarkdown = false,
    this.metadata,
    this.actionButton,
    this.onExpandChanged,
  });

  @override
  State<CollapsibleTextSection> createState() => _CollapsibleTextSectionState();
}

class _CollapsibleTextSectionState extends State<CollapsibleTextSection>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _iconRotation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _iconRotation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (_isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
    widget.onExpandChanged?.call();
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('In Zwischenablage kopiert'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildContent() {
    final textStyle = widget.contentStyle ??
        const TextStyle(
          fontSize: 16,
          height: 1.5,
        );

    if (_isExpanded) {
      return Container(
        constraints: const BoxConstraints(maxHeight: 400),
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
                  ),
                  listBullet: textStyle,
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      // Show preview
      final lines = widget.content.split('\n');
      final previewText = lines.take(widget.previewLines).join('\n');
      final hasMore = lines.length > widget.previewLines;

      return SelectableText(
        hasMore ? '$previewText...' : previewText,
        style: textStyle,
        maxLines: widget.previewLines,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                if (widget.showCopyButton)
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: _copyToClipboard,
                    tooltip: 'Kopieren',
                  ),
                IconButton(
                  icon: RotationTransition(
                    turns: _iconRotation,
                    child: const Icon(Icons.expand_more),
                  ),
                  onPressed: _toggleExpand,
                  tooltip: _isExpanded ? 'Einklappen' : 'Ausklappen',
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Content
            _buildContent(),

            // Expand/Collapse button
            if (widget.content.split('\n').length > widget.previewLines) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: _toggleExpand,
                  icon: RotationTransition(
                    turns: _iconRotation,
                    child: const Icon(Icons.expand_more),
                  ),
                  label: Text(_isExpanded ? 'Weniger anzeigen' : 'Mehr anzeigen'),
                ),
              ),
            ],

            // Metadata and action button row at the end
            if (widget.metadata != null || widget.actionButton != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (widget.metadata != null)
                    Expanded(child: widget.metadata!),
                  if (widget.actionButton != null)
                    widget.actionButton!,
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
