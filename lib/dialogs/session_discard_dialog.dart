import 'package:flutter/material.dart';
import '../l10n/l10n.dart';

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
      title: Text(context.l10n.sessionDiscardTitle),
      content: Text(context.l10n.sessionDiscardMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
          child: Text(context.l10n.startNewSession),
        ),
      ],
    );
  }
}
