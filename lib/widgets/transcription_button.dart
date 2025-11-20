import 'package:flutter/material.dart';

/// Button for starting or canceling transcription
/// Displays loading indicator when transcribing
class TranscriptionButton extends StatelessWidget {
  final bool isTranscribing;
  final VoidCallback onPressed;

  const TranscriptionButton({
    super.key,
    required this.isTranscribing,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: isTranscribing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.transcribe),
      label: Text(isTranscribing ? 'Abbrechen' : 'Transkribieren'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(16),
        backgroundColor: isTranscribing ? Colors.red : null,
        foregroundColor: isTranscribing ? Colors.white : null,
      ),
    );
  }
}
