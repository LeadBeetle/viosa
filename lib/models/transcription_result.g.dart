// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transcription_result.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TranscriptionResultAdapter extends TypeAdapter<TranscriptionResult> {
  @override
  final int typeId = 0;

  @override
  TranscriptionResult read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TranscriptionResult(
      text: fields[0] as String,
      language: fields[1] as String,
      modelUsed: fields[2] as String,
      timestamp: fields[3] as DateTime,
      speakers: (fields[4] as List?)?.cast<Speaker>(),
      segments: (fields[5] as List?)?.cast<TranscriptSegment>(),
    );
  }

  @override
  void write(BinaryWriter writer, TranscriptionResult obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.text)
      ..writeByte(1)
      ..write(obj.language)
      ..writeByte(2)
      ..write(obj.modelUsed)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.speakers)
      ..writeByte(5)
      ..write(obj.segments);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TranscriptionResultAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
