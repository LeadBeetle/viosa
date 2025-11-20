import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Standardized loading indicators for consistent feedback across the app
class AppLoadingIndicator extends StatelessWidget {
  final AppLoadingIndicatorSize size;
  final Color? color;

  const AppLoadingIndicator({
    super.key,
    this.size = AppLoadingIndicatorSize.medium,
    this.color,
  });

  const AppLoadingIndicator.small({
    super.key,
    this.color,
  }) : size = AppLoadingIndicatorSize.small;

  const AppLoadingIndicator.medium({
    super.key,
    this.color,
  }) : size = AppLoadingIndicatorSize.medium;

  const AppLoadingIndicator.large({
    super.key,
    this.color,
  }) : size = AppLoadingIndicatorSize.large;

  @override
  Widget build(BuildContext context) {
    final dimensions = _getDimensions();
    final strokeWidth = _getStrokeWidth();

    return SizedBox(
      width: dimensions,
      height: dimensions,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        color: color,
      ),
    );
  }

  double _getDimensions() {
    switch (size) {
      case AppLoadingIndicatorSize.small:
        return AppLoadingSize.small;
      case AppLoadingIndicatorSize.medium:
        return AppLoadingSize.medium;
      case AppLoadingIndicatorSize.large:
        return AppLoadingSize.large;
    }
  }

  double _getStrokeWidth() {
    switch (size) {
      case AppLoadingIndicatorSize.small:
        return AppStrokeWidth.thin;
      case AppLoadingIndicatorSize.medium:
        return AppStrokeWidth.normal;
      case AppLoadingIndicatorSize.large:
        return AppStrokeWidth.thick;
    }
  }
}

enum AppLoadingIndicatorSize {
  small,
  medium,
  large,
}
