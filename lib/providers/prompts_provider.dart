import 'package:flutter/foundation.dart';
import '../models/prompt.dart';
import '../services/prompt_service.dart';
import '../generated/app_localizations.dart';

/// Provider for prompts state management
/// Wraps PromptService and provides reactive state updates
class PromptsProvider with ChangeNotifier {
  final PromptService _promptService;

  List<Prompt> _customPrompts = [];
  bool _isInitialized = false;
  bool _isLoading = false;

  /// Cache for sorted custom prompts
  List<Prompt>? _cachedSortedCustom;

  /// Predefined prompt IDs for checking if a prompt is predefined
  static const List<String> _predefinedPromptIds = [
    'predefined_questions',
    'predefined_action_items',
    'predefined_summary',
    'predefined_key_points',
    'predefined_decisions',
    'predefined_pro_contra',
    'predefined_report',
    'predefined_controversy_analysis',
  ];

  PromptsProvider(this._promptService);

  void _invalidateSortCache() {
    _cachedSortedCustom = null;
  }

  List<Prompt> _sortByUsageCount(List<Prompt> prompts) {
    final sorted = List<Prompt>.from(prompts);
    sorted.sort((a, b) => b.usageCount.compareTo(a.usageCount));
    return sorted;
  }

  /// Get predefined prompts (localized)
  List<Prompt> getPredefinedPrompts(AppLocalizations l10n) {
    return _promptService.getPredefinedPrompts(l10n);
  }

  /// Get custom prompts (sorted by usage)
  List<Prompt> get customPrompts {
    _cachedSortedCustom ??= List.unmodifiable(_sortByUsageCount(_customPrompts));
    return _cachedSortedCustom!;
  }

  /// Get all prompts (custom + predefined, localized)
  List<Prompt> getAllPrompts(AppLocalizations l10n) {
    final custom = customPrompts;
    final predefined = getPredefinedPrompts(l10n);
    return [...custom, ...predefined];
  }

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;

  /// Initialize prompts from storage on app startup
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Initialize the prompt service (opens Hive box and migrates data)
      await _promptService.initialize();
      _isInitialized = true;

      // Load custom prompts with usage stats
      final custom = await _promptService.getCustomPrompts();
      _customPrompts = await _promptService.getPromptsWithUsageStats(custom);
      _invalidateSortCache();
    } catch (e, stackTrace) {
      debugPrint('Error initializing prompts: $e');
      debugPrint('Stack trace: $stackTrace');

      // Try to initialize the service if it failed
      try {
        await _promptService.initialize();
        _isInitialized = true;
      } catch (initError) {
        debugPrint('Failed to initialize prompt service: $initError');
      }

      _customPrompts = [];
      _invalidateSortCache();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new custom prompt
  Future<void> addPrompt(Prompt prompt) async {
    if (!_isInitialized) {
      throw StateError('PromptsProvider not initialized. Call initialize() first.');
    }
    await _promptService.saveCustomPrompt(prompt);
    await _reloadCustomPrompts();
  }

  /// Update an existing custom prompt
  Future<void> updatePrompt(Prompt prompt) async {
    if (_isPredefined(prompt.id)) {
      throw Exception('Cannot update predefined prompts');
    }

    await _promptService.saveCustomPrompt(prompt);
    await _reloadCustomPrompts();
  }

  /// Delete a custom prompt
  Future<void> deletePrompt(String id) async {
    if (_isPredefined(id)) {
      throw Exception('Cannot delete predefined prompts');
    }

    await _promptService.deleteCustomPrompt(id);
    _customPrompts.removeWhere((prompt) => prompt.id == id);
    _invalidateSortCache();
    notifyListeners();
  }

  /// Get a prompt by ID (localized)
  Prompt? getPromptById(String id, AppLocalizations l10n) {
    try {
      return getAllPrompts(l10n).firstWhere((prompt) => prompt.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Check if a prompt is predefined (cannot be modified/deleted)
  bool _isPredefined(String id) {
    return _predefinedPromptIds.contains(id);
  }

  /// Check if a prompt is predefined (public method)
  bool isPredefinedPrompt(String id) {
    return _isPredefined(id);
  }

  /// Reload custom prompts from storage
  Future<void> _reloadCustomPrompts() async {
    final custom = await _promptService.getCustomPrompts();
    _customPrompts = await _promptService.getPromptsWithUsageStats(custom);
    _invalidateSortCache();
    notifyListeners();
  }

  /// Force refresh all prompts from storage
  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _reloadCustomPrompts();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Increment usage count for a prompt
  Future<void> incrementUsage(String promptId) async {
    await _promptService.incrementPromptUsage(promptId);
    await _reloadCustomPrompts();
    notifyListeners();
  }

  /// Apply a prompt template by replacing placeholders with input text
  /// Accepts either a Prompt object or a template string
  String applyPromptTemplate(dynamic promptOrTemplate, String inputText) {
    final template = promptOrTemplate is Prompt
        ? promptOrTemplate.template
        : promptOrTemplate as String;
    return _promptService.applyPromptTemplate(template, inputText);
  }
}
