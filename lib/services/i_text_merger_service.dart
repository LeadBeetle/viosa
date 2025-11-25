/// Interface for merging transcription texts from overlapping audio splits
/// Following Interface Segregation Principle (ISP)
abstract class ITextMergerService {
  /// Merges multiple transcription texts, removing duplicates from overlapping regions
  /// [texts] - List of transcription texts in order
  /// Returns the merged text with overlap duplicates removed
  String mergeTexts(List<String> texts);
}
