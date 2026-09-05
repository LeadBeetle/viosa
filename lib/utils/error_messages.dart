import 'dart:async';
import 'dart:io';
import 'package:flutter/widgets.dart';
import '../services/llm_exceptions.dart';
import '../services/transcription_exceptions.dart';
import '../l10n/l10n.dart';

/// Translates exceptions into user-facing messages
class ErrorMessages {
  const ErrorMessages._();

  static const int _maxDetailLength = 240;

  /// Returns a localized, user-friendly message for [error]
  static String forError(BuildContext context, Object? error) {
    final l10n = context.l10n;

    debugPrint('ErrorMessages: ${error.runtimeType}: $error');

    if (error is LLMAuthException) return l10n.errorAuth;
    if (error is LLMRateLimitException) return l10n.errorRateLimit;
    if (error is LLMNetworkException) return l10n.errorNetwork;
    if (error is LLMTimeoutException) return l10n.errorTimeout;
    if (error is LLMServerException) return l10n.errorServer;
    if (error is SocketException) return l10n.errorNetwork;
    if (error is TimeoutException) return l10n.errorTimeout;

    if (error is MissingApiKeyException) return l10n.errorApiKeyMissing;
    if (error is AudioFileMissingException) return l10n.errorAudioFileMissing;
    if (error is FileSystemException) return l10n.errorAudioFileMissing;

    if (error is LLMProviderException) {
      return l10n.errorServiceWithDetails(_detail(error.message));
    }
    if (error is TranscriptionPipelineException) {
      return l10n.errorServiceWithDetails(_detail(error.message));
    }

    if (error == null) return l10n.errorUnknown;
    return l10n.errorUnknownWithDetails(_detail(error.toString()));
  }

  /// Trims a raw error text to something a snackbar can show
  static String _detail(String message) {
    final cleaned = message.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.isEmpty) return message;
    if (cleaned.length <= _maxDetailLength) return cleaned;
    return '${cleaned.substring(0, _maxDetailLength)}…';
  }
}
