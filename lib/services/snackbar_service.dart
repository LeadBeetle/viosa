import 'package:flutter/material.dart';
import 'i_snackbar_service.dart';
import '../utils/app_theme.dart';

/// A service for displaying improved snackbars with consistent styling
class SnackBarService implements ISnackBarService {
  static final SnackBarService _instance = SnackBarService._internal();
  factory SnackBarService() => _instance;
  SnackBarService._internal();

  /// Shows an error snackbar, optionally with a single action
  @override
  void showError(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _showSnackBar(
      context,
      message,
      backgroundColor: isDark ? AppTheme.snackbarErrorDark : AppTheme.snackbarErrorLight,
      textColor: Colors.white,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Shows a success snackbar
  @override
  void showSuccess(BuildContext context, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _showSnackBar(
      context,
      message,
      backgroundColor: isDark ? AppTheme.snackbarSuccessDark : AppTheme.snackbarSuccessLight,
      textColor: Colors.white,
    );
  }

  /// Shows a simple info snackbar (for clipboard notifications, etc.)
  @override
  void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _showSnackBar(
      context,
      message,
      backgroundColor: isDark ? AppTheme.snackbarNeutralDark : AppTheme.snackbarNeutralLight,
      textColor: Colors.white,
      duration: duration,
    );
  }

  /// Internal method to show a snackbar with consistent styling
  void _showSnackBar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Color? textColor,
    Duration duration = const Duration(seconds: 5),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: textColor != null ? TextStyle(color: textColor) : null,
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: textColor,
                onPressed: onAction,
              )
            : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        margin: const EdgeInsets.all(16.0),
      ),
    );
  }

}
