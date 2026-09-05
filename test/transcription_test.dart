import 'package:flutter_test/flutter_test.dart';
import 'package:viosa/models/transcript_segment.dart';
import 'package:viosa/models/transcription_history.dart';
import 'package:viosa/models/transcription_result.dart';
import 'package:viosa/services/diarized_transcript_builder.dart';
import 'package:viosa/services/export/srt_export_formatter.dart';

void main() {
  group('DiarizedTranscriptBuilder', () {
    final builder = DiarizedTranscriptBuilder();

    final segments = [
      const TranscriptSegment(startMs: 0, endMs: 1000, text: 'Hallo.', speaker: 'speaker_0'),
      const TranscriptSegment(startMs: 1000, endMs: 2000, text: 'Wie geht es?', speaker: 'speaker_0'),
      const TranscriptSegment(startMs: 2000, endMs: 3000, text: 'Gut, danke.', speaker: 'speaker_1'),
    ];

    test('fasst aufeinanderfolgende Segmente eines Sprechers zusammen', () {
      final text = builder.build(segments, 'de');

      expect(text, '**Sprecher 1:** Hallo. Wie geht es?\n\n**Sprecher 2:** Gut, danke.');
    });

    test('nutzt englische Label für andere Sprachen', () {
      final text = builder.build(segments, 'en');

      expect(text, startsWith('**Speaker 1:**'));
    });

    test('behält echte Namen als Label bei', () {
      final named = [
        const TranscriptSegment(startMs: 0, endMs: 1000, text: 'Hallo.', speaker: 'Anna'),
      ];

      expect(builder.build(named, 'de'), '**Anna:** Hallo.');
    });

    test('ersetzt Rohlabels in den Segmenten', () {
      final labelled = builder.withDisplayLabels(segments, 'de');

      expect(labelled.map((s) => s.speaker).toList(),
          ['Sprecher 1', 'Sprecher 1', 'Sprecher 2']);
    });
  });

  group('SrtExportFormatter', () {
    test('schreibt Zeitcodes und Sprecher', () {
      final history = TranscriptionHistory(
        audioFileName: 'meeting.m4a',
        transcription: TranscriptionResult(
          text: 'Hallo.',
          language: 'de',
          modelUsed: 'microsoft/mai-transcribe-2',
          timestamp: DateTime(2026, 1, 1),
          segments: const [
            TranscriptSegment(
              startMs: 1500,
              endMs: 3250,
              text: 'Hallo.',
              speaker: 'Sprecher 1',
            ),
          ],
        ),
      );

      final srt = SrtExportFormatter().format(history);

      expect(srt, '1\n00:00:01,500 --> 00:00:03,250\nSprecher 1: Hallo.');
    });
  });
}
