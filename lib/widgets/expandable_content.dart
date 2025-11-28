import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../l10n/l10n.dart';

const double kDefaultCollapsedHeight = 200.0;
const int kDefaultCharacterThreshold = 500;

/// A reusable widget for displaying collapsible content with fade effect
class ExpandableContent extends StatefulWidget {
  final Widget child;
  final Widget? collapsedChild;
  final String content;
  final double collapsedHeight;
  final int characterThreshold;
  final Color? fadeColor;
  final bool initiallyExpanded;
  final ValueChanged<bool>? onExpandedChanged;

  const ExpandableContent({
    super.key,
    required this.child,
    this.collapsedChild,
    required this.content,
    this.collapsedHeight = kDefaultCollapsedHeight,
    this.characterThreshold = kDefaultCharacterThreshold,
    this.fadeColor,
    this.initiallyExpanded = false,
    this.onExpandedChanged,
  });

  @override
  State<ExpandableContent> createState() => _ExpandableContentState();
}

class _ExpandableContentState extends State<ExpandableContent> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  bool get _shouldCollapse {
    return widget.content.length > widget.characterThreshold;
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    widget.onExpandedChanged?.call(_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldCollapse) {
      return widget.child;
    }

    final theme = Theme.of(context);
    final fadeColor = widget.fadeColor ?? theme.colorScheme.surface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedCrossFade(
          firstChild: _CollapsedContentBox(
            height: widget.collapsedHeight,
            fadeColor: fadeColor,
            child: widget.collapsedChild ?? widget.child,
          ),
          secondChild: widget.child,
          crossFadeState:
              _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
          sizeCurve: Curves.easeInOut,
        ),
        const SizedBox(height: AppSpacing.s),
        _ExpandButton(
          isExpanded: _isExpanded,
          onTap: _toggleExpanded,
        ),
      ],
    );
  }
}

class _CollapsedContentBox extends StatelessWidget {
  final double height;
  final Color fadeColor;
  final Widget child;

  const _CollapsedContentBox({
    required this.height,
    required this.fadeColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: child,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 60,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    fadeColor.withValues(alpha: 0),
                    fadeColor,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandButton extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onTap;

  const _ExpandButton({
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isExpanded ? context.l10n.showLess : context.l10n.showMore,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          AnimatedRotation(
            turns: isExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 300),
            child: Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
