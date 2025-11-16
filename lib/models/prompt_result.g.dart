// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prompt_result.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PromptResultAdapter extends TypeAdapter<PromptResult> {
  @override
  final int typeId = 1;

  @override
  PromptResult read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PromptResult(
      id: fields[0] as String?,
      promptName: fields[1] as String,
      promptTemplate: fields[2] as String,
      transcriptionText: fields[3] as String,
      llmResponse: fields[4] as String,
      modelUsed: fields[5] as String,
      timestamp: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, PromptResult obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.promptName)
      ..writeByte(2)
      ..write(obj.promptTemplate)
      ..writeByte(3)
      ..write(obj.transcriptionText)
      ..writeByte(4)
      ..write(obj.llmResponse)
      ..writeByte(5)
      ..write(obj.modelUsed)
      ..writeByte(6)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PromptResultAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
