// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'objectsModels.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DrawingAdapter extends TypeAdapter<Drawing> {
  @override
  final int typeId = 1;

  @override
  Drawing read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Drawing(
      id: fields[0] as int?,
      imageId: fields[1] as int,
      drawingPath: fields[2] as String,
      color: fields[3] as String,
      strokeWidth: fields[4] as double,
      isDeleted: fields[5] as bool,
      historyId: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Drawing obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.imageId)
      ..writeByte(2)
      ..write(obj.drawingPath)
      ..writeByte(3)
      ..write(obj.color)
      ..writeByte(4)
      ..write(obj.strokeWidth)
      ..writeByte(5)
      ..write(obj.isDeleted)
      ..writeByte(6)
      ..write(obj.historyId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrawingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StickerAdapter extends TypeAdapter<Sticker> {
  @override
  final int typeId = 2;

  @override
  Sticker read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Sticker(
      id: fields[0] as int?,
      imageId: fields[1] as int,
      path: fields[2] as String,
      positionX: fields[3] as double,
      positionY: fields[4] as double,
      scale: fields[5] as double,
      rotation: fields[6] as double,
      historyId: fields[7] as int,
      isAsset: fields[8] as bool,
      isDeleted: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Sticker obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.imageId)
      ..writeByte(2)
      ..write(obj.path)
      ..writeByte(3)
      ..write(obj.positionX)
      ..writeByte(4)
      ..write(obj.positionY)
      ..writeByte(5)
      ..write(obj.scale)
      ..writeByte(6)
      ..write(obj.rotation)
      ..writeByte(7)
      ..write(obj.historyId)
      ..writeByte(8)
      ..write(obj.isAsset)
      ..writeByte(9)
      ..write(obj.isDeleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StickerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TextObjectAdapter extends TypeAdapter<TextObject> {
  @override
  final int typeId = 3;

  @override
  TextObject read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TextObject(
      id: fields[0] as int?,
      imageId: fields[1] as int,
      text: fields[2] as String,
      positionX: fields[3] as double,
      positionY: fields[4] as double,
      fontSize: fields[5] as double,
      fontWeight: fields[6] as String,
      fontStyle: fields[7] as String,
      alignment: fields[8] as String,
      color: fields[9] as String,
      fontFamily: fields[10] as String,
      scale: fields[11] as double,
      rotation: fields[12] as double,
      historyId: fields[13] as int?,
      isDeleted: fields[14] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, TextObject obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.imageId)
      ..writeByte(2)
      ..write(obj.text)
      ..writeByte(3)
      ..write(obj.positionX)
      ..writeByte(4)
      ..write(obj.positionY)
      ..writeByte(5)
      ..write(obj.fontSize)
      ..writeByte(6)
      ..write(obj.fontWeight)
      ..writeByte(7)
      ..write(obj.fontStyle)
      ..writeByte(8)
      ..write(obj.alignment)
      ..writeByte(9)
      ..write(obj.color)
      ..writeByte(10)
      ..write(obj.fontFamily)
      ..writeByte(11)
      ..write(obj.scale)
      ..writeByte(12)
      ..write(obj.rotation)
      ..writeByte(13)
      ..write(obj.historyId)
      ..writeByte(14)
      ..write(obj.isDeleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextObjectAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ImageDataAdapter extends TypeAdapter<ImageData> {
  @override
  final int typeId = 4;

  @override
  ImageData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ImageData(
      imageId: fields[0] as int?,
      filePath: fields[1] as String,
      fileName: fields[2] as String,
      fileSize: fields[3] as int,
      width: fields[4] as int,
      height: fields[5] as int,
      creationDate: fields[6] as DateTime,
      lastModified: fields[7] as DateTime,
      originalImageId: fields[8] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, ImageData obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.imageId)
      ..writeByte(1)
      ..write(obj.filePath)
      ..writeByte(2)
      ..write(obj.fileName)
      ..writeByte(3)
      ..write(obj.fileSize)
      ..writeByte(4)
      ..write(obj.width)
      ..writeByte(5)
      ..write(obj.height)
      ..writeByte(6)
      ..write(obj.creationDate)
      ..writeByte(7)
      ..write(obj.lastModified)
      ..writeByte(8)
      ..write(obj.originalImageId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FilterDataAdapter extends TypeAdapter<FilterData> {
  @override
  final int typeId = 5;

  @override
  FilterData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FilterData(
      filterId: fields[0] as int?,
      filterName: fields[1] as String,
      brightness: fields[2] as double,
      contrast: fields[3] as double,
      saturation: fields[4] as double,
      warmth: fields[5] as double,
      vignette: fields[6] as double,
    );
  }

  @override
  void write(BinaryWriter writer, FilterData obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.filterId)
      ..writeByte(1)
      ..write(obj.filterName)
      ..writeByte(2)
      ..write(obj.brightness)
      ..writeByte(3)
      ..write(obj.contrast)
      ..writeByte(4)
      ..write(obj.saturation)
      ..writeByte(5)
      ..write(obj.warmth)
      ..writeByte(6)
      ..write(obj.vignette);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FilterDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CollageDataAdapter extends TypeAdapter<CollageData> {
  @override
  final int typeId = 6;

  @override
  CollageData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CollageData(
      collageId: fields[0] as int?,
      templateName: fields[1] as String,
      width: fields[2] as int,
      height: fields[3] as int,
      fileSize: fields[4] as int,
      previewPath: fields[5] as String,
      creationDate: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CollageData obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.collageId)
      ..writeByte(1)
      ..write(obj.templateName)
      ..writeByte(2)
      ..write(obj.width)
      ..writeByte(3)
      ..write(obj.height)
      ..writeByte(4)
      ..write(obj.fileSize)
      ..writeByte(5)
      ..write(obj.previewPath)
      ..writeByte(6)
      ..write(obj.creationDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CollageDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CollageImageAdapter extends TypeAdapter<CollageImage> {
  @override
  final int typeId = 7;

  @override
  CollageImage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CollageImage(
      collageId: fields[0] as int,
      imageId: fields[1] as int,
      positionX: fields[2] as double,
      positionY: fields[3] as double,
      scale: fields[4] as double,
      rotation: fields[5] as double,
      zIndex: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, CollageImage obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.collageId)
      ..writeByte(1)
      ..write(obj.imageId)
      ..writeByte(2)
      ..write(obj.positionX)
      ..writeByte(3)
      ..write(obj.positionY)
      ..writeByte(4)
      ..write(obj.scale)
      ..writeByte(5)
      ..write(obj.rotation)
      ..writeByte(6)
      ..write(obj.zIndex);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CollageImageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CurrentStateAdapter extends TypeAdapter<CurrentState> {
  @override
  final int typeId = 8;

  @override
  CurrentState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CurrentState(
      imageId: fields[0] as int,
      lastHistoryId: fields[1] as int,
      currentSnapshotPath: fields[2] as String?,
      currentSnapshotBytes: (fields[3] as List?)?.cast<int>(),
    );
  }

  @override
  void write(BinaryWriter writer, CurrentState obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.imageId)
      ..writeByte(1)
      ..write(obj.lastHistoryId)
      ..writeByte(2)
      ..write(obj.currentSnapshotPath)
      ..writeByte(3)
      ..write(obj.currentSnapshotBytes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CurrentStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AdjustSettingsAdapter extends TypeAdapter<AdjustSettings> {
  @override
  final int typeId = 9;

  @override
  AdjustSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AdjustSettings(
      brightness: fields[0] as double,
      contrast: fields[1] as double,
      saturation: fields[2] as double,
      exposure: fields[3] as double,
      noise: fields[4] as double,
      smooth: fields[5] as double,
    );
  }

  @override
  void write(BinaryWriter writer, AdjustSettings obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.brightness)
      ..writeByte(1)
      ..write(obj.contrast)
      ..writeByte(2)
      ..write(obj.saturation)
      ..writeByte(3)
      ..write(obj.exposure)
      ..writeByte(4)
      ..write(obj.noise)
      ..writeByte(5)
      ..write(obj.smooth);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdjustSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
