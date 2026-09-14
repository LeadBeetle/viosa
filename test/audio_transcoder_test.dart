import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viosa/services/audio_transcoder_service.dart';
import 'package:viosa/services/i_audio_transcoder_service.dart';
import 'package:viosa/services/transcription_exceptions.dart';
import 'package:viosa/services/transcription_job_service.dart';
import 'package:viosa/models/transcription_options.dart';
import 'package:viosa/models/transcription_result.dart';
import 'package:viosa/services/transcription_service.dart';

class _FakeTranscoder implements IAudioTranscoderService {
  final String target;
  String? received;

  _FakeTranscoder(this.target);

  @override
  bool needsTranscoding(String audioPath) => !audioPath.endsWith('.wav');

  @override
  Future<String> toWav(String audioPath) async {
    received = audioPath;
    return needsTranscoding(audioPath) ? target : audioPath;
  }
}

class _RecordingTranscriptionService implements ITranscriptionService {
  String? audioPath;

  @override
  Future<TranscriptionResult> transcribe({
    required String apiKey,
    required String base64Audio,
    required String audioPath,
    required String language,
    required TranscriptionOptions options,
  }) async {
    this.audioPath = audioPath;
    return TranscriptionResult(
      text: 'hallo',
      language: language,
      modelUsed: 'test',
      timestamp: DateTime(2026),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('lädt die umgewandelte Datei hoch statt des Originals', () async {
    final directory = await Directory.systemTemp.createTemp('viosa_transcode');
    final source = File('${directory.path}/aufnahme.m4a')
      ..writeAsBytesSync([1, 2, 3]);
    final converted = File('${directory.path}/aufnahme.wav')
      ..writeAsBytesSync([4, 5, 6]);

    final transcoder = _FakeTranscoder(converted.path);
    final transcription = _RecordingTranscriptionService();

    final result = await TranscriptionJobService(
      transcriptionService: transcription,
      transcoderService: transcoder,
    ).transcribeFile(
      audioPath: source.path,
      apiKey: 'key',
      language: 'de',
      options: TranscriptionOptions(speakerLabel: (position) => 'S$position'),
    );

    expect(result.text, 'hallo');
    expect(transcoder.received, source.path);
    expect(transcription.audioPath, converted.path);

    await directory.delete(recursive: true);
  });

  test('reicht WAV unverändert durch', () {
    final service = AudioTranscoderService();

    expect(service.needsTranscoding('/tmp/aufnahme.wav'), isFalse);
  });

  test('meldet einen Plattformfehler als Umwandlungsfehler', () async {
    const channel = MethodChannel('ai.viosa.app/audio_transcode');
    final file = File(
      '${(await Directory.systemTemp.createTemp('viosa_fail')).path}/a.m4a',
    )..writeAsBytesSync([1]);

    const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    messenger.setMockMethodCallHandler(
      pathProvider,
      (call) async => Directory.systemTemp.path,
    );
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'transcode_failed', message: 'kein Decoder');
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(channel, null);
      messenger.setMockMethodCallHandler(pathProvider, null);
    });

    await expectLater(
      _TranscoderUnderTest(channel).toWav(file.path),
      throwsA(isA<AudioTranscodeException>()),
    );
  });
}

/// Erzwingt den Android-Pfad, den [AudioTranscoderService] sonst nur auf dem
/// Gerät nimmt
class _TranscoderUnderTest extends AudioTranscoderService {
  _TranscoderUnderTest(MethodChannel channel) : super(channel: channel);

  @override
  bool needsTranscoding(String audioPath) => !audioPath.endsWith('.wav');
}
