// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transcription_history.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TranscriptionHistoryAdapter extends TypeAdapter<TranscriptionHistory> {
  @override
  final int typeId = 2;

  @override
  TranscriptionHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TranscriptionHistory(
      id: fields[0] as String?,
      audioFileName: fields[1] as String,
      transcription: fields[2] as TranscriptionResult?,
      promptResults: (fields[3] as List?)?.cast<PromptResult>(),
      createdAt: fields[4] as DateTime?,
      splitJobId: fields[5] as String?,
      isSplitTranscription: fields[6] as bool,
      waveform: (fields[8] as List?)?.cast<double>(),
      audioPath: fields[9] as String?,
      chatMessages: (fields[10] as List?)?.cast<ChatMessage>(),
    );
  }

  @override
  void write(BinaryWriter writer, TranscriptionHistory obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.audioFileName)
      ..writeByte(2)
      ..write(obj.transcription)
      ..writeByte(3)
      ..write(obj.promptResults)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.splitJobId)
      ..writeByte(6)
      ..write(obj.isSplitTranscription)
      ..writeByte(7)
      ..write(obj._durationMs)
      ..writeByte(8)
      ..write(obj.waveform)
      ..writeByte(9)
      ..write(obj.audioPath)
      ..writeByte(10)
      ..write(obj.chatMessages);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TranscriptionHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
