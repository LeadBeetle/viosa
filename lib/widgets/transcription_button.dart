import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';

/// Button for starting or canceling transcription
/// Displays loading indicator when transcribing
class TranscriptionButton extends StatefulWidget {
  final bool isTranscribing;
  final VoidCallback onPressed;
  final bool showSuccessAnimation;

  const TranscriptionButton({
    super.key,
    required this.isTranscribing,
    required this.onPressed,
    this.showSuccessAnimation = false,
  });

  @override
  State<TranscriptionButton> createState() => _TranscriptionButtonState();
}

class _TranscriptionButtonState extends State<TranscriptionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _showSuccessAnimation = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TranscriptionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTranscribing && !oldWidget.isTranscribing) {
      _animationController.repeat();
    } else if (!widget.isTranscribing && oldWidget.isTranscribing) {
      _animationController.stop();
      _animationController.reset();
    }

    // Handle success animation trigger
    if (widget.showSuccessAnimation && !oldWidget.showSuccessAnimation) {
      setState(() {
        _showSuccessAnimation = true;
      });
      HapticFeedback.heavyImpact();

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _showSuccessAnimation = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String buttonText;
    IconData iconData;

    if (_showSuccessAnimation) {
      buttonText = 'Erfolgreich!';
      iconData = Icons.check_circle;
    } else if (widget.isTranscribing) {
      buttonText = 'Wird transkribiert...';
      iconData = Icons.hourglass_empty;
    } else {
      buttonText = 'Transkribieren';
      iconData = Icons.transcribe;
    }

    Widget buttonIcon;
    if (_showSuccessAnimation) {
      buttonIcon = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 400),
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
            ),
          );
        },
      );
    } else if (widget.isTranscribing) {
      buttonIcon = RotationTransition(
        turns: _animationController,
        child: const Icon(Icons.hourglass_empty),
      );
    } else {
      buttonIcon = Icon(iconData);
    }

    return ElevatedButton.icon(
      onPressed: _showSuccessAnimation
          ? null
          : () {
              HapticFeedback.mediumImpact();
              widget.onPressed();
            },
      icon: buttonIcon,
      label: Text(buttonText),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(AppSpacing.m),
        backgroundColor: _showSuccessAnimation
            ? Colors.green.shade100
            : widget.isTranscribing
                ? Theme.of(context).colorScheme.error
                : null,
        foregroundColor: widget.isTranscribing && !_showSuccessAnimation
            ? Theme.of(context).colorScheme.onError
            : null,
      ),
    );
  }
}
