import 'package:hive/hive.dart';

part 'objectsModels.g.dart';

@HiveType(typeId: 1)
class Drawing {
  @HiveField(0)
  int? id;
  @HiveField(1)
  int imageId;
  @HiveField(2)
  String drawingPath;
  @HiveField(3)
  String color;
  @HiveField(4)
  double strokeWidth;
  @HiveField(5)
  bool isDeleted;
  @HiveField(6)
  int historyId;

  Drawing({
    this.id,
    required this.imageId,
    required this.drawingPath,
    required this.color,
    required this.strokeWidth,
    this.isDeleted = false,
    required this.historyId,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'image_id': imageId,
    'drawingPath': drawingPath,
    'color': color,
    'strokeWidth': strokeWidth,
    'isDeleted': isDeleted ? 1 : 0,
    'historyId': historyId,
  };

  factory Drawing.fromMap(Map<String, dynamic> map) => Drawing(
    id: map['id'],
    imageId: map['image_id'],
    drawingPath: map['drawingPath'],
    color: map['color'],
    strokeWidth: map['strokeWidth'],
    isDeleted: map['isDeleted'] == 1,
    historyId: map['historyId'],
  );
}

@HiveType(typeId: 2)
class Sticker {
  @HiveField(0)
  int? id;
  @HiveField(1)
  int imageId;
  @HiveField(2)
  String path;
  @HiveField(3)
  double positionX;
  @HiveField(4)
  double positionY;
  @HiveField(5)
  double scale;
  @HiveField(6)
  double rotation;
  @HiveField(7)
  int historyId;
  @HiveField(8)
  bool isAsset;
  @HiveField(9)
  bool isDeleted;

  Sticker({
    this.id,
    required this.imageId,
    required this.path,
    required this.positionX,
    required this.positionY,
    required this.scale,
    required this.rotation,
    required this.historyId,
    required this.isAsset,
    this.isDeleted = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'image_id': imageId,
    'path': path,
    'x': positionX,
    'y': positionY,
    'scale': scale,
    'rotation': rotation,
    'historyId': historyId,
    'is_asset': isAsset ? 1 : 0,
    'isDeleted': isDeleted ? 1 : 0,
  };

  factory Sticker.fromMap(Map<String, dynamic> map) => Sticker(
    id: map['id'],
    imageId: map['image_id'],
    path: map['path'],
    positionX: map['x'],
    positionY: map['y'],
    scale: map['scale'],
    rotation: map['rotation'],
    historyId: map['historyId'],
    isAsset: map['is_asset'] == 1,
    isDeleted: map['isDeleted'] == 1,
  );
}

@HiveType(typeId: 3)
class TextObject {
  @HiveField(0)
  final int? id;
  @HiveField(1)
  final int imageId;
  @HiveField(2)
  final String text;
  @HiveField(3)
  final double positionX;
  @HiveField(4)
  final double positionY;
  @HiveField(5)
  final double fontSize;
  @HiveField(6)
  final String fontWeight;
  @HiveField(7)
  final String fontStyle;
  @HiveField(8)
  final String alignment;
  @HiveField(9)
  final String color;
  @HiveField(10)
  final String fontFamily;
  @HiveField(11)
  final double scale;
  @HiveField(12)
  final double rotation;
  @HiveField(13)
  final int? historyId;
  @HiveField(14)
  final bool isDeleted;

  TextObject({
    this.id,
    required this.imageId,
    required this.text,
    required this.positionX,
    required this.positionY,
    required this.fontSize,
    required this.fontWeight,
    required this.fontStyle,
    required this.alignment,
    required this.color,
    required this.fontFamily,
    required this.scale,
    required this.rotation,
    this.historyId,
    this.isDeleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'image_id': imageId,
      'text': text,
      'positionX': positionX,
      'positionY': positionY,
      'fontSize': fontSize,
      'fontWeight': fontWeight,
      'fontStyle': fontStyle,
      'alignment': alignment,
      'color': color,
      'fontFamily': fontFamily,
      'scale': scale,
      'rotation': rotation,
      'historyId': historyId,
      'isDeleted': isDeleted ? 1 : 0,
    };
  }

