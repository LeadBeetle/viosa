import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/prompt.dart';
import '../generated/app_localizations.dart';

/// Interface for prompt management operations
/// Following Interface Segregation Principle (ISP)
abstract class IPromptService {
  Future<void> initialize();
  Future<List<Prompt>> getAllPrompts(AppLocalizations l10n);
  Future<List<Prompt>> getCustomPrompts();
  List<Prompt> getPredefinedPrompts(AppLocalizations l10n);
  Future<void> saveCustomPrompt(Prompt prompt);
  Future<void> deleteCustomPrompt(String promptId);
  Future<Prompt?> getPromptById(String id, AppLocalizations l10n);
  String applyPromptTemplate(String template, String transcription);
  Future<void> incrementPromptUsage(String promptId);
  Future<int> getPromptUsageCount(String promptId);
  Future<DateTime?> getPromptLastUsed(String promptId);
}

/// Service for managing prompt templates
/// Single Responsibility Principle (SRP): Only handles prompt storage and retrieval
class PromptService implements IPromptService {
  static const String _customPromptsBoxName = 'custom_prompts';
  static const String _usageStatsBoxName = 'prompt_usage_stats';

  Box<Prompt>? _customPromptsBox;
  Box? _usageStatsBox;
  bool _isInitialized = false;

  /// Get localized predefined prompts
  List<Prompt> _getLocalizedPredefinedPrompts(AppLocalizations l10n) {
    return [
      Prompt(
        id: 'predefined_questions',
        name: l10n.predefinedPromptQuestionsName,
        template: l10n.predefinedPromptQuestionsTemplate,
        isPredefined: true,
      ),
      Prompt(
        id: 'predefined_action_items',
        name: l10n.predefinedPromptActionItemsName,
        template: l10n.predefinedPromptActionItemsTemplate,
        isPredefined: true,
      ),
      Prompt(
        id: 'predefined_summary',
        name: l10n.predefinedPromptSummaryName,
        template: l10n.predefinedPromptSummaryTemplate,
        isPredefined: true,
      ),
      Prompt(
        id: 'predefined_key_points',
        name: l10n.predefinedPromptKeyPointsName,
        template: l10n.predefinedPromptKeyPointsTemplate,
        isPredefined: true,
      ),
      Prompt(
        id: 'predefined_decisions',
        name: l10n.predefinedPromptDecisionsName,
        template: l10n.predefinedPromptDecisionsTemplate,
        isPredefined: true,
      ),
      Prompt(
        id: 'predefined_pro_contra',
        name: l10n.predefinedPromptProContraName,
        template: l10n.predefinedPromptProContraTemplate,
        isPredefined: true,
      ),
      Prompt(
        id: 'predefined_report',
        name: l10n.predefinedPromptReportName,
        template: l10n.predefinedPromptReportTemplate,
        isPredefined: true,
      ),
      Prompt(
        id: 'predefined_controversy_analysis',
        name: l10n.predefinedPromptControversyName,
        template: l10n.predefinedPromptControversyTemplate,
        isPredefined: true,
      ),
    ];
  }

