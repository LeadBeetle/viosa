import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'llm_exceptions.dart';

/// Shared HTTP concerns for every OpenRouter-backed service.
///
/// Headers, timeouts and the status-code to [LLMProviderException] mapping are
/// identical across the completion and speech-to-text services, so they live
/// here rather than being duplicated per endpoint.
class OpenRouterHttp {
  const OpenRouterHttp._();

  /// Base URL of the OpenRouter API
  static const String baseUrl = 'https://openrouter.ai/api/v1';

  /// Dedicated speech-to-text endpoint
  static const String transcriptionsPath = '/audio/transcriptions';

  /// Apply the timeouts every OpenRouter call shares
  static void configureTimeouts(Dio dio) {
    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.options.sendTimeout = const Duration(minutes: 7);
    dio.options.receiveTimeout = const Duration(minutes: 7);
  }

  /// Authorization and attribution headers required by OpenRouter
  static Map<String, String> buildHeaders(String apiKey) {
    return {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
      'HTTP-Referer': 'https://viosa-app.local',
      'X-Title': 'VIOSA',
    };
  }

  /// Throw the matching [LLMProviderException] for a non-200 response
  static void throwForStatus(int? statusCode, dynamic data) {
    if (statusCode != 200) logErrorBody(statusCode, data);
    if (statusCode == 401) throw LLMAuthException();
    if (statusCode == 429) throw LLMRateLimitException();
    if (statusCode == 503) {
      throw LLMServerException(503, 'Service temporarily unavailable.');
    }
    if (statusCode != null && statusCode >= 500) {
      throw LLMServerException(statusCode);
    }
    if (statusCode == 413) {
      throw LLMProviderException(
        'Audio payload too large for the transcription API.',
        statusCode: 413,
      );
    }
    if (statusCode != 200) {
      throw LLMProviderException(
        'API error: ${extractErrorMessage(data) ?? 'Unknown error'}',
        statusCode: statusCode,
      );
    }
  }

  /// Log the untouched error body so the upstream reason survives even when it
  /// is not part of the message the user gets to see
  static void logErrorBody(int? statusCode, dynamic data) {
    String body;
    try {
      body = jsonEncode(data);
    } catch (_) {
      body = data.toString();
    }
    if (body.length > 2000) body = '${body.substring(0, 2000)}…';
    debugPrint('OpenRouter $statusCode body: $body');
  }

  /// Pull the provider error message out of an error response body
  ///
  /// OpenRouter reports an upstream rejection as "Provider returned 400" and
  /// keeps the reason in `error.metadata`, so that detail is appended rather
  /// than dropped
  static String? extractErrorMessage(dynamic data) {
    if (data is! Map || data['error'] is! Map) return null;

    final error = data['error'] as Map;
    final message = error['message'];
    final detail = _extractProviderDetail(error['metadata']);

    if (message is! String) return detail;
    return detail == null ? message : '$message ($detail)';
  }

  static String? _extractProviderDetail(dynamic metadata) {
    if (metadata is! Map) return null;

    final parts = <String>[];
    final provider = metadata['provider_name'];
    if (provider is String && provider.isNotEmpty) parts.add(provider);

    final raw = metadata['raw'];
    if (raw is String && raw.isNotEmpty) {
      parts.add(raw);
    } else if (raw != null) {
      parts.add(raw.toString());
    }

    return parts.isEmpty ? null : parts.join(': ');
  }

  /// Translate a [DioException] into the app's exception vocabulary
  static LLMProviderException mapDioException(DioException e) {
    if (e.type == DioExceptionType.cancel) {
      return LLMProviderException('Request cancelled by user');
    }
    if (e.type == DioExceptionType.connectionTimeout) {
      return LLMTimeoutException('Connection timeout. Please check your internet connection.');
    }
    if (e.type == DioExceptionType.sendTimeout) {
      return LLMTimeoutException('Upload timeout. Your file may be too large or connection too slow.');
    }
    if (e.type == DioExceptionType.receiveTimeout) {
      return LLMTimeoutException('Response timeout. The server is taking too long to respond.');
    }
    if (e.type == DioExceptionType.connectionError) {
      return LLMNetworkException();
    }
    final statusCode = e.response?.statusCode;
    if (statusCode != null) {
      if (statusCode == 401) return LLMAuthException();
      if (statusCode == 429) return LLMRateLimitException();
      if (statusCode >= 500) return LLMServerException(statusCode);
    }
    return LLMProviderException('Request failed: ${e.message}');
  }
}