  factory TextObject.fromMap(Map<String, dynamic> map) {
    return TextObject(
      id: map['id'],
      imageId: map['image_id'],
      text: map['text'],
      positionX: map['positionX'],
      positionY: map['positionY'],
      fontSize: map['fontSize'],
      fontWeight: map['fontWeight'],
      fontStyle: map['fontStyle'],
      alignment: map['alignment'],
      color: map['color'],
      fontFamily: map['fontFamily'],
      scale: map['scale'],
      rotation: map['rotation'],
      historyId: map['historyId'],
      isDeleted: map['isDeleted'] == 1,
    );
  }
}

@HiveType(typeId: 4)
class ImageData {
  @HiveField(0)
  final int? imageId;
  @HiveField(1)
  final String filePath;
  @HiveField(2)
  final String fileName;
  @HiveField(3)
  final int fileSize;
  @HiveField(4)
  final int width;
  @HiveField(5)
  final int height;
  @HiveField(6)
  final DateTime creationDate;
  @HiveField(7)
  final DateTime lastModified;
  @HiveField(8)
  final int? originalImageId;

  ImageData({
    this.imageId,
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.width,
    required this.height,
    required this.creationDate,
    required this.lastModified,
    this.originalImageId,
  });

  Map<String, dynamic> toMap() {
    return {
      'image_id': imageId,
      'file_path': filePath,
      'file_name': fileName,
      'file_size': fileSize,
      'width': width,
      'height': height,
      'creation_date': creationDate.toIso8601String(),
      'last_modified': lastModified.toIso8601String(),
      'original_image_id': originalImageId,
    };
  }

  factory ImageData.fromMap(Map<String, dynamic> map) {
    return ImageData(
      imageId: map['image_id'],
      filePath: map['file_path'],
      fileName: map['file_name'],
      fileSize: map['file_size'],
      width: map['width'],
      height: map['height'],
      creationDate: DateTime.parse(map['creation_date']),
      lastModified: DateTime.parse(map['last_modified']),
      originalImageId: map['original_image_id'],
    );
  }
}

@HiveType(typeId: 5)
class FilterData {
  @HiveField(0)
  final int? filterId;
  @HiveField(1)
  final String filterName;
  @HiveField(2)
  final double brightness;
  @HiveField(3)
  final double contrast;
  @HiveField(4)
  final double saturation;
  @HiveField(5)
  final double warmth;
  @HiveField(6)
  final double vignette;

  FilterData({
    this.filterId,
    required this.filterName,
    required this.brightness,
    required this.contrast,
    required this.saturation,
    required this.warmth,
    required this.vignette,
  });

  Map<String, dynamic> toMap() {
    return {
      'filter_id': filterId,
      'filter_name': filterName,
      'brightness': brightness,
      'contrast': contrast,
      'saturation': saturation,
      'warmth': warmth,
      'vignette': vignette,
    };
  }

  factory FilterData.fromMap(Map<String, dynamic> map) {
    return FilterData(
      filterId: map['filter_id'],
      filterName: map['filter_name'],
      brightness: map['brightness'],
      contrast: map['contrast'],
      saturation: map['saturation'],
      warmth: map['warmth'],
      vignette: map['vignette'],
    );
  }
}

@HiveType(typeId: 6)
class CollageData {
  @HiveField(0)
  final int? collageId;
  @HiveField(1)
  final String templateName;
  @HiveField(2)
  final int width;
  @HiveField(3)
  final int height;
  @HiveField(4)
  final int fileSize;
  @HiveField(5)
  final String previewPath;
  @HiveField(6)
  final DateTime creationDate;

