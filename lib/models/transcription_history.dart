import 'package:hive/hive.dart';
import 'transcription_result.dart';
import 'prompt_result.dart';
import 'chat_message.dart';

part 'transcription_history.g.dart';

/// Data model for transcription history entry
/// Follows Single Responsibility Principle (SRP)
@HiveType(typeId: 2)
class TranscriptionHistory {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String audioFileName;

  @HiveField(2)
  final TranscriptionResult? transcription;

  @HiveField(3)
  final List<PromptResult> promptResults;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final String? splitJobId;

  @HiveField(6)
  final bool isSplitTranscription;

  @HiveField(7)
  final int? _durationMs; // Store as milliseconds for Hive

  @HiveField(8)
  final List<double>? waveform;

  @HiveField(9)
  final String? audioPath;

  @HiveField(10)
  final List<ChatMessage>? chatMessages;

  // Getter to convert milliseconds to Duration
  Duration? get duration => _durationMs != null ? Duration(milliseconds: _durationMs!) : null;

  // Getter for chat message count
  int get chatMessageCount => chatMessages?.length ?? 0;

  TranscriptionHistory({
    String? id,
    required this.audioFileName,
    this.transcription,
    List<PromptResult>? promptResults,
    DateTime? createdAt,
    this.splitJobId,
    this.isSplitTranscription = false,
    Duration? duration,
    this.waveform,
    this.audioPath,
    this.chatMessages,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        promptResults = promptResults ?? [],
        createdAt = createdAt ?? DateTime.now(),
        _durationMs = duration?.inMilliseconds;

  /// Creates history entry from JSON
  factory TranscriptionHistory.fromJson(Map<String, dynamic> json) {
    return TranscriptionHistory(
      id: json['id'] as String,
      audioFileName: json['audioFileName'] as String,
      transcription: json['transcription'] != null
          ? TranscriptionResult.fromJson(
              json['transcription'] as Map<String, dynamic>)
          : null,
      promptResults: (json['promptResults'] as List<dynamic>?)
              ?.map((e) => PromptResult.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      splitJobId: json['splitJobId'] as String?,
      isSplitTranscription: json['isSplitTranscription'] as bool? ?? false,
      duration: Duration(milliseconds: json['duration'] as int? ?? 0),
      waveform: (json['waveform'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      audioPath: json['audioPath'] as String?,
      chatMessages: (json['chatMessages'] as List<dynamic>?)
          ?.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Converts history entry to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'audioFileName': audioFileName,
      'transcription': transcription?.toJson(),
      'promptResults': promptResults.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'splitJobId': splitJobId,
      'isSplitTranscription': isSplitTranscription,
      'duration': duration?.inMilliseconds,
      'waveform': waveform,
      'audioPath': audioPath,
      'chatMessages': chatMessages?.map((e) => e.toJson()).toList(),
    };
  }

  /// Returns formatted creation timestamp
  String get formattedCreatedAt {
    return '${createdAt.year}-${_twoDigits(createdAt.month)}-${_twoDigits(createdAt.day)} '
        '${_twoDigits(createdAt.hour)}:${_twoDigits(createdAt.minute)}';
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  /// Creates a copy with updated fields
  TranscriptionHistory copyWith({
    String? id,
    String? audioFileName,
    TranscriptionResult? transcription,
    List<PromptResult>? promptResults,
    DateTime? createdAt,
    String? splitJobId,
    bool? isSplitTranscription,
    Duration? duration,
    List<double>? waveform,
    String? audioPath,
    List<ChatMessage>? chatMessages,
  }) {
    return TranscriptionHistory(
      id: id ?? this.id,
      audioFileName: audioFileName ?? this.audioFileName,
      transcription: transcription ?? this.transcription,
      promptResults: promptResults ?? this.promptResults,
      createdAt: createdAt ?? this.createdAt,
      splitJobId: splitJobId ?? this.splitJobId,
      isSplitTranscription: isSplitTranscription ?? this.isSplitTranscription,
      duration: duration ?? this.duration,
      waveform: waveform ?? this.waveform,
      audioPath: audioPath ?? this.audioPath,
      chatMessages: chatMessages ?? this.chatMessages,
    );
  }
}
