import 'package:dio/dio.dart';
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
    String? transcribeStyle,
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

    try {
      final response = await _dio.post(
        '$baseUrl${OpenRouterHttp.transcriptionsPath}',
        data: request,
        options: Options(
          headers: OpenRouterHttp.buildHeaders(apiKey),
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      OpenRouterHttp.throwForStatus(response.statusCode, response.data);
      return _parseResponse(response.data);
    } on LLMProviderException {
      rethrow;
    } on DioException catch (e) {
      throw OpenRouterHttp.mapDioException(e);
    } catch (e) {
      if (e is Exception) rethrow;
      throw LLMProviderException('Transcription failed: $e');
    }
  }

  Map<String, dynamic> _buildAzureOptions({
    required bool diarization,
    required List<String> phrases,
    required String? transcribeStyle,
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

    if (transcribeStyle != null && transcribeStyle.isNotEmpty) {
      options['enhancedMode'] = {
        'modelOptions': {'transcribeStyle': transcribeStyle},
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
