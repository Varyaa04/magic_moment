class Drawing {
  int? id;
  int imageId;
  String drawingPath;
  String color;
  double strokeWidth;
  int historyId;
  bool isDeleted;

  Drawing({
    this.id,
    required this.imageId,
    required this.drawingPath,
    required this.color,
    required this.strokeWidth,
    required this.historyId,
    this.isDeleted = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'image_id': imageId,
    'drawingPath': drawingPath,
    'color': color,
    'strokeWidth': strokeWidth,
    'historyId': historyId,
    'isDeleted': isDeleted ? 1 : 0,
  };

  factory Drawing.fromMap(Map<String, dynamic> map) => Drawing(
    id: map['id'],
    imageId: map['image_id'],
    drawingPath: map['drawingPath'],
    color: map['color'],
    strokeWidth: map['strokeWidth'],
    historyId: map['historyId'],
    isDeleted: map['isDeleted'] == 1,
  );
}

class Sticker {
  int? id;
  int imageId;
  String path;
  double positionX;
  double positionY;
  double scale;
  double rotation;
  int historyId;
  bool isAsset;
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

class TextObject {
  final int? id;
  final int imageId;
  final String text;
  final double positionX;
  final double positionY;
  final double fontSize;
  final String fontWeight;
  final String fontStyle;
  final String alignment;
  final String color;
  final String fontFamily;
  final double scale;
  final double rotation;
  final int? historyId;
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
      'imageId': imageId,
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

  static TextObject fromMap(Map<String, dynamic> map) {
    return TextObject(
      id: map['id'],
      imageId: map['imageId'],
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
class AdjustSettings {
  final double brightness;
  final double contrast;
  final double saturation;
  final double exposure;
  final double noise;
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