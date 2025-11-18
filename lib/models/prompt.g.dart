// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prompt.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PromptAdapter extends TypeAdapter<Prompt> {
  @override
  final int typeId = 4;

  @override
  Prompt read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Prompt(
      id: fields[0] as String,
      name: fields[1] as String,
      template: fields[2] as String,
      isPredefined: fields[3] as bool,
      createdAt: fields[4] as DateTime?,
      usageCount: (fields[5] as int?) ?? 0,
      lastUsedAt: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Prompt obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.template)
      ..writeByte(3)
      ..write(obj.isPredefined)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.usageCount)
      ..writeByte(6)
      ..write(obj.lastUsedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PromptAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