  /// Initialize the Hive box
  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Open the Hive boxes
      _customPromptsBox = await Hive.openBox<Prompt>(_customPromptsBoxName);
      _usageStatsBox = await Hive.openBox(_usageStatsBoxName);

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error opening Hive boxes: $e');
      // If boxes are corrupted, try to delete and recreate them
      try {
        debugPrint('Attempting to delete corrupted boxes...');
        await Hive.deleteBoxFromDisk(_customPromptsBoxName);
        await Hive.deleteBoxFromDisk(_usageStatsBoxName);

        // Retry opening
        _customPromptsBox = await Hive.openBox<Prompt>(_customPromptsBoxName);
        _usageStatsBox = await Hive.openBox(_usageStatsBoxName);

        _isInitialized = true;
        debugPrint('Successfully recreated boxes after corruption');
      } catch (retryError) {
        debugPrint('Failed to recover from corruption: $retryError');
        rethrow;
      }
    }
  }

  void _ensureInitialized() {
    if (!_isInitialized || _customPromptsBox == null) {
      throw StateError('PromptService not initialized. Call initialize() first.');
    }
  }

  @override
  List<Prompt> getPredefinedPrompts(AppLocalizations l10n) {
    return List.unmodifiable(_getLocalizedPredefinedPrompts(l10n));
  }

  @override
  Future<List<Prompt>> getCustomPrompts() async {
    _ensureInitialized();

    try {
      return _customPromptsBox!.values.toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<Prompt>> getAllPrompts(AppLocalizations l10n) async {
    final customPrompts = await getCustomPrompts();
    return [...customPrompts, ..._getLocalizedPredefinedPrompts(l10n)];
  }

  @override
  Future<void> saveCustomPrompt(Prompt prompt) async {
    _ensureInitialized();

    if (prompt.isPredefined) {
      throw ArgumentError('Cannot save predefined prompts');
    }

    // Hive uses the ID as the key, so put will update if exists or add if new
    await _customPromptsBox!.put(prompt.id, prompt);
  }

  @override
  Future<void> deleteCustomPrompt(String promptId) async {
    _ensureInitialized();

    final prompt = _customPromptsBox!.get(promptId);
    if (prompt == null) {
      throw ArgumentError('Prompt not found');
    }

    if (prompt.isPredefined) {
      throw ArgumentError('Cannot delete predefined prompts');
    }

    await _customPromptsBox!.delete(promptId);
  }

  @override
  Future<Prompt?> getPromptById(String id, AppLocalizations l10n) async {
    final allPrompts = await getAllPrompts(l10n);
    try {
      return allPrompts.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Applies the prompt template to the transcription text
  /// If the template doesn't contain {transcription} or [[transcription]], it will be automatically appended
  @override
  String applyPromptTemplate(String template, String transcription) {
    // If template contains placeholder (either format), replace it
    if (template.contains('{transcription}')) {
      return template.replaceAll('{transcription}', transcription);
    }
    if (template.contains('[[transcription]]')) {
      return template.replaceAll('[[transcription]]', transcription);
    }

    // Otherwise, auto-inject transcription at the end
    return '$template\n\n$transcription';
  }

  /// Increment usage count for a prompt
  @override
  Future<void> incrementPromptUsage(String promptId) async {
    _ensureInitialized();

    final countKey = '${promptId}_count';
    final lastUsedKey = '${promptId}_lastUsed';

    final currentCount = _usageStatsBox!.get(countKey, defaultValue: 0) as int;
    await _usageStatsBox!.put(countKey, currentCount + 1);
    await _usageStatsBox!.put(lastUsedKey, DateTime.now().toIso8601String());
  }

  /// Get usage count for a prompt
  @override
  Future<int> getPromptUsageCount(String promptId) async {
    _ensureInitialized();

    final countKey = '${promptId}_count';
    return _usageStatsBox!.get(countKey, defaultValue: 0) as int;
  }

  /// Get last used time for a prompt
  @override
  Future<DateTime?> getPromptLastUsed(String promptId) async {
    _ensureInitialized();

    final lastUsedKey = '${promptId}_lastUsed';
    final lastUsedStr = _usageStatsBox!.get(lastUsedKey) as String?;
    if (lastUsedStr == null) return null;
    return DateTime.parse(lastUsedStr);
  }

  /// Get prompts with usage stats populated
  /// Optimized to batch-load usage stats instead of N+1 queries
  /// Returns prompts with default usage stats if not initialized
  Future<List<Prompt>> getPromptsWithUsageStats(List<Prompt> prompts) async {
    // If not initialized, return prompts with default usage stats
    if (!_isInitialized || _usageStatsBox == null) {
      return prompts.map((prompt) => prompt.copyWith(
        usageCount: 0,
        lastUsedAt: null,
      )).toList();
    }

    // Batch load all usage stats at once
    final usageStatsMap = <String, Map<String, dynamic>>{};
    for (final prompt in prompts) {
      final countKey = 'count_${prompt.id}';
      final lastUsedKey = 'last_used_${prompt.id}';

      usageStatsMap[prompt.id] = {
        'count': _usageStatsBox?.get(countKey, defaultValue: 0) ?? 0,
        'lastUsed': _usageStatsBox?.get(lastUsedKey),
      };
    }

    // Map prompts with their usage stats
    return prompts.map((prompt) {
      final stats = usageStatsMap[prompt.id]!;
      final lastUsedStr = stats['lastUsed'] as String?;

      return prompt.copyWith(
        usageCount: stats['count'] as int,
        lastUsedAt: lastUsedStr != null ? DateTime.parse(lastUsedStr) : null,
      );
    }).toList();
  }
}
