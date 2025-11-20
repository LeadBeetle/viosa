import 'package:flutter/material.dart';

/// Interface for displaying snackbars with consistent styling
/// Follows Interface Segregation Principle and Dependency Inversion Principle
abstract class ISnackBarService {
  /// Shows an error snackbar
  void showError(BuildContext context, String message);

  /// Shows a success snackbar
  void showSuccess(BuildContext context, String message);

  /// Shows a simple info snackbar (for clipboard notifications, etc.)
  void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  });
}
