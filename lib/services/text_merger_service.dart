import 'i_text_merger_service.dart';

/// Service for merging transcription texts from overlapping audio splits
/// Uses suffix-prefix matching to detect and remove duplicate content
/// Following Single Responsibility Principle (SRP)
class TextMergerService implements ITextMergerService {
  static const int _minOverlapWords = 2;
  static const int _maxOverlapWords = 50;

  @override
  String mergeTexts(List<String> texts) {
    if (texts.isEmpty) return '';
    if (texts.length == 1) return texts.first.trim();

    final result = StringBuffer();
    result.write(texts.first.trim());

    for (int i = 1; i < texts.length; i++) {
      final previousText = i == 1 ? texts.first.trim() : result.toString();
      final currentText = texts[i].trim();

      if (currentText.isEmpty) continue;

      final mergedPart = _mergeWithOverlapDetection(previousText, currentText);

      if (mergedPart != null) {
        result.clear();
        result.write(mergedPart);
      } else {
        result.write(' ');
        result.write(currentText);
      }
    }

    return result.toString();
  }

  String? _mergeWithOverlapDetection(String text1, String text2) {
    if (text1.isEmpty || text2.isEmpty) return null;

    final words1 = _tokenize(text1);
    final words2 = _tokenize(text2);

    if (words1.isEmpty || words2.isEmpty) return null;

    final overlapLength = _findBestOverlap(words1, words2);

    if (overlapLength >= _minOverlapWords) {
      final text1Part = words1.sublist(0, words1.length - overlapLength).join(' ');
      final text2Full = words2.join(' ');

      if (text1Part.isEmpty) {
        return text2Full;
      }
      return '$text1Part $text2Full';
    }

    return null;
  }

  List<String> _tokenize(String text) {
    return text
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
  }

  int _findBestOverlap(List<String> words1, List<String> words2) {
    final maxPossibleOverlap = _maxOverlapWords.clamp(0, words1.length.clamp(0, words2.length));

    for (int overlapLen = maxPossibleOverlap; overlapLen >= _minOverlapWords; overlapLen--) {
      if (overlapLen > words1.length || overlapLen > words2.length) continue;

      final suffix = words1.sublist(words1.length - overlapLen);
      final prefix = words2.sublist(0, overlapLen);

      if (_wordsMatch(suffix, prefix)) {
        return overlapLen;
      }
    }

    return 0;
  }

  bool _wordsMatch(List<String> words1, List<String> words2) {
    if (words1.length != words2.length) return false;

    for (int i = 0; i < words1.length; i++) {
      if (!_fuzzyWordMatch(words1[i], words2[i])) {
        return false;
      }
    }
    return true;
  }

  bool _fuzzyWordMatch(String word1, String word2) {
    final normalized1 = _normalizeWord(word1);
    final normalized2 = _normalizeWord(word2);

    if (normalized1 == normalized2) return true;

    if (normalized1.length > 3 && normalized2.length > 3) {
      final distance = _levenshteinDistance(normalized1, normalized2);
      final maxLen = normalized1.length > normalized2.length
          ? normalized1.length
          : normalized2.length;
      return distance <= (maxLen * 0.2).ceil();
    }

    return false;
  }

  String _normalizeWord(String word) {
    return word
        .toLowerCase()
        .replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '');
  }

  int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> previousRow = List.generate(s2.length + 1, (i) => i);
    List<int> currentRow = List.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      currentRow[0] = i + 1;

      for (int j = 0; j < s2.length; j++) {
        final insertCost = previousRow[j + 1] + 1;
        final deleteCost = currentRow[j] + 1;
        final replaceCost = s1[i] == s2[j] ? previousRow[j] : previousRow[j] + 1;

        currentRow[j + 1] = [insertCost, deleteCost, replaceCost].reduce((a, b) => a < b ? a : b);
      }

      final temp = previousRow;
      previousRow = currentRow;
      currentRow = temp;
    }

    return previousRow[s2.length];
  }
}
