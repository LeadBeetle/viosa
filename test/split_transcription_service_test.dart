import 'package:flutter_test/flutter_test.dart';
import 'package:viosa/models/audio_split.dart';
import 'package:viosa/models/split_transcription_job.dart';
import 'package:viosa/services/audio_splitter_service.dart';
import 'package:viosa/services/split_transcription_exceptions.dart';
import 'package:viosa/services/split_transcription_service.dart';

/// Merkt sich die gelöschten Splits, statt Dateien anzufassen.
class _RecordingSplitterService extends AudioSplitterService {
  final deleted = <String>[];

  @override
  Future<void> cleanupSplits(List<AudioSplit> splits) async {
    deleted.addAll(splits.map((split) => split.filePath));
  }
}

AudioSplit _split(int index, String filePath) => AudioSplit(
      id: 'split$index',
      index: index,
      filePath: filePath,
      startTimeMs: index * 60000,
      endTimeMs: (index + 1) * 60000,
      size: 1024,
      mimeType: 'audio/m4a',
    );

SplitTranscriptionJob _job(String audioPath, List<AudioSplit> splits) =>
    SplitTranscriptionJob(
      id: 'job',
      originalAudioPath: audioPath,
      originalFileName: 'audio.m4a',
      totalSplits: splits.length,
      splits: splits,
      language: 'de',
      createdAt: DateTime(2026),
    );

void main() {
  group('SplitTranscriptionService.cleanupSplits', () {
    test('behält die Aufnahme, die als einziger Split dient', () async {
      final splitter = _RecordingSplitterService();
      final service = SplitTranscriptionService(splitterService: splitter);
      const audioPath = '/data/app_flutter/recording_1.m4a';

      await service.cleanupSplits(_job(audioPath, [_split(0, audioPath)]));

      expect(splitter.deleted, isEmpty);
    });

    test('löscht die erzeugten Teildateien', () async {
      final splitter = _RecordingSplitterService();
      final service = SplitTranscriptionService(splitterService: splitter);
      const audioPath = '/data/app_flutter/recording_1.m4a';

      await service.cleanupSplits(
        _job(audioPath, [
          _split(0, '/tmp/audio_splits/split_000.m4a'),
          _split(1, '/tmp/audio_splits/split_001.m4a'),
        ]),
      );

      expect(splitter.deleted, hasLength(2));
    });
  });

  group('AudioSplitterService.splitAudio', () {
    test('meldet eine fehlende Audiodatei mit eigenem Fehlertyp', () async {
      final service = AudioSplitterService();

      expect(
        () => service.splitAudio('/does/not/exist.m4a'),
        throwsA(isA<AudioFileMissingException>()),
      );
    });
  });
}
