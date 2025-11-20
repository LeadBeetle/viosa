import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/snackbar_service.dart';

/// Mixin for widgets that need copy-to-clipboard functionality
/// Eliminates code duplication across multiple card widgets
mixin CopyableContentMixin<T extends StatefulWidget> on State<T> {
  /// Copies text to clipboard and shows a confirmation snackbar
  Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      SnackBarService().showInfo(context, 'In Zwischenablage kopiert');
    }
  }
}
