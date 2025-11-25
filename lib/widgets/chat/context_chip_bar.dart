import 'package:flutter/material.dart';
import '../../utils/constants.dart';

/// Widget for displaying and selecting chat contexts
/// Shows available contexts as filter chips
class ContextChipBar extends StatefulWidget {
  final List<String> availableContexts;
  final Set<String> enabledContexts;
  final void Function(String contextKey) onToggle;
  final String Function(String contextKey) getDisplayName;

  const ContextChipBar({
    super.key,
    required this.availableContexts,
    required this.enabledContexts,
    required this.onToggle,
    required this.getDisplayName,
  });

  @override
  State<ContextChipBar> createState() => _ContextChipBarState();
}

class _ContextChipBarState extends State<ContextChipBar>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppDuration.normal,
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.availableContexts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with toggle button
          InkWell(
            onTap: _toggleExpanded,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.m,
                vertical: AppSpacing.s,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.tune,
                    size: AppIconSize.medium,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Text(
                    'Kontext',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  // Show count of enabled contexts
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.circular),
                    ),
                    child: Text(
                      '${widget.enabledContexts.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: AppDuration.normal,
                    child: Icon(
                      Icons.expand_more,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Expandable chip list
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.m,
                right: AppSpacing.m,
                bottom: AppSpacing.m,
              ),
              child: Wrap(
                spacing: AppSpacing.s,
                runSpacing: AppSpacing.s,
                children: widget.availableContexts.map((contextKey) {
                  final isEnabled = widget.enabledContexts.contains(contextKey);
                  final displayName = widget.getDisplayName(contextKey);
                  final isTranscription = contextKey == 'transcription';

                  return FilterChip(
                    label: Text(displayName),
                    selected: isEnabled,
                    onSelected: isTranscription ? null : (_) => widget.onToggle(contextKey),
                    avatar: isEnabled
                        ? Icon(
                            isTranscription ? Icons.lock : Icons.check,
                            size: 16,
                          )
                        : null,
                    showCheckmark: false,
                    selectedColor: theme.colorScheme.primaryContainer,
                    backgroundColor: theme.colorScheme.surfaceContainerHigh,
                    labelStyle: TextStyle(
                      color: isEnabled
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurface,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
