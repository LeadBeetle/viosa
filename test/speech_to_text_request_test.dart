import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viosa/services/llm_exceptions.dart';
import 'package:viosa/services/transcription/i_speech_to_text_service.dart';
import 'package:viosa/services/transcription/openrouter_speech_to_text_service.dart';

class _RecordingAdapter implements HttpClientAdapter {
  final List<Map<String, dynamic>> requests = [];
  final int statusCode;

  _RecordingAdapter({this.statusCode = 200});

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(jsonDecode(jsonEncode(options.data)) as Map<String, dynamic>);

    final body = statusCode == 200
        ? {'text': 'hallo', 'language': 'de'}
        : {
            'error': {'message': 'Provider returned 400', 'code': statusCode}
          };

    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
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

Future<SpeechToTextResult> _transcribe(OpenRouterSpeechToTextService service) {
  return service.transcribe(
    apiKey: 'key',
    base64Audio: 'AAAA',
    format: 'wav',
    transcribeStyle: TranscribeStyle.clean,
  );
}

void main() {
  test('sendet genau eine Anfrage mit allen Optionen', () async {
    final adapter = _RecordingAdapter();

    final result = await _transcribe(_service(adapter));

    expect(result.text, 'hallo');
    expect(adapter.requests, hasLength(1));

    final request = adapter.requests.single;
    expect(request['model'], 'microsoft/mai-transcribe-2');
    expect((request['input_audio'] as Map)['format'], 'wav');
    expect(request['response_format'], 'verbose_json');
    expect(request['timestamp_granularities'], ['segment']);
    expect(request['provider'], isNotNull);
  });

  test('meldet den Fehler, ohne die Anfrage zu wiederholen', () async {
    final adapter = _RecordingAdapter(statusCode: 400);

    await expectLater(
      _transcribe(_service(adapter)),
      throwsA(isA<LLMProviderException>()),
    );

    expect(adapter.requests, hasLength(1));
  });
}
