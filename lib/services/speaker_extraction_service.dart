import '../models/speaker.dart';

/// Service for extracting speaker information from transcription text
abstract class ISpeakerExtractionService {
  List<Speaker> extractSpeakers(String transcriptionText);
}

class SpeakerExtractionService implements ISpeakerExtractionService {
  static const List<String> _speakerColors = [
    '#4CAF50', // Green
    '#2196F3', // Blue
    '#FF9800', // Orange
    '#9C27B0', // Purple
    '#F44336', // Red
    '#00BCD4', // Cyan
    '#795548', // Brown
    '#607D8B', // Blue Grey
  ];

  @override
  List<Speaker> extractSpeakers(String transcriptionText) {
    final speakerLabels = <String>{};

    final patterns = [
      RegExp(r'^\*\*(Sprecher \d+):\*\*', multiLine: true),
      RegExp(r'^\*\*(Speaker \d+):\*\*', multiLine: true),
      RegExp(r'^\*\*([A-ZÄÖÜ][a-zäöüß]+(?:\s+[A-ZÄÖÜ][a-zäöüß]+)?):\*\*', multiLine: true),
      RegExp(r'\n\*\*(Sprecher \d+):\*\*'),
      RegExp(r'\n\*\*(Speaker \d+):\*\*'),
      RegExp(r'\n\*\*([A-ZÄÖÜ][a-zäöüß]+(?:\s+[A-ZÄÖÜ][a-zäöüß]+)?):\*\*'),
      RegExp(r'^(Sprecher \d+):', multiLine: true),
      RegExp(r'^(Speaker \d+):', multiLine: true),
      RegExp(r'^([A-ZÄÖÜ][a-zäöüß]+(?:\s+[A-ZÄÖÜ][a-zäöüß]+)?):', multiLine: true),
      RegExp(r'\n(Sprecher \d+):'),
      RegExp(r'\n(Speaker \d+):'),
      RegExp(r'\n([A-ZÄÖÜ][a-zäöüß]+(?:\s+[A-ZÄÖÜ][a-zäöüß]+)?):'),
    ];

    for (final pattern in patterns) {
      final matches = pattern.allMatches(transcriptionText);
      for (final match in matches) {
        final label = match.group(1)?.trim();
        if (label != null && label.isNotEmpty && !_isCommonWord(label)) {
          speakerLabels.add(label);
        }
      }
    }

    final speakers = <Speaker>[];
    var colorIndex = 0;

    for (final label in speakerLabels) {
      speakers.add(Speaker(
        label: label,
        color: _speakerColors[colorIndex % _speakerColors.length],
      ));
      colorIndex++;
    }

    return speakers;
  }

  bool _isCommonWord(String word) {
    const commonWords = {
      'Ja', 'Nein', 'Okay', 'Also', 'Gut', 'Danke', 'Bitte',
      'Yes', 'No', 'Well', 'So', 'Ok', 'Thanks', 'Please',
      'Beispiel', 'Example', 'Frage', 'Question', 'Antwort', 'Answer',
      'Hinweis', 'Note', 'Wichtig', 'Important',
    };
    return commonWords.contains(word);
  }
}
