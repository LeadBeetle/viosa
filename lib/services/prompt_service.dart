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

  /// Predefined prompts that cannot be deleted
  static final List<Prompt> _predefinedPrompts = [
    Prompt(
      id: 'predefined_questions',
      name: 'Fragen generieren',
      template: '''Generiere 5-7 Verständnisfragen zum folgenden Text. Die Fragen sollen:
- Verschiedene Schwierigkeitsgrade abdecken (einfach bis anspruchsvoll)
- Sowohl Fakten als auch Zusammenhänge abfragen
- Klar und präzise formuliert sein

Text:
{transcription}''',
      isPredefined: true,
    ),
    Prompt(
      id: 'predefined_action_items',
      name: 'Action Items',
      template: '''Extrahiere alle Aufgaben und To-Dos aus dem folgenden Text.

Formatiere die Ausgabe als strukturierte Liste:
- Gruppiere nach Thema oder Verantwortlichkeit (falls erkennbar)
- Markiere Deadlines oder Fristen (falls erwähnt)
- Priorisiere nach Dringlichkeit (falls ableitbar)

Falls keine konkreten Aufgaben erkennbar sind, gib dies an.

Text:
{transcription}''',
      isPredefined: true,
    ),
    Prompt(
      id: 'predefined_summary',
      name: 'Zusammenfassen',
      template: '''Erstelle eine ausführliche und detaillierte Zusammenfassung des folgenden Textes.

Die Zusammenfassung soll:
- Strukturiert in thematische Abschnitte gegliedert sein
- Alle wesentlichen Inhalte, Argumente und Erkenntnisse erfassen
- Den Kontext, Zweck und die Schlussfolgerungen des Gesprächs/Textes verdeutlichen
- Wichtige Details und Nuancen beibehalten

Verwende Überschriften und Absätze für bessere Lesbarkeit.

Text:
{transcription}''',
      isPredefined: true,
    ),
    Prompt(
      id: 'predefined_key_points',
      name: 'Wichtige Punkte',
      template: '''Liste die wichtigsten Punkte aus dem folgenden Text auf.

Für jeden Punkt:
- Formuliere eine klare Hauptaussage
- Ergänze relevante Details, Begründungen oder Kontext
- Erkläre die Bedeutung oder Implikation des Punktes

Achte auf:
- Maximal 5-10 Punkte
- Priorisierung nach Relevanz

Text:
{transcription}''',
      isPredefined: true,
    ),
    Prompt(
      id: 'predefined_decisions',
      name: 'Entscheidungen',
      template: '''Extrahiere alle Entscheidungen aus dem folgenden Text.

Für jede Entscheidung:
- Was wurde entschieden?
- Warum wurde so entschieden? (Begründung/Argumente)
- Wer ist verantwortlich? (falls erkennbar)
- Bis wann? (falls erwähnt)

Falls keine klaren Entscheidungen getroffen wurden, liste die offenen Diskussionspunkte und ausstehenden Klärungen auf.

Text:
{transcription}''',
      isPredefined: true,
    ),
    Prompt(
      id: 'predefined_pro_contra',
      name: 'Pro & Contra',
      template: '''Analysiere den folgenden Text und erstelle eine Pro & Contra Analyse.

Struktur:
- Thema oder Fragestellung identifizieren
- Pro-Argumente mit Begründungen auflisten
- Contra-Argumente mit Begründungen auflisten
- Fazit oder Tendenz zusammenfassen (falls aus dem Gespräch erkennbar)

Text:
{transcription}''',
      isPredefined: true,
    ),
    Prompt(
      id: 'predefined_report',
      name: 'Bericht erstellen',
      template: '''Erstelle einen formellen Bericht basierend auf dem folgenden Text.

Struktur:
- Titel und Datum/Anlass (falls erkennbar)
- Einleitung: Kontext und Zweck
- Hauptteil: Besprochene Themen mit Kernaussagen und Details
- Ergebnisse: Getroffene Entscheidungen und Vereinbarungen
- Ausblick: Nächste Schritte und offene Punkte

Verwende einen sachlichen, professionellen Stil.

Text:
{transcription}''',
      isPredefined: true,
    ),
    Prompt(
      id: 'predefined_controversy_analysis',
      name: 'Kontroversen vertiefen',
      template: '''Identifiziere kontroverse oder strittige Punkte aus dem folgenden Text und analysiere diese tiefgehend.

Für jeden kontroversen Punkt:
- Beschreibe den Streitpunkt und die verschiedenen Standpunkte
- Analysiere die vorgebrachten Argumente jeder Seite
- Ergänze wichtige Aspekte, die in der Diskussion zu kurz kamen oder fehlten
- Liefere zusätzliche Fakten, Perspektiven oder Gegenargumente zur Vertiefung
- Gib eine ausgewogene Einschätzung

Ziel ist es, eine fundierte Grundlage für die weitere Meinungsbildung zu schaffen.

Text:
{transcription}''',
      isPredefined: true,
    ),
  ];

  /// Initialize the Hive box
  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Open the Hive boxes
    _customPromptsBox = await Hive.openBox<Prompt>(_customPromptsBoxName);
    _usageStatsBox = await Hive.openBox(_usageStatsBoxName);

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
  Future<List<Prompt>> getPromptsWithUsageStats(List<Prompt> prompts) async {
    _ensureInitialized();

    final List<Prompt> result = [];
    for (final prompt in prompts) {
      final usageCount = await getPromptUsageCount(prompt.id);
      final lastUsedAt = await getPromptLastUsed(prompt.id);
      result.add(prompt.copyWith(
        usageCount: usageCount,
        lastUsedAt: lastUsedAt,
      ));
    }
    return result;
  }
}
