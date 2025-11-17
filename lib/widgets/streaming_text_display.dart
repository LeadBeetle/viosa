import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'markdown_view_dialog.dart';
import '../services/snackbar_service.dart';

/// A widget that displays streaming text content with auto-scroll
/// and user control features
class StreamingTextDisplay extends StatefulWidget {
  final String title;
  final Stream<String>? textStream;
  final String? initialText;
  final TextStyle? contentStyle;
  final bool showCopyButton;
  final Widget? metadata;
  final VoidCallback? onStreamComplete;
  final Function(String)? onStreamError;
  final Function(String)? onChunk;

  const StreamingTextDisplay({
    super.key,
    required this.title,
    this.textStream,
    this.initialText,
    this.contentStyle,
    this.showCopyButton = true,
    this.metadata,
    this.onStreamComplete,
    this.onStreamError,
    this.onChunk,
  });

  @override
  State<StreamingTextDisplay> createState() => _StreamingTextDisplayState();
}

class _StreamingTextDisplayState extends State<StreamingTextDisplay> {
  final ScrollController _scrollController = ScrollController();
  final StringBuffer _contentBuffer = StringBuffer();
  bool _isStreaming = false;
  bool _autoScroll = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialText != null) {
      _contentBuffer.write(widget.initialText);
    }
    if (widget.textStream != null) {
      _startStreaming();
    }

    // Listen to scroll events to detect user scroll
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    // Check if user scrolled up (disable auto-scroll)
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = maxScroll - 100; // 100px threshold

    if (currentScroll < threshold && _autoScroll) {
      setState(() {
        _autoScroll = false;
      });
    }
  }

  void _startStreaming() {
    setState(() {
      _isStreaming = true;
      _hasError = false;
    });

    widget.textStream!.listen(
      (chunk) {
        setState(() {
          _contentBuffer.write(chunk);
        });

        // Call onChunk callback if provided
        widget.onChunk?.call(chunk);

        // Auto-scroll to bottom if enabled
        if (_autoScroll && _scrollController.hasClients) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeOut,
              );
            }
          });
        }
      },
      onError: (error) {
        setState(() {
          _isStreaming = false;
          _hasError = true;
          _errorMessage = error.toString();
        });
        widget.onStreamError?.call(error.toString());
      },
      onDone: () {
        setState(() {
          _isStreaming = false;
        });
        widget.onStreamComplete?.call();
      },
    );
  }

  void _scrollToBottom() {
    setState(() {
      _autoScroll = true;
    });
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _contentBuffer.toString()));
    SnackBarService.showInfo(context, 'In Zwischenablage kopiert');
  }

  void _showFullScreen() {
    MarkdownViewDialog.show(
      context: context,
      title: widget.title,
      content: _contentBuffer.toString(),
      contentStyle: widget.contentStyle,
    );
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
                  child: Row(
                    children: [
                      Text(
                        widget.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (_isStreaming) ...[
                        const SizedBox(width: 8),
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_contentBuffer.isNotEmpty) ...[
                  if (widget.showCopyButton)
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: _copyToClipboard,
                      tooltip: 'Kopieren',
                    ),
                  IconButton(
                    icon: const Icon(Icons.open_in_full, size: 20),
                    onPressed: _showFullScreen,
                    tooltip: 'Vollständig anzeigen',
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),

            // Content
            if (_hasError)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              )
            else
              Stack(
                children: [
                  Container(
                    constraints: const BoxConstraints(maxHeight: 600),
                    child: Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Builder(
                            builder: (context) {
                              // Get text size from settings if contentStyle is not provided
                              final textStyle = widget.contentStyle ??
                                  TextStyle(
                                    fontSize: 16,
                                    height: 1.5,
                                  );
                              return MarkdownBody(
                                data: _contentBuffer.toString(),
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
                                  listBullet: textStyle,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  // "Jump to Latest" button
                  if (!_autoScroll && _contentBuffer.isNotEmpty)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: FloatingActionButton.small(
                        onPressed: _scrollToBottom,
                        tooltip: 'Zum Ende springen',
                        child: const Icon(Icons.arrow_downward, size: 20),
                      ),
                    ),
                ],
              ),

            // Metadata (if provided) - now at the end
            if (widget.metadata != null) ...[
              const SizedBox(height: 12),
              widget.metadata!,
            ],
          ],
        ),
      ),
    );
  }
}
