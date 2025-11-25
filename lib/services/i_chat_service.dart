import '../models/chat_message.dart';

/// Context for chat conversations containing transcription and prompt results
class ChatContext {
  final String? transcription;
  final Map<String, String> promptResults; // promptName -> llmResponse
  final Set<String> enabledContexts;

  const ChatContext({
    this.transcription,
    this.promptResults = const {},
    this.enabledContexts = const {'transcription'},
  });

  /// Build the system prompt based on enabled contexts
  String buildSystemPrompt() {
    final buffer = StringBuffer();
    buffer.writeln(
        'Du bist ein hilfreicher Assistent für die Analyse von Audio-Transkriptionen.');
    buffer.writeln(
        'Du hilfst dem Benutzer, Informationen aus dem Transkript und den Analyseergebnissen zu verstehen und weiterzuverarbeiten.');
    buffer.writeln('Antworte präzise und auf Deutsch.');

    if (enabledContexts.contains('transcription') && transcription != null) {
      buffer.writeln('\n--- Transkript ---');
      buffer.writeln(transcription);
    }

    for (final entry in promptResults.entries) {
      if (enabledContexts.contains(entry.key)) {
        buffer.writeln('\n--- ${entry.key} ---');
        buffer.writeln(entry.value);
      }
    }

    return buffer.toString();
  }

  /// Get list of all available context keys
  List<String> get availableContexts {
    final contexts = <String>[];
    if (transcription != null) {
      contexts.add('transcription');
    }
    contexts.addAll(promptResults.keys);
    return contexts;
  }

  ChatContext copyWith({
    String? transcription,
    Map<String, String>? promptResults,
    Set<String>? enabledContexts,
  }) {
    return ChatContext(
      transcription: transcription ?? this.transcription,
      promptResults: promptResults ?? this.promptResults,
      enabledContexts: enabledContexts ?? this.enabledContexts,
    );
  }
}

/// Interface for chat services
/// Follows Single Responsibility Principle (SRP)
abstract class IChatService {
  /// Send a message and receive a streaming response
  Stream<String> sendMessageStreaming({
    required String apiKey,
    required String model,
    required String userMessage,
    required List<ChatMessage> history,
    required ChatContext context,
  });

  /// Parse @ mentions from user message and return referenced context keys
  Set<String> parseMentions(String message);

  /// Get display name for a context key
  String getContextDisplayName(String contextKey);
}