  CollageData({
    this.collageId,
    required this.templateName,
    required this.width,
    required this.height,
    required this.fileSize,
    required this.previewPath,
    required this.creationDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'collage_id': collageId,
      'template_name': templateName,
      'width': width,
      'height': height,
      'file_size': fileSize,
      'preview_path': previewPath,
      'creation_date': creationDate.toIso8601String(),
    };
  }

  factory CollageData.fromMap(Map<String, dynamic> map) {
    return CollageData(
      collageId: map['collage_id'],
      templateName: map['template_name'],
      width: map['width'],
      height: map['height'],
      fileSize: map['file_size'],
      previewPath: map['preview_path'],
      creationDate: DateTime.parse(map['creation_date']),
    );
  }
}

@HiveType(typeId: 7)
class CollageImage {
  @HiveField(0)
  final int collageId;
  @HiveField(1)
  final int imageId;
  @HiveField(2)
  final double positionX;
  @HiveField(3)
  final double positionY;
  @HiveField(4)
  final double scale;
  @HiveField(5)
  final double rotation;
  @HiveField(6)
  final int zIndex;

  CollageImage({
    required this.collageId,
    required this.imageId,
    required this.positionX,
    required this.positionY,
    required this.scale,
    required this.rotation,
    required this.zIndex,
  });

  Map<String, dynamic> toMap() {
    return {
      'collage_id': collageId,
      'image_id': imageId,
      'position_x': positionX,
      'position_y': positionY,
      'scale': scale,
      'rotation': rotation,
      'z_index': zIndex,
    };
  }

  factory CollageImage.fromMap(Map<String, dynamic> map) {
    return CollageImage(
      collageId: map['collage_id'],
      imageId: map['image_id'],
      positionX: map['position_x'],
      positionY: map['position_y'],
      scale: map['scale'],
      rotation: map['rotation'],
      zIndex: map['z_index'],
    );
  }
}

@HiveType(typeId: 8)
class CurrentState {
  @HiveField(0)
  final int imageId;
  @HiveField(1)
  final int lastHistoryId;
  @HiveField(2)
  final String? currentSnapshotPath;
  @HiveField(3)
  final List<int>? currentSnapshotBytes;

  CurrentState({
    required this.imageId,
    required this.lastHistoryId,
    this.currentSnapshotPath,
    this.currentSnapshotBytes,
  });

  Map<String, dynamic> toMap() {
    return {
      'image_id': imageId,
      'last_history_id': lastHistoryId,
      'current_snapshot_path': currentSnapshotPath,
      'current_snapshot_bytes': currentSnapshotBytes,
    };
  }

  factory CurrentState.fromMap(Map<String, dynamic> map) {
    return CurrentState(
      imageId: map['image_id'],
      lastHistoryId: map['last_history_id'],
      currentSnapshotPath: map['current_snapshot_path'],
      currentSnapshotBytes: map['current_snapshot_bytes'],
    );
  }
}

@HiveType(typeId: 9)
class AdjustSettings {
  @HiveField(0)
  final double brightness;
  @HiveField(1)
  final double contrast;
  @HiveField(2)
  final double saturation;
  @HiveField(3)
  final double exposure;
  @HiveField(4)
  final double noise;
  @HiveField(5)
  final double smooth;

  AdjustSettings({
    required this.brightness,
    required this.contrast,
    required this.saturation,
    required this.exposure,
    required this.noise,
    required this.smooth,
  });

  Map<String, dynamic> toMap() {
    return {
      'brightness': brightness,
      'contrast': contrast,
      'saturation': saturation,
      'exposure': exposure,
      'noise': noise,
      'smooth': smooth,
    };
  }

  factory AdjustSettings.fromMap(Map<String, dynamic> map) {
    return AdjustSettings(
      brightness: map['brightness'] ?? 0.0,
      contrast: map['contrast'] ?? 0.0,
      saturation: map['saturation'] ?? 0.0,
      exposure: map['exposure'] ?? 0.0,
      noise: map['noise'] ?? 0.0,
      smooth: map['smooth'] ?? 0.0,
    );
  }
}