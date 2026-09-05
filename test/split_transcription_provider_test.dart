import 'package:flutter_test/flutter_test.dart';
import 'package:viosa/models/audio_split.dart';
import 'package:viosa/models/split_transcription_job.dart';
import 'package:viosa/models/transcription_options.dart';
import 'package:viosa/models/transcription_result.dart';
import 'package:viosa/providers/split_transcription_provider.dart';
import 'package:viosa/services/i_audio_splitter_service.dart';
import 'package:viosa/services/split_transcription_service.dart';

/// Ersetzt das echte Aufteilen und Transkribieren, damit nur die Reihenfolge
/// von Speichern und Benachrichtigen geprüft wird.
class _FakeSplitTranscriptionService extends SplitTranscriptionService {
  static const int totalSplits = 2;

  final int failingSplits;
  int retriedSplits = 0;

  _FakeSplitTranscriptionService({this.failingSplits = 0});

  @override
  Future<SplitTranscriptionJob> createJob({
    required String audioPath,
    required String fileName,
    required String language,
    Duration maxDuration = const Duration(minutes: 10),
    Duration overlap = const Duration(seconds: 5),
    void Function(SplitProgress progress)? onSplitProgress,
  }) async {
    return SplitTranscriptionJob(
      id: 'job',
      originalAudioPath: audioPath,
      originalFileName: fileName,
      totalSplits: totalSplits,
      splits: List.generate(
        totalSplits,
        (index) => AudioSplit(
          id: 'split$index',
          filePath: '$audioPath.$index',
          index: index,
          startTimeMs: index * 60000,
          endTimeMs: (index + 1) * 60000,
          size: 1024,
          mimeType: 'audio/m4a',
        ),
      ),
      language: language,
      createdAt: DateTime(2026),
    );
  }

  @override
  Future<void> processJob(
    SplitTranscriptionJob job,
    String apiKey, {
    required TranscriptionOptions options,
    String? model,
    void Function(SplitTranscriptionJob)? onProgress,
  }) async {
    job.status = JobStatus.processing;
    onProgress?.call(job);

    for (final split in job.splits) {
      if (split.index < failingSplits) {
        split.status = SplitStatus.failed;
        job.failedCount++;
      } else {
        split.status = SplitStatus.completed;
        split.transcriptionText = 'Teil ${split.index}';
        job.completedCount++;
      }
      onProgress?.call(job);
    }

    job.status =
        job.failedCount > 0 ? JobStatus.partialFailure : JobStatus.completed;
    job.completedAt = DateTime(2026);
    onProgress?.call(job);
  }

  @override
  Future<void> retryFailedSplit(
    SplitTranscriptionJob job,
    String splitId,
    String apiKey, {
    required TranscriptionOptions options,
    void Function(SplitTranscriptionJob)? onProgress,
  }) async {
    final split = job.splits.firstWhere((s) => s.id == splitId);
    split.status = SplitStatus.completed;
    split.transcriptionText = 'Teil ${split.index}';
    job.failedCount--;
    job.completedCount++;
    retriedSplits++;

    if (job.failedCount == 0) {
      job.status = JobStatus.completed;
    }
    onProgress?.call(job);
  }

  @override
  Future<void> cleanupSplits(SplitTranscriptionJob job) async {}
}

TranscriptionOptions _options() =>
    TranscriptionOptions(speakerLabel: (position) => 'Sprecher $position');

Future<SplitTranscriptionOutcome> _startAndAwait(
  SplitTranscriptionProvider provider, {
  required Future<void> Function(String, TranscriptionResult) onResult,
}) async {
  final outcome = provider.jobOutcomes.first;

  await provider.startTranscription(
    audioPath: 'audio.m4a',
    fileName: 'audio.m4a',
    language: 'de',
    apiKey: 'key',
    historyId: 'history-1',
    options: _options(),
    onResult: onResult,
  );

  return outcome;
}

void main() {
  group('SplitTranscriptionProvider', () {
    test('meldet das Ergebnis erst nach dem Speichern', () async {
      var savedBeforeOutcome = false;
      final provider = SplitTranscriptionProvider(
        service: _FakeSplitTranscriptionService(),
      );

      final outcome = await _startAndAwait(
        provider,
        onResult: (id, result) async {
          savedBeforeOutcome = true;
        },
      );

      expect(savedBeforeOutcome, isTrue);
      expect(outcome.result, isNotNull);
      expect(outcome.error, isNull);
      expect(provider.consumePendingAutoPrompt('history-1'), isTrue);
    });

    test('hält den fertigen Job aus jobUpdates heraus', () async {
      final provider = SplitTranscriptionProvider(
        service: _FakeSplitTranscriptionService(),
      );
      var updateCount = 0;
      provider.jobUpdates.listen((_) => updateCount++);

      await _startAndAwait(provider, onResult: (id, result) async {});

      expect(updateCount, 3);
    });

    test('meldet einen Fehler beim Speichern statt eines Ergebnisses', () async {
      final provider = SplitTranscriptionProvider(
        service: _FakeSplitTranscriptionService(),
      );

      final outcome = await _startAndAwait(
        provider,
        onResult: (id, result) async => throw StateError('Box zu'),
      );

      expect(outcome.result, isNull);
      expect(outcome.error, isA<StateError>());
      expect(provider.lastError, isA<StateError>());
      expect(provider.consumePendingAutoPrompt('history-1'), isFalse);
    });

    test('speichert das reparierte Transkript nach einem erneuten Versuch',
        () async {
      final service = _FakeSplitTranscriptionService(failingSplits: 1);
      final provider = SplitTranscriptionProvider(service: service);
      final saved = <TranscriptionResult>[];

      final partial = await _startAndAwait(
        provider,
        onResult: (id, result) async => saved.add(result),
      );

      expect(partial.job.hasFailures, isTrue);
      expect(saved, hasLength(1));

      final repaired = provider.jobOutcomes.first;
      await provider.retryAllFailedSplits('job');
      final outcome = await repaired;

      expect(service.retriedSplits, 1);
      expect(saved, hasLength(2));
      expect(outcome.job.hasFailures, isFalse);
      expect(outcome.result, isNotNull);
    });
  });
}
