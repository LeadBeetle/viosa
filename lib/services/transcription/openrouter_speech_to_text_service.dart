import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../models/transcript_segment.dart';
import '../llm_exceptions.dart';
import '../openrouter_http.dart';
import '../../repositories/model_repository.dart';
import 'i_speech_to_text_service.dart';

/// OpenRouter implementation of ISpeechToTextService
/// Uses the dedicated /audio/transcriptions endpoint and requests the full
/// MAI-Transcribe feature set: segment timestamps, automatic language
/// identification, speaker diarization, keyword biasing and transcript style
class OpenRouterSpeechToTextService implements ISpeechToTextService {
  final Dio _dio;
  final String baseUrl;

  static const int _maxPhrases = 100;

  @override
  final String model;

  @override
  String get providerId => 'openrouter';

  @override
  String get providerName => 'OpenRouter';

  OpenRouterSpeechToTextService({
    Dio? dio,
    this.baseUrl = OpenRouterHttp.baseUrl,
    this.model = ModelRepository.transcriptionModelId,
  }) : _dio = dio ?? Dio() {
    OpenRouterHttp.configureTimeouts(_dio);
  }

  @override
  Future<SpeechToTextResult> transcribe({
    required String apiKey,
    required String base64Audio,
    required String format,
    String? language,
    bool diarization = false,
    List<String> phrases = const [],
    TranscribeStyle? transcribeStyle,
  }) async {
    final request = <String, dynamic>{
      'model': model,
      'input_audio': {
        'data': base64Audio,
        'format': format,
      },
      'response_format': 'verbose_json',
      'timestamp_granularities': ['segment'],
    };

    if (language != null && language.isNotEmpty && language != 'auto') {
      request['language'] = language;
    }

    final azureOptions = _buildAzureOptions(
      diarization: diarization,
      phrases: phrases,
      transcribeStyle: transcribeStyle,
    );

    if (azureOptions.isNotEmpty) {
      request['provider'] = {
        'options': {'azure': azureOptions},
      };
    }

    for (final variant in _variantsOf(request)) {
      debugPrint(
        'Transcription request (${variant.name}): '
        '${_describeRequest(variant.request, base64Audio)}',
      );

      final response = await _post(apiKey, variant.request);

      if (response.statusCode == 400 && !variant.isLast) {
        OpenRouterHttp.logErrorBody(response.statusCode, response.data);
        debugPrint('Variant ${variant.name} rejected with 400, trying next');
        continue;
      }

      OpenRouterHttp.throwForStatus(response.statusCode, response.data);
      debugPrint('Transcription accepted with variant ${variant.name}');
      return _parseResponse(response.data);
    }

    throw LLMProviderException(
      'Transcription rejected with 400 for every request variant',
      statusCode: 400,
    );
  }

  Future<Response<dynamic>> _post(
    String apiKey,
    Map<String, dynamic> request,
  ) async {
    try {
      return await _dio.post(
        '$baseUrl${OpenRouterHttp.transcriptionsPath}',
        data: request,
        options: Options(
          headers: OpenRouterHttp.buildHeaders(apiKey),
          validateStatus: (status) => status != null && status < 600,
        ),
      );
    } on DioException catch (e) {
      throw OpenRouterHttp.mapDioException(e);
    }
  }

  /// Progressively simpler versions of [request]
  ///
  /// OpenRouter forwards an upstream rejection as a bare "Provider returned
  /// 400" without naming the field, so the optional parts are dropped one by
  /// one until the API accepts the call. The log names the variant that worked
  List<_RequestVariant> _variantsOf(Map<String, dynamic> request) {
    final variants = <Map<String, dynamic>>[Map.of(request)];

    if (request.containsKey('provider')) {
      variants.add(Map.of(variants.last)..remove('provider'));
    }
    if (request.containsKey('timestamp_granularities')) {
      variants.add(Map.of(variants.last)..remove('timestamp_granularities'));
    }
    variants.add(Map.of(variants.last)..remove('response_format'));

    return [
      for (var i = 0; i < variants.length; i++)
        _RequestVariant(
          request: variants[i],
          name: _variantName(variants[i]),
          isLast: i == variants.length - 1,
        ),
    ];
  }

  String _variantName(Map<String, dynamic> request) {
    final parts = <String>[
      if (request.containsKey('provider')) 'provider',
      if (request.containsKey('timestamp_granularities')) 'timestamps',
      if (request.containsKey('response_format')) 'verbose_json',
    ];
    return parts.isEmpty ? 'minimal' : parts.join('+');
  }

  /// Renders the request for the log with the audio replaced by its size
  String _describeRequest(Map<String, dynamic> request, String base64Audio) {
    final described = Map<String, dynamic>.from(request);
    described['input_audio'] = {
      'data': '<${base64Audio.length} base64 chars>',
      'format': (request['input_audio'] as Map)['format'],
    };
    return described.toString();
  }

  Map<String, dynamic> _buildAzureOptions({
    required bool diarization,
    required List<String> phrases,
    required TranscribeStyle? transcribeStyle,
  }) {
    final options = <String, dynamic>{};

    if (diarization) {
      options['diarization'] = {'enabled': true};
    }

    final cleanedPhrases = phrases
        .map((phrase) => phrase.trim())
        .where((phrase) => phrase.isNotEmpty)
        .take(_maxPhrases)
        .toList();

    if (cleanedPhrases.isNotEmpty) {
      options['phraseList'] = {'phrases': cleanedPhrases};
    }

    if (transcribeStyle != null) {
      options['enhancedMode'] = {
        'modelOptions': {'transcribeStyle': transcribeStyle.wireValue},
      };
    }

    return options;
  }

  SpeechToTextResult _parseResponse(dynamic responseData) {
    try {
      final data = responseData as Map<String, dynamic>;
      final segments = _parseSegments(data['segments']);
      final text = (data['text'] as String?) ?? _textFromSegments(segments);
      final detectedLanguage = (data['language'] as String?)?.trim();

      return SpeechToTextResult(
        text: text,
        model: model,
        detectedLanguage:
            detectedLanguage == null || detectedLanguage.isEmpty ? null : detectedLanguage,
        segments: segments,
      );
    } catch (e) {
      throw LLMProviderException('Failed to parse API response: $e');
    }
  }

  List<TranscriptSegment> _parseSegments(dynamic rawSegments) {
    if (rawSegments is! List) return const [];

    final segments = <TranscriptSegment>[];

    for (final entry in rawSegments) {
      if (entry is! Map) continue;

      final text = (entry['text'] as String?)?.trim();
      if (text == null || text.isEmpty) continue;

      segments.add(
        TranscriptSegment(
          startMs: _toMilliseconds(entry['start']),
          endMs: _toMilliseconds(entry['end']),
          text: text,
          speaker: _speakerLabel(entry),
        ),
      );
    }

    return segments;
  }

  String? _speakerLabel(Map<dynamic, dynamic> segment) {
    final raw = segment['speaker'] ?? segment['speaker_id'] ?? segment['speakerId'];
    if (raw == null) return null;

    final label = raw.toString().trim();
    return label.isEmpty ? null : label;
  }

  int _toMilliseconds(dynamic value) {
    if (value is num) return (value * 1000).round();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) return (parsed * 1000).round();
    }
    return 0;
  }

  String _textFromSegments(List<TranscriptSegment> segments) {
    return segments.map((segment) => segment.text).join(' ').trim();
  }
}

/// One attempt of the transcription request with its log label
class _RequestVariant {
  final Map<String, dynamic> request;
  final String name;
  final bool isLast;

  const _RequestVariant({
    required this.request,
    required this.name,
    required this.isLast,
  });
}
