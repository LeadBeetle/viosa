import 'package:flutter_test/flutter_test.dart';
import 'package:viosa/models/transcription_options.dart';
import 'package:viosa/models/transcription_result.dart';
import 'package:viosa/providers/transcription_job_provider.dart';
import 'package:viosa/services/i_transcription_job_service.dart';
import 'package:viosa/services/transcription_exceptions.dart';

class _FakeTranscriptionJobService implements ITranscriptionJobService {
  final TranscriptionResult? result;
  final Object? error;
  int calls = 0;

  _FakeTranscriptionJobService({this.result, this.error});

  @override
  Future<TranscriptionResult> transcribeFile({
    required String audioPath,
    required String apiKey,
    required String language,
    required TranscriptionOptions options,
    String? model,
  }) async {
    calls++;
    if (error != null) throw error!;
    return result!;
  }
}

TranscriptionResult _result(String text) => TranscriptionResult(
      text: text,
      language: 'de',
      modelUsed: 'test',
      timestamp: DateTime(2026),
    );

TranscriptionOptions _options() =>
    TranscriptionOptions(speakerLabel: (position) => 'Sprecher $position');

Future<TranscriptionJobOutcome> _start(
  TranscriptionJobProvider provider, {
  String apiKey = 'key',
  Future<void> Function(String historyId, TranscriptionResult result)? onResult,
}) {
  final outcome = provider.jobOutcomes.first;

  provider.startTranscription(
    audioPath: 'audio.m4a',
    fileName: 'audio.m4a',
    language: 'de',
    apiKey: apiKey,
    historyId: 'history-1',
    options: _options(),
    onResult: onResult,
  );

  return outcome;
}

void main() {
  test('Ein fertiges Transkript wird gespeichert und dann gemeldet', () async {
    final stored = <String, TranscriptionResult>{};
    final provider = TranscriptionJobProvider(
      service: _FakeTranscriptionJobService(result: _result('Hallo')),
    );

    final outcome = await _start(
      provider,
      onResult: (historyId, result) async => stored[historyId] = result,
    );

    expect(stored['history-1']?.text, 'Hallo');
    expect(outcome.result?.text, 'Hallo');
    expect(outcome.error, isNull);
    expect(provider.isRunning, isFalse);
  });

  test('Nach einem Transkript wartet der Auto-Prompt auf den Eintrag',
      () async {
    final provider = TranscriptionJobProvider(
      service: _FakeTranscriptionJobService(result: _result('Hallo')),
    );

    await _start(provider);

    expect(provider.consumePendingAutoPrompt('history-2'), isFalse);
    expect(provider.consumePendingAutoPrompt('history-1'), isTrue);
    expect(provider.consumePendingAutoPrompt('history-1'), isFalse);
  });

  test('Ein Fehler beendet den Auftrag und erreicht die Oberfläche', () async {
    final provider = TranscriptionJobProvider(
      service: _FakeTranscriptionJobService(
        error: const AudioFileMissingException('audio.m4a'),
      ),
    );

    final outcome = await _start(provider);

    expect(outcome.result, isNull);
    expect(outcome.error, isA<AudioFileMissingException>());
    expect(provider.isRunning, isFalse);
    expect(provider.lastError, isA<AudioFileMissingException>());
  });

  test('Ohne API-Schlüssel läuft keine Transkription an', () async {
    final service = _FakeTranscriptionJobService(result: _result('Hallo'));
    final provider = TranscriptionJobProvider(service: service);

    final outcome = await _start(provider, apiKey: '');

    expect(service.calls, 0);
    expect(outcome.error, isA<MissingApiKeyException>());
  });

  test('Ein abgebrochener Auftrag speichert sein Ergebnis nicht', () async {
    final stored = <String, TranscriptionResult>{};
    final provider = TranscriptionJobProvider(
      service: _FakeTranscriptionJobService(result: _result('Hallo')),
    );

    provider.startTranscription(
      audioPath: 'audio.m4a',
      fileName: 'audio.m4a',
      language: 'de',
      apiKey: 'key',
      historyId: 'history-1',
      options: _options(),
      onResult: (historyId, result) async => stored[historyId] = result,
    );
    provider.cancel();

    await Future<void>.delayed(Duration.zero);

    expect(stored, isEmpty);
    expect(provider.isRunning, isFalse);
    expect(provider.activeJobId, isNull);
  });
}
