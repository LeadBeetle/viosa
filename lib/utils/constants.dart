import 'package:flutter/material.dart';

/// Represents an AI model option with metadata for display
class ModelOption {
  final String id;
  final String name;
  final String provider;
  final String tier;
  final String description;

  const ModelOption({
    required this.id,
    required this.name,
    required this.provider,
    required this.tier,
    required this.description,
  });
}

class AppConstants {
  // App Info
  static const String appName = 'Viosa';
  static const String appTitle = 'Viosa Audio Transcription';

  // API
  static const String openRouterApiUrl = 'https://openrouter.ai/api/v1/chat/completions';
  static const String defaultModel = 'google/gemini-2.5-flash';

  // Supported Models
  static const List<ModelOption> supportedModels = [
    ModelOption(
      id: 'google/gemini-2.5-flash',
      name: 'Gemini 2.5 Flash',
      provider: 'Google',
      tier: 'Schnell & günstig',
      description: 'Ideal für einfache Transkriptionen und schnelle Ergebnisse',
    ),
    ModelOption(
      id: 'google/gemini-2.5-pro',
      name: 'Gemini 2.5 Pro',
      provider: 'Google',
      tier: 'Ausgewogen',
      description: 'Bessere Qualität für komplexe Audio-Inhalte',
    ),
    ModelOption(
      id: 'anthropic/claude-sonnet-4.5',
      name: 'Claude Sonnet 4.5',
      provider: 'Anthropic',
      tier: 'Premium',
      description: 'Höchste Qualität für anspruchsvolle Aufgaben',
    ),
  ];

  // Legacy constant for backward compatibility
  static const String llmModel = defaultModel;

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
