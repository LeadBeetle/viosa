import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viosa/services/llm_exceptions.dart';
import 'package:viosa/services/transcription/i_speech_to_text_service.dart';
import 'package:viosa/services/transcription/openrouter_speech_to_text_service.dart';

class _RecordingAdapter implements HttpClientAdapter {
  final List<Map<String, dynamic>> requests = [];
  final bool Function(Map<String, dynamic> request) accepts;

  _RecordingAdapter(this.accepts);

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final request = jsonDecode(jsonEncode(options.data)) as Map<String, dynamic>;
    requests.add(request);

    if (!accepts(request)) {
      return ResponseBody.fromString(
        jsonEncode({
          'error': {'message': 'Provider returned 400', 'code': 400}
        }),
        400,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType]
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode({'text': 'hallo', 'language': 'de'}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType]
      },
    );
  }
}

OpenRouterSpeechToTextService _service(_RecordingAdapter adapter) {
  final dio = Dio();
  dio.httpClientAdapter = adapter;
  return OpenRouterSpeechToTextService(dio: dio);
}

Future<dynamic> _transcribe(OpenRouterSpeechToTextService service) {
  return service.transcribe(
    apiKey: 'key',
    base64Audio: 'AAAA',
    format: 'm4a',
    transcribeStyle: TranscribeStyle.clean,
  );
}

void main() {
  test('sendet zuerst die vollständige Anfrage', () async {
    final adapter = _RecordingAdapter((_) => true);

    await _transcribe(_service(adapter));

    expect(adapter.requests, hasLength(1));
    expect(adapter.requests.single['provider'], isNotNull);
    expect(adapter.requests.single['response_format'], 'verbose_json');
  });

  test('lässt bei 400 die optionalen Felder nacheinander weg', () async {
    final adapter = _RecordingAdapter(
      (request) => !request.containsKey('provider'),
    );

    await _transcribe(_service(adapter));

    expect(adapter.requests, hasLength(2));
    expect(adapter.requests.first.containsKey('provider'), isTrue);
    expect(adapter.requests.last.containsKey('provider'), isFalse);
    expect(adapter.requests.last['response_format'], 'verbose_json');
  });

  test('meldet einen Fehler, wenn jede Variante abgelehnt wird', () async {
    final adapter = _RecordingAdapter((_) => false);

    await expectLater(
      _transcribe(_service(adapter)),
      throwsA(isA<LLMProviderException>()),
    );

    expect(adapter.requests, hasLength(4));
    expect(adapter.requests.last.containsKey('response_format'), isFalse);
    expect(adapter.requests.last.containsKey('timestamp_granularities'), isFalse);
  });
}
