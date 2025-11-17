// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'split_transcription_job.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SplitTranscriptionJobAdapter extends TypeAdapter<SplitTranscriptionJob> {
  @override
  final int typeId = 8;

  @override
  SplitTranscriptionJob read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SplitTranscriptionJob(
      id: fields[0] as String,
      originalAudioPath: fields[1] as String,
      originalFileName: fields[2] as String,
      totalSplits: fields[3] as int,
      splits: (fields[4] as List).cast<AudioSplit>(),
      language: fields[5] as String,
      createdAt: fields[6] as DateTime,
      status: fields[7] as JobStatus,
      completedCount: fields[8] as int,
      failedCount: fields[9] as int,
      completedAt: fields[10] as DateTime?,
      lastUpdatedAt: fields[11] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, SplitTranscriptionJob obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.originalAudioPath)
      ..writeByte(2)
      ..write(obj.originalFileName)
      ..writeByte(3)
      ..write(obj.totalSplits)
      ..writeByte(4)
      ..write(obj.splits)
      ..writeByte(5)
      ..write(obj.language)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.completedCount)
      ..writeByte(9)
      ..write(obj.failedCount)
      ..writeByte(10)
      ..write(obj.completedAt)
      ..writeByte(11)
      ..write(obj.lastUpdatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SplitTranscriptionJobAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class JobStatusAdapter extends TypeAdapter<JobStatus> {
  @override
  final int typeId = 7;

  @override
  JobStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return JobStatus.queued;
      case 1:
        return JobStatus.processing;
      case 2:
        return JobStatus.completed;
      case 3:
        return JobStatus.partialFailure;
      case 4:
        return JobStatus.cancelled;
      default:
        return JobStatus.queued;
    }
  }

  @override
  void write(BinaryWriter writer, JobStatus obj) {
    switch (obj) {
      case JobStatus.queued:
        writer.writeByte(0);
        break;
      case JobStatus.processing:
        writer.writeByte(1);
        break;
      case JobStatus.completed:
        writer.writeByte(2);
        break;
      case JobStatus.partialFailure:
        writer.writeByte(3);
        break;
      case JobStatus.cancelled:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JobStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
