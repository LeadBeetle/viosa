import '../models/chat_message.dart';
import 'i_chat_service.dart';
import 'completion/i_completion_service.dart';
import 'completion/completion_service_factory.dart';

/// Implementation of the chat service
/// Handles conversation with LLM using transcription context
class ChatService implements IChatService {
  static final _mentionPattern = RegExp(r'@(\w+)');

  @override
  Stream<String> sendMessageStreaming({
    required String apiKey,
    required String model,
    required String userMessage,
    required List<ChatMessage> history,
    required ChatContext context,
  }) async* {
    final completionService = CompletionServiceFactory.create(model: model);

    // Build messages list
    final messages = <CompletionMessage>[];

    // Add system prompt with context
    messages.add(CompletionMessage(
      role: 'system',
      content: context.buildSystemPrompt(),
    ));

    // Add conversation history
    for (final msg in history) {
      messages.add(CompletionMessage(
        role: msg.role,
        content: msg.content,
      ));
    }

    // Process user message - resolve @ mentions
    final processedMessage = _processUserMessage(userMessage, context);

    // Add current user message
    messages.add(CompletionMessage(
      role: 'user',
      content: processedMessage,
    ));

    // Stream the response
    yield* completionService.completeStreaming(
      apiKey: apiKey,
      messages: messages,
      config: const CompletionConfig(
        maxTokens: 4000,
        temperature: 0.7,
      ),
    );
  }

  String _processUserMessage(String message, ChatContext context) {
    // Find all @ mentions and add context hints
    final mentions = parseMentions(message);

    if (mentions.isEmpty) {
      return message;
    }

    // Add a hint about which contexts are being referenced
    final referencedContexts = <String>[];
    for (final mention in mentions) {
      if (mention == 'Transkript' &&
          context.enabledContexts.contains('transcription')) {
        referencedContexts.add('Transkript');
      } else if (context.promptResults.containsKey(mention)) {
        referencedContexts.add(mention);
      }
    }

    if (referencedContexts.isNotEmpty) {
      return '$message\n\n[Referenzierte Kontexte: ${referencedContexts.join(', ')}]';
    }

    return message;
  }

  @override
  Set<String> parseMentions(String message) {
    final matches = _mentionPattern.allMatches(message);
    return matches.map((m) => m.group(1)!).toSet();
  }

  @override
  String getContextDisplayName(String contextKey) {
    if (contextKey == 'transcription') {
      return 'Transkript';
    }
    return contextKey;
  }
}
