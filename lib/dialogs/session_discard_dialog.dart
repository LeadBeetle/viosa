import 'package:flutter/material.dart';

/// Dialog to confirm discarding the current session
class SessionDiscardDialog extends StatelessWidget {
  const SessionDiscardDialog({super.key});

  /// Shows the dialog and returns true if user confirms
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => const SessionDiscardDialog(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Aktuelle Session verwerfen?'),
      content: const Text(
        'Sie haben bereits eine Audiodatei ausgewählt oder transkribiert. '
        'Möchten Sie diese Session verwerfen und eine neue starten?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
          child: const Text('Neue Session starten'),
        ),
      ],
    );
  }
}
