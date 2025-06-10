// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'editHistory.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EditHistoryAdapter extends TypeAdapter<EditHistory> {
  @override
  final int typeId = 0;

  @override
  EditHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EditHistory(
      imageId: fields[1] as int,
      operationType: fields[2] as String,
      operationParameters: (fields[3] as Map).cast<String, dynamic>(),
      operationDate: fields[4] as DateTime,
      snapshotPath: fields[5] as String?,
      snapshotBytes: (fields[6] as List?)?.cast<int>(),
    );
  }

  @override
  void write(BinaryWriter writer, EditHistory obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.imageId)
      ..writeByte(1)
      ..write(obj.operationType)
      ..writeByte(2)
      ..write(obj.operationParameters)
      ..writeByte(3)
      ..write(obj.operationDate)
      ..writeByte(4)
      ..write(obj.snapshotPath)
      ..writeByte(5)
      ..write(obj.snapshotBytes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EditHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
