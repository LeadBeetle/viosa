import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// A service for displaying improved snackbars with consistent styling
class SnackBarService {
  /// Shows an error snackbar
  static void showError(BuildContext context, String message) {
    _showSnackBar(
      context,
      message,
      backgroundColor: AppConstants.errorColor,
    );
  }

  /// Shows a success snackbar
  static void showSuccess(BuildContext context, String message) {
    _showSnackBar(
      context,
      message,
      backgroundColor: AppConstants.successColor,
    );
  }

  /// Shows a simple info snackbar (for clipboard notifications, etc.)
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _showSnackBar(
      context,
      message,
      duration: duration,
    );
  }

  /// Internal method to show a snackbar with consistent styling
  static void _showSnackBar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 5),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.fixed,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    );
  }
}
