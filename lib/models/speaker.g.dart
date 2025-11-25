// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'speaker.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SpeakerAdapter extends TypeAdapter<Speaker> {
  @override
  final int typeId = 10;

  @override
  Speaker read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Speaker(
      label: fields[0] as String,
      color: fields[1] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Speaker obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.label)
      ..writeByte(1)
      ..write(obj.color);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpeakerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
