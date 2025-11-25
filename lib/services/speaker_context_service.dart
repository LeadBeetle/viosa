import 'completion/i_completion_service.dart';

/// Represents context about a speaker for continuity across splits
class SpeakerContext {
  final String label;
  final String summary;

  SpeakerContext({
    required this.label,
    required this.summary,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'summary': summary,
      };

  factory SpeakerContext.fromJson(Map<String, dynamic> json) => SpeakerContext(
        label: json['label'] as String,
        summary: json['summary'] as String,
      );
}

/// Context passed between split transcriptions for speaker continuity
class TranscriptionContext {
  final List<SpeakerContext> speakers;

  TranscriptionContext({required this.speakers});

  bool get isEmpty => speakers.isEmpty;
  bool get isNotEmpty => speakers.isNotEmpty;

  String toPromptString(String language) {
    if (speakers.isEmpty) return '';

    final buffer = StringBuffer();

    if (language == 'de') {
      buffer.writeln('Bekannte Sprecher aus dem bisherigen Gespräch:');
      for (final speaker in speakers) {
        buffer.writeln('- ${speaker.label}: ${speaker.summary}');
      }
      buffer.writeln();
      buffer.writeln(
          'Ordne die Stimmen den bekannten Sprechern zu, falls sie übereinstimmen.');
    } else {
      buffer.writeln('Known speakers from the conversation so far:');
      for (final speaker in speakers) {
        buffer.writeln('- ${speaker.label}: ${speaker.summary}');
      }
      buffer.writeln();
      buffer.writeln(
          'Match voices to known speakers if they correspond.');
    }

    return buffer.toString();
  }
}

/// Interface for speaker context extraction
abstract class ISpeakerContextService {
  Future<TranscriptionContext> extractContext({
    required String apiKey,
    required String transcription,
    required String language,
  });
}

/// Service for extracting speaker context from transcriptions
class SpeakerContextService implements ISpeakerContextService {
  final ICompletionService _completionService;

  SpeakerContextService({
    required ICompletionService completionService,
  }) : _completionService = completionService;

  @override
  Future<TranscriptionContext> extractContext({
    required String apiKey,
    required String transcription,
    required String language,
  }) async {
    if (!_hasSpeakerLabels(transcription)) {
      return TranscriptionContext(speakers: []);
    }

    final prompt = _getExtractionPrompt(language, transcription);

    final messages = [
      CompletionMessage(
        role: 'user',
        content: [
          {'type': 'text', 'text': prompt}
        ],
      ),
    ];

    final response = await _completionService.complete(
      apiKey: apiKey,
      messages: messages,
      config: CompletionConfig(maxTokens: 2000, temperature: 0.1),
    );

    return _parseResponse(response);
  }

  bool _hasSpeakerLabels(String text) {
    return RegExp(r'(Sprecher \d+:|Speaker \d+:|^[A-ZÄÖÜ][a-zäöüß]+:)',
            multiLine: true)
        .hasMatch(text);
  }

  String _getExtractionPrompt(String language, String transcription) {
    if (language == 'de') {
      return '''Analysiere das folgende Transkript und extrahiere für jeden Sprecher:
1. Das Label/den Namen (z.B. "Max" oder "Sprecher 1")
2. Eine kurze Zusammenfassung (1-2 Sätze) der Hauptthemen, über die diese Person gesprochen hat

Antwortformat (exakt einhalten):
SPRECHER: [Label]
ZUSAMMENFASSUNG: [Kurze Zusammenfassung]
---

Transkript:
$transcription''';
    } else {
      return '''Analyze the following transcript and extract for each speaker:
1. The label/name (e.g. "John" or "Speaker 1")
2. A brief summary (1-2 sentences) of the main topics this person talked about

Response format (follow exactly):
SPEAKER: [Label]
SUMMARY: [Brief summary]
---

Transcript:
$transcription''';
    }
  }

  TranscriptionContext _parseResponse(String response) {
    final speakers = <SpeakerContext>[];
    final blocks = response.split('---');

    for (final block in blocks) {
      final trimmed = block.trim();
      if (trimmed.isEmpty) continue;

      String? label;
      String? summary;

      final lines = trimmed.split('\n');
      for (final line in lines) {
        if (line.startsWith('SPRECHER:') || line.startsWith('SPEAKER:')) {
          label = line.split(':').skip(1).join(':').trim();
        } else if (line.startsWith('ZUSAMMENFASSUNG:') ||
            line.startsWith('SUMMARY:')) {
          summary = line.split(':').skip(1).join(':').trim();
        }
      }

      if (label != null && label.isNotEmpty && summary != null && summary.isNotEmpty) {
        speakers.add(SpeakerContext(label: label, summary: summary));
      }
    }

    return TranscriptionContext(speakers: speakers);
  }
}
