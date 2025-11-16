import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = 'Viosa';
  static const String appTitle = 'Viosa Audio Transcription';

  // API
  static const String openRouterApiUrl = 'https://openrouter.ai/api/v1/chat/completions';
  static const String llmModel = 'google/gemini-2.5-flash';

  // Supported Languages
  static const List<LanguageOption> supportedLanguages = [
    LanguageOption(code: 'auto', name: 'Auto-Detect'),
    LanguageOption(code: 'de', name: 'Deutsch'),
    LanguageOption(code: 'en', name: 'English'),
  ];

  // File Size Limits
  static const int maxFileSizeBytes = 25 * 1024 * 1024; // 25MB

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const double cardElevation = 2.0;

  // Colors
  static const Color primaryColor = Colors.deepPurple;
  static const Color errorColor = Colors.red;
  static const Color successColor = Colors.green;
}

class LanguageOption {
  final String code;
  final String name;

  const LanguageOption({
    required this.code,
    required this.name,
  });
}
