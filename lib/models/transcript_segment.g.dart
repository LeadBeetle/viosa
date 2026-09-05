// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transcript_segment.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TranscriptSegmentAdapter extends TypeAdapter<TranscriptSegment> {
  @override
  final int typeId = 9;

  @override
  TranscriptSegment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TranscriptSegment(
      startMs: fields[0] as int,
      endMs: fields[1] as int,
      text: fields[2] as String,
      speaker: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TranscriptSegment obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.startMs)
      ..writeByte(1)
      ..write(obj.endMs)
      ..writeByte(2)
      ..write(obj.text)
      ..writeByte(3)
      ..write(obj.speaker);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TranscriptSegmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
