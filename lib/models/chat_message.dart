import 'package:hive/hive.dart';

part 'chat_message.g.dart';

/// Data model for a chat message
/// Used for conversations based on transcription results
@HiveType(typeId: 11)
class ChatMessage {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String role; // 'user' | 'assistant'

  @HiveField(2)
  final String content;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final List<String>? referencedContexts; // ['transcription', 'Zusammenfassung']

  ChatMessage({
    String? id,
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.referencedContexts,
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        timestamp = timestamp ?? DateTime.now();

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      referencedContexts: (json['referencedContexts'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'referencedContexts': referencedContexts,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? role,
    String? content,
    DateTime? timestamp,
    List<String>? referencedContexts,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      referencedContexts: referencedContexts ?? this.referencedContexts,
    );
  }

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
}
