import 'package:flutter/material.dart';
import '../../utils/constants.dart';

/// Text field with @ mention autocomplete support
class MentionTextField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final List<String> availableMentions;
  final String Function(String contextKey) getDisplayName;
  final VoidCallback? onSubmit;
  final String? hintText;
  final bool enabled;

  const MentionTextField({
    super.key,
    required this.controller,
    this.focusNode,
    required this.availableMentions,
    required this.getDisplayName,
    this.onSubmit,
    this.hintText,
    this.enabled = true,
  });

  @override
  State<MentionTextField> createState() => _MentionTextFieldState();
}

class _MentionTextFieldState extends State<MentionTextField> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  List<String> _filteredMentions = [];
  int _mentionStartIndex = -1;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _removeOverlay();
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    final selection = widget.controller.selection;

    if (!selection.isValid || selection.baseOffset != selection.extentOffset) {
      _hideOverlay();
      return;
    }

    final cursorPosition = selection.baseOffset;

    // Find @ symbol before cursor
    int atIndex = -1;
    for (int i = cursorPosition - 1; i >= 0; i--) {
      if (text[i] == '@') {
        atIndex = i;
        break;
      } else if (text[i] == ' ' || text[i] == '\n') {
        break;
      }
    }

    if (atIndex >= 0) {
      final query = text.substring(atIndex + 1, cursorPosition).toLowerCase();
      _mentionStartIndex = atIndex;

      // Filter available mentions
      _filteredMentions = widget.availableMentions.where((mention) {
        final displayName = widget.getDisplayName(mention).toLowerCase();
        return displayName.contains(query) || mention.toLowerCase().contains(query);
      }).toList();

      if (_filteredMentions.isNotEmpty) {
        _showOverlay();
      } else {
        _hideOverlay();
      }
    } else {
      _hideOverlay();
    }
  }

  void _showOverlay() {
    if (_showSuggestions) {
      _overlayEntry?.markNeedsBuild();
      return;
    }

    _showSuggestions = true;
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    if (!_showSuggestions) return;
    _showSuggestions = false;
    _removeOverlay();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => Positioned(
        width: 200,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, -8),
          followerAnchor: Alignment.bottomLeft,
          targetAnchor: Alignment.topLeft,
          child: Material(
            elevation: AppElevation.modal,
            borderRadius: BorderRadius.circular(AppRadius.small),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.small),
                color: Theme.of(context).colorScheme.surface,
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                itemCount: _filteredMentions.length,
                itemBuilder: (context, index) {
                  final mention = _filteredMentions[index];
                  final displayName = widget.getDisplayName(mention);

                  return ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    leading: Icon(
                      mention == 'transcription'
                          ? Icons.description_outlined
                          : Icons.auto_awesome,
                      size: AppIconSize.small,
                    ),
                    title: Text(displayName),
                    onTap: () => _insertMention(mention),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _insertMention(String mention) {
    final text = widget.controller.text;
    final displayName = widget.getDisplayName(mention);

    // Replace @query with @DisplayName
    final newText = '${text.substring(0, _mentionStartIndex)}@$displayName ${text.substring(widget.controller.selection.baseOffset)}';

    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: _mentionStartIndex + displayName.length + 2,
      ),
    );

    _hideOverlay();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        enabled: widget.enabled,
        maxLines: null,
        minLines: 1,
        textInputAction: TextInputAction.send,
        onSubmitted: widget.enabled ? (_) => widget.onSubmit?.call() : null,
        decoration: InputDecoration(
          hintText: widget.hintText ?? 'Nachricht eingeben...',
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.m,
            vertical: AppSpacing.s,
          ),
        ),
        style: theme.textTheme.bodyMedium,
      ),
    );
  }
}
