import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// App bar title widget with VIOSA logo and app name
class AppBarTitleWithLogo extends StatelessWidget {
  const AppBarTitleWithLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/viosa_icon.png',
          height: 32,
          width: 32,
        ),
        const SizedBox(width: 8),
        const Text(AppConstants.appName),
      ],
    );
  }
}
