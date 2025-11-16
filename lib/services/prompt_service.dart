import 'package:hive_flutter/hive_flutter.dart';
import '../models/prompt.dart';

/// Interface for prompt management operations
/// Following Interface Segregation Principle (ISP)
abstract class IPromptService {
  Future<void> initialize();
  Future<List<Prompt>> getAllPrompts();
  Future<List<Prompt>> getCustomPrompts();
  List<Prompt> getPredefinedPrompts();
  Future<void> saveCustomPrompt(Prompt prompt);
  Future<void> deleteCustomPrompt(String promptId);
  Future<Prompt?> getPromptById(String id);
  String applyPromptTemplate(String template, String transcription);
}

/// Service for managing prompt templates
/// Single Responsibility Principle (SRP): Only handles prompt storage and retrieval
class PromptService implements IPromptService {
  static const String _customPromptsBoxName = 'custom_prompts';

  Box<Prompt>? _customPromptsBox;
  bool _isInitialized = false;

  /// Predefined prompts that cannot be deleted
  static final List<Prompt> _predefinedPrompts = [
    Prompt(
      id: 'predefined_questions',
      name: 'Fragen generieren',
      template: 'Generiere Verständnisfragen zum folgenden Text:\n\n{transcription}',
      isPredefined: true,
    ),
    Prompt(
      id: 'predefined_action_items',
      name: 'Action Items',
      template: 'Extrahiere alle Aufgaben und To-Dos aus dem folgenden Text:\n\n{transcription}',
      isPredefined: true,
    ),
    Prompt(
      id: 'predefined_summary',
      name: 'Zusammenfassen',
      template: 'Fasse den folgenden Text kurz und prägnant zusammen:\n\n{transcription}',
      isPredefined: true,
    ),
    Prompt(
      id: 'predefined_key_points',
      name: 'Wichtige Punkte',
      template: 'Liste die wichtigsten Punkte aus dem folgenden Text auf:\n\n{transcription}',
      isPredefined: true,
    ),
  ];

  /// Initialize the Hive box
  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Open the Hive box
    _customPromptsBox = await Hive.openBox<Prompt>(_customPromptsBoxName);

    _isInitialized = true;
  }

  void _ensureInitialized() {
    if (!_isInitialized || _customPromptsBox == null) {
      throw StateError('PromptService not initialized. Call initialize() first.');
    }
  }

  @override
  List<Prompt> getPredefinedPrompts() {
    return List.unmodifiable(_predefinedPrompts);
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
  Future<List<Prompt>> getAllPrompts() async {
    final customPrompts = await getCustomPrompts();
    return [...customPrompts, ..._predefinedPrompts];
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
  Future<Prompt?> getPromptById(String id) async {
    final allPrompts = await getAllPrompts();
    try {
      return allPrompts.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Applies the prompt template to the transcription text
  /// If the template doesn't contain {transcription}, it will be automatically appended
  @override
  String applyPromptTemplate(String template, String transcription) {
    // If template contains placeholder, replace it
    if (template.contains('{transcription}')) {
      return template.replaceAll('{transcription}', transcription);
    }

    // Otherwise, auto-inject transcription at the end
    return '$template\n\n$transcription';
  }
}
