import 'package:flutter/foundation.dart';
import '../models/prompt.dart';
import '../services/prompt_service.dart';

/// Provider for prompts state management
/// Wraps PromptService and provides reactive state updates
class PromptsProvider with ChangeNotifier {
  final PromptService _promptService;

  List<Prompt> _predefinedPrompts = [];
  List<Prompt> _customPrompts = [];
  bool _isInitialized = false;
  bool _isLoading = false;

  PromptsProvider(this._promptService);

  // Getters - sorted by usage count (descending)
  List<Prompt> get predefinedPrompts {
    final sorted = List<Prompt>.from(_predefinedPrompts);
    sorted.sort((a, b) => b.usageCount.compareTo(a.usageCount));
    return List.unmodifiable(sorted);
  }

  List<Prompt> get customPrompts {
    final sorted = List<Prompt>.from(_customPrompts);
    sorted.sort((a, b) => b.usageCount.compareTo(a.usageCount));
    return List.unmodifiable(sorted);
  }

  List<Prompt> get allPrompts {
    final custom = List<Prompt>.from(_customPrompts);
    final predefined = List<Prompt>.from(_predefinedPrompts);
    custom.sort((a, b) => b.usageCount.compareTo(a.usageCount));
    predefined.sort((a, b) => b.usageCount.compareTo(a.usageCount));
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

      // Load prompts with usage stats
      final predefined = _promptService.getPredefinedPrompts();
      final custom = await _promptService.getCustomPrompts();

      _predefinedPrompts = await _promptService.getPromptsWithUsageStats(predefined);
      _customPrompts = await _promptService.getPromptsWithUsageStats(custom);

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing prompts: $e');
      _predefinedPrompts = [];
      _customPrompts = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new custom prompt
  Future<void> addPrompt(Prompt prompt) async {
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
    notifyListeners();
  }

  /// Get a prompt by ID
  Prompt? getPromptById(String id) {
    try {
      return allPrompts.firstWhere((prompt) => prompt.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Check if a prompt is predefined (cannot be modified/deleted)
  bool _isPredefined(String id) {
    return _predefinedPrompts.any((prompt) => prompt.id == id);
  }

  /// Check if a prompt is predefined (public method)
  bool isPredefinedPrompt(String id) {
    return _isPredefined(id);
  }

  /// Reload custom prompts from storage
  Future<void> _reloadCustomPrompts() async {
    final custom = await _promptService.getCustomPrompts();
    _customPrompts = await _promptService.getPromptsWithUsageStats(custom);
    notifyListeners();
  }

  /// Force refresh all prompts from storage
  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();

    try {
      final predefined = _promptService.getPredefinedPrompts();
      final custom = await _promptService.getCustomPrompts();

      _predefinedPrompts = await _promptService.getPromptsWithUsageStats(predefined);
      _customPrompts = await _promptService.getPromptsWithUsageStats(custom);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Increment usage count for a prompt
  Future<void> incrementUsage(String promptId) async {
    await _promptService.incrementPromptUsage(promptId);

    // Reload prompts to get updated usage stats
    final predefined = _promptService.getPredefinedPrompts();
    final custom = await _promptService.getCustomPrompts();

    _predefinedPrompts = await _promptService.getPromptsWithUsageStats(predefined);
    _customPrompts = await _promptService.getPromptsWithUsageStats(custom);

    notifyListeners();
  }
}
