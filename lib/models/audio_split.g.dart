// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio_split.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AudioSplitAdapter extends TypeAdapter<AudioSplit> {
  @override
  final int typeId = 6;

  @override
  AudioSplit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AudioSplit(
      id: fields[0] as String,
      index: fields[1] as int,
      filePath: fields[2] as String,
      startTimeMs: fields[3] as int,
      endTimeMs: fields[4] as int,
      size: fields[5] as int,
      mimeType: fields[6] as String,
      status: fields[7] as SplitStatus,
      attemptCount: fields[8] as int,
      transcriptionText: fields[9] as String?,
      errorMessage: fields[10] as String?,
      completedAt: fields[11] as DateTime?,
      segments: (fields[12] as List?)?.cast<TranscriptSegment>(),
      detectedLanguage: fields[13] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AudioSplit obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.index)
      ..writeByte(2)
      ..write(obj.filePath)
      ..writeByte(3)
      ..write(obj.startTimeMs)
      ..writeByte(4)
      ..write(obj.endTimeMs)
      ..writeByte(5)
      ..write(obj.size)
      ..writeByte(6)
      ..write(obj.mimeType)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.attemptCount)
      ..writeByte(9)
      ..write(obj.transcriptionText)
      ..writeByte(10)
      ..write(obj.errorMessage)
      ..writeByte(11)
      ..write(obj.completedAt)
      ..writeByte(12)
      ..write(obj.segments)
      ..writeByte(13)
      ..write(obj.detectedLanguage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioSplitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SplitStatusAdapter extends TypeAdapter<SplitStatus> {
  @override
  final int typeId = 5;

  @override
  SplitStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SplitStatus.pending;
      case 1:
        return SplitStatus.processing;
      case 2:
        return SplitStatus.completed;
      case 3:
        return SplitStatus.failed;
      default:
        return SplitStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, SplitStatus obj) {
    switch (obj) {
      case SplitStatus.pending:
        writer.writeByte(0);
        break;
      case SplitStatus.processing:
        writer.writeByte(1);
        break;
      case SplitStatus.completed:
        writer.writeByte(2);
        break;
      case SplitStatus.failed:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SplitStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
