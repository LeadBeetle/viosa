import 'package:flutter/material.dart';
import '../services/snackbar_service.dart';

/// Mixin providing UI helper methods for screens
mixin ScreenHelpers<T extends StatefulWidget> on State<T> {
  /// Show error message in snackbar
  void showErrorSnackBar(String message) {
    SnackBarService().showError(context, message);
  }

  /// Show success message in snackbar
  void showSuccessSnackBar(String message) {
    SnackBarService().showSuccess(context, message);
  }

  /// Safely call setState only if widget is still mounted
  void safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }
}
