import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Speed Dial Floating Action Button
/// Provides a FAB that expands to show multiple action options
class SpeedDialFAB extends StatefulWidget {
  final VoidCallback onRecordTap;
  final VoidCallback onFileTap;

  const SpeedDialFAB({
    super.key,
    required this.onRecordTap,
    required this.onFileTap,
  });

  @override
  State<SpeedDialFAB> createState() => _SpeedDialFABState();
}

class _SpeedDialFABState extends State<SpeedDialFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.125, // 45 degrees (1/8 turn)
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _close() {
    if (_isOpen) {
      setState(() {
        _isOpen = false;
        _controller.reverse();
      });
    }
  }

  void _handleRecordTap() {
    _close();
    widget.onRecordTap();
  }

  void _handleFileTap() {
    _close();
    widget.onFileTap();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Record button
        ScaleTransition(
          scale: _scaleAnimation,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Label
                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Neue Aufnahme',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Button
                FloatingActionButton(
                  heroTag: 'record',
                  mini: true,
                  onPressed: _handleRecordTap,
                  tooltip: 'Neue Aufnahme',
                  child: const Icon(Icons.mic),
                ),
              ],
            ),
          ),
        ),
        // File picker button
        ScaleTransition(
          scale: _scaleAnimation,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Label
                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Datei öffnen',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Button
                FloatingActionButton(
                  heroTag: 'file',
                  mini: true,
                  onPressed: _handleFileTap,
                  tooltip: 'Datei öffnen',
                  child: const Icon(Icons.folder_open),
                ),
              ],
            ),
          ),
        ),
        // Main FAB
        FloatingActionButton(
          heroTag: 'main',
          onPressed: _toggle,
          tooltip: 'Neue Aufnahme oder Datei öffnen',
          child: AnimatedBuilder(
            animation: _rotationAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationAnimation.value * 2 * math.pi,
                child: Icon(_isOpen ? Icons.close : Icons.add),
              );
            },
          ),
        ),
      ],
    );
  }
}
