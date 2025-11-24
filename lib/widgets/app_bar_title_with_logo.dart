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
          height: 40,
          width: 40,
        ),
        const SizedBox(width: 4),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: const Text(AppConstants.appName),
        ),
      ],
    );
  }
}
