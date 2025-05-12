import 'dart:developer';
import 'dart:io' show Platform;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../pagesEditing/annotation/emojiPanel.dart';
import '../pagesEditing/annotation/textEditorPanel.dart';

class magicMomentDatabase {
  static Database? _database;
  static final magicMomentDatabase instance = magicMomentDatabase._init();

  magicMomentDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final path = join(await getDatabasesPath(), 'magic_moment.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

Future<List<EditHistory>> getAllHistoryForImage(int imageId) async {
    try {
      final db = await database;

      final maps = await db.query(
        'edit_history',
        where: 'image_id = ?',
        whereArgs: [imageId],
        orderBy: 'operation_date ASC',
      );
      return maps.map((map) => EditHistory.fromMap(map)).toList();
    } catch (e) {
      log('Error getting history for image $imageId: $e');
      rethrow;
    }
  }

  Future<int> insertHistory(EditHistory history) async {
    try {
      final db = await database;

      return await db.insert('edit_history', history.toMap());
    } catch (e) {
      log('Error inserting history: $e');
      rethrow;
    }
  }

  Future<int> updateCurrentState(int imageId, int lastHistoryId, String? snapshotPath) async {
    try {
      final db = await database;

      return await db.insert(
        'current_state',
        {
          'image_id': imageId,
          'last_history_id': lastHistoryId,
          'current_snapshot_path': snapshotPath,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      log('Error updating current state for image $imageId: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getCurrentState(int imageId) async {
    try {
      final db = await database;

      final maps = await db.query(
        'current_state',
        where: 'image_id = ?',
        whereArgs: [imageId],
        limit: 1, // Явно ограничиваем одну запись
      );
      return maps.isNotEmpty ? maps.first : null;
    } catch (e) {
      log('Error getting current state for image $imageId: $e');
      rethrow;
    }
  }

  Future<void> setImageFormat(String format) async {
    final db = await database;
    await db.insert(
      'image_format',
      {'format': format},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getImageFormat() async {
    final db = await database;
    final result = await db.query('image_format', limit: 1);
    return result.isNotEmpty ? result.first['format'] as String? : null;
  }

  Future<void> _onCreate(Database db, int version) async {
    // Таблица форматов изображений
    await db.execute('''
      CREATE TABLE image_format (
        format_id INTEGER PRIMARY KEY AUTOINCREMENT,
        format_name TEXT NOT NULL,
        extension TEXT NOT NULL,
        can_compress INTEGER NOT NULL,
        is_lossless INTEGER NOT NULL
      )
    ''');

    // Таблица изображений
    await db.execute('''
      CREATE TABLE image (
        image_id INTEGER PRIMARY KEY AUTOINCREMENT,
        file_path TEXT NOT NULL,
        file_name TEXT NOT NULL,
        file_size INTEGER NOT NULL,
        width INTEGER NOT NULL,
        height INTEGER NOT NULL,
        format_id INTEGER NOT NULL,
        creation_date TEXT NOT NULL,
        last_modified TEXT NOT NULL,
        original_image_id INTEGER,
        FOREIGN KEY (format_id) REFERENCES image_format (format_id),
        FOREIGN KEY (original_image_id) REFERENCES image (image_id)
      )
    ''');

    // Таблица фильтров
    await db.execute('''
      CREATE TABLE filter (
        filter_id INTEGER PRIMARY KEY AUTOINCREMENT,
        filter_name TEXT NOT NULL,
        brightness REAL NOT NULL,
        contrast REAL NOT NULL,
        saturation REAL NOT NULL,
        warmth REAL NOT NULL,
        vignette REAL NOT NULL
      )
    ''');

    // Таблица коллажей
    await db.execute('''
      CREATE TABLE collage (
        collage_id INTEGER PRIMARY KEY AUTOINCREMENT,
        template_name TEXT NOT NULL,
        width INTEGER NOT NULL,
        height INTEGER NOT NULL,
        format_id INTEGER NOT NULL,
        file_size INTEGER NOT NULL,
        preview_path TEXT NOT NULL,
        creation_date TEXT NOT NULL,
        FOREIGN KEY (format_id) REFERENCES image_format (format_id)
      )
    ''');

    // Таблица изображений в коллажах
    await db.execute('''
      CREATE TABLE collage_images (
        collage_id INTEGER NOT NULL,
        image_id INTEGER NOT NULL,
        position_x REAL NOT NULL,
        position_y REAL NOT NULL,
        scale REAL NOT NULL,
        rotation REAL NOT NULL,
        z_index INTEGER NOT NULL,
        PRIMARY KEY (collage_id, image_id),
        FOREIGN KEY (collage_id) REFERENCES collage (collage_id),
        FOREIGN KEY (image_id) REFERENCES image (image_id)
      )
    ''');

    // Таблица истории редактирования
    await db.execute('''
      CREATE TABLE edit_history (
        history_id INTEGER PRIMARY KEY AUTOINCREMENT,
        image_id INTEGER NOT NULL,
        filter_id INTEGER,
        operation_type TEXT NOT NULL,
        operation_parameters TEXT NOT NULL,
        operation_date TEXT NOT NULL,
        snapshot_path TEXT,
        previous_state_id INTEGER,
        FOREIGN KEY (image_id) REFERENCES image (image_id),
        FOREIGN KEY (filter_id) REFERENCES filter (filter_id),
        FOREIGN KEY (previous_state_id) REFERENCES edit_history (history_id)
      )
    ''');

    // Таблица текущего состояния
    await db.execute('''
      CREATE TABLE current_state (
        image_id INTEGER PRIMARY KEY,
        last_history_id INTEGER NOT NULL,
        current_snapshot_path TEXT,
        FOREIGN KEY (image_id) REFERENCES image (image_id),
        FOREIGN KEY (last_history_id) REFERENCES edit_history (history_id)
      )
    ''');

    //Таблица для эмодзи
    await db.execute('''
    CREATE TABLE stickers (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      image_id INTEGER NOT NULL,
      path TEXT NOT NULL,
      bytes BLOB,
      x REAL NOT NULL,
      y REAL NOT NULL,
      size REAL NOT NULL,
      is_asset INTEGER NOT NULL,
      FOREIGN KEY (image_id) REFERENCES images (id) ON DELETE CASCADE
    )
  ''');

    //Таблица для текста
    await db.execute('''
    CREATE TABLE texts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      image_id INTEGER NOT NULL,
      content TEXT NOT NULL,
      x REAL NOT NULL,
      y REAL NOT NULL,
      size REAL NOT NULL,
      color INTEGER NOT NULL,
      font_family TEXT NOT NULL,
      FOREIGN KEY (image_id) REFERENCES images (id) ON DELETE CASCADE
    )
  ''');
    // Заполняем справочник форматов
    await _populateImageFormats(db);
  }

  Future<void> _populateImageFormats(Database db) async {
    await db.insert('image_format', {
      'format_name': 'JPEG',
      'extension': '.jpg',
      'can_compress': 1,
      'is_lossless': 0
    });

    await db.insert('image_format', {
      'format_name': 'PNG',
      'extension': '.png',
      'can_compress': 1,
      'is_lossless': 1
    });
  }

  //  CRUD операции для таблицы изображений
  Future<int> insertImage(ImageData image) async {
    final db = await instance.database;
    return await db.insert('image', image.toMap());
  }

  Future<List<ImageData>> getAllImages() async {
    final db = await instance.database;
    final maps = await db.query('image');
    return List.generate(maps.length, (i) => ImageData.fromMap(maps[i]));
  }

  Future<ImageData?> getImage(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'image',
      where: 'image_id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) return ImageData.fromMap(maps.first);
    return null;
  }

  Future<int> updateImage(ImageData image) async {
    final db = await instance.database;
    return await db.update(
      'image',
      image.toMap(),
      where: 'image_id = ?',
      whereArgs: [image.imageId],
    );
  }

  Future<int> deleteImage(int id) async {
    final db = await instance.database;
    return await db.delete(
      'image',
      where: 'image_id = ?',
      whereArgs: [id],
    );
  }

  //  CRUD операции для таблицы фильтров
  Future<int> insertFilter(FilterData filter) async {
    final db = await instance.database;
    return await db.insert('filter', filter.toMap());
  }

  Future<List<FilterData>> getAllFilters() async {
    final db = await instance.database;
    final maps = await db.query('filter');
    return List.generate(maps.length, (i) => FilterData.fromMap(maps[i]));
  }

  Future<FilterData?> getFilter(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'filter',
      where: 'filter_id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) return FilterData.fromMap(maps.first);
    return null;
  }

  Future<int> updateFilter(FilterData filter) async {
    final db = await instance.database;
    return await db.update(
      'filter',
      filter.toMap(),
      where: 'filter_id = ?',
      whereArgs: [filter.filterId],
    );
  }

  Future<int> deleteFilter(int id) async {
    final db = await instance.database;
    return await db.delete(
      'filter',
      where: 'filter_id = ?',
      whereArgs: [id],
    );
  }

  //  CRUD операции для таблицы с коллажами
  Future<int> insertCollage(CollageData collage) async {
    final db = await instance.database;
    return await db.insert('collage', collage.toMap());
  }

  Future<List<CollageData>> getAllCollage() async {
    final db = await instance.database;
    final maps = await db.query('collage');
    return List.generate(maps.length, (i) => CollageData.fromMap(maps[i]));
  }

  Future<CollageData?> getCollage(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'collage',
      where: 'collage_id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) return CollageData.fromMap(maps.first);
    return null;
  }

  Future<int> updateCollage(CollageData collage) async {
    final db = await instance.database;
    return await db.update(
      'collage',
      collage.toMap(),
      where: 'collage_id = ?',
      whereArgs: [collage.collageId],
    );
  }

  Future<int> deleteCollage(int id) async {
    final db = await instance.database;
    return await db.delete(
      'collage',
      where: 'collage_id = ?',
      whereArgs: [id],
    );
  }

 //  CRUD операции для таблицы с историей
  Future<List<EditHistory>> getAllHistory() async {
    final db = await instance.database;
    final maps = await db.query('history');
    return List.generate(maps.length, (i) => EditHistory.fromMap(maps[i]));
  }

  Future<EditHistory?> getHistory(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'history',
      where: 'history_id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) return EditHistory.fromMap(maps.first);
    return null;
  }

  Future<int> updateHistory(EditHistory history) async {
    final db = await instance.database;
    return await db.update(
      'history',
      history.toMap(),
      where: 'history_id = ?',
      whereArgs: [history.historyId],
    );
  }

  Future<int> deleteHistory(int id) async {
    final db = await instance.database;
    return await db.delete(
      'history',
      where: 'history_id = ?',
      whereArgs: [id],
    );
  }

//  CRUD операции для таблицы с эмодзи
  Future<int> insertSticker(StickerData sticker, int imageId) async {
    final db = await database;
    return await db.insert('stickers', sticker.isAsset as Map<String, Object?>);
  }



  Future<void> updateSticker(StickerData sticker) async {
    final db = await database;
    await db.update(
      'stickers',
      {
        'x': sticker.position.dx,
        'y': sticker.position.dy,
        'size': sticker.size,
      },
      where: 'id = ?',
      whereArgs: [sticker.isAsset],
    );
  }

  Future<void> deleteSticker(int id) async {
    final db = await database;
    await db.delete(
      'stickers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertTextItem(TextItem item, int imageId) async {
    final db = await database;
    return await db.insert('texts', item.toMap(imageId));
  }

  Future<List<TextItem>> getTextItemsForImage(int imageId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'texts',
      where: 'image_id = ?',
      whereArgs: [imageId],
    );
    return List.generate(maps.length, (i) => TextItem.fromMap(maps[i]));
  }

  Future<void> updateTextItem(TextItem item) async {
    final db = await database;
    await db.update(
      'texts',
      {
        'x': item.position.dx,
        'y': item.position.dy,
        'size': item.size,
        'color': item.color.value,
      },
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> deleteTextItem(int id) async {
    final db = await database;
    await db.delete(
      'texts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

Future<int> insertHistory(EditHistory history) async {
  var database;
  final db = await database;
  return await db.insert('edit_history', history.toMap());
}
Future<List<EditHistory>> getAllHistoryForImage(int imageId) async {
  var database;
  final db = await database;
  final List<Map<String, dynamic>> maps = await db.query(
    'edit_history',
    where: 'image_id = ?',
    whereArgs: [imageId],
    orderBy: 'operation_date ASC',
  );
  return List.generate(maps.length, (i) => EditHistory.fromMap(maps[i]));
}
Future<void> updateCurrentState(int imageId, int historyId, String? snapshotPath) async {
  var database;
  final db = await database;
  await db.update(
    'images',
    {
      'current_history_id': historyId,
      'current_snapshot_path': snapshotPath,
    },
    where: 'image_id = ?',
    whereArgs: [imageId],
  );
}
Future<void> deleteHistory(int historyId) async {
  var database;
  final db = await database;
  await db.delete(
    'edit_history',
    where: 'history_id = ?',
    whereArgs: [historyId],
  );
}


// Модели данных
class ImageData {
  final int? imageId;
  final String filePath;
  final String fileName;
  final int fileSize;
  final int width;
  final int height;
  final int formatId;
  final DateTime creationDate;
  final DateTime lastModified;
  final int? originalImageId;

  ImageData({
    this.imageId,
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.width,
    required this.height,
    required this.formatId,
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
      'format_id': formatId,
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
      formatId: map['format_id'],
      creationDate: DateTime.parse(map['creation_date']),
      lastModified: DateTime.parse(map['last_modified']),
      originalImageId: map['original_image_id'],
    );
  }
}

class FilterData {
  final int? filterId;
  final String filterName;
  final double brightness;
  final double contrast;
  final double saturation;
  final double warmth;
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

class CollageData {
  final int? collageId;
  final String templateName;
  final int width;
  final int height;
  final int formatId;
  final int fileSize;
  final String previewPath;
  final DateTime creationDate;

  CollageData({
    this.collageId,
    required this.templateName,
    required this.width,
    required this.height,
    required this.formatId,
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
      'format_id': formatId,
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
      formatId: map['format_id'],
      fileSize: map['file_size'],
      previewPath: map['preview_path'],
      creationDate: DateTime.parse(map['creation_date']),
    );
  }
}

class EditHistory {
  int? historyId;
  final int imageId;
  final String operationType;
  final Map<String, dynamic> operationParameters;
  final DateTime operationDate;
  final String? snapshotPath;
  final int? previousStateId;

  EditHistory({
    this.historyId,
    required this.imageId,
    required this.operationType,
    required this.operationParameters,
    required this.operationDate,
    this.snapshotPath,
    this.previousStateId,
  });

  Map<String, dynamic> toMap() {
    return {
      'history_id': historyId,
      'image_id': imageId,
      'operation_type': operationType,
      'operation_parameters': jsonEncode(operationParameters),
      'operation_date': operationDate.toIso8601String(),
      'snapshot_path': snapshotPath,
      'previous_state_id': previousStateId,
    };
  }

  factory EditHistory.fromMap(Map<String, dynamic> map) {
    return EditHistory(
      historyId: map['history_id'],
      imageId: map['image_id'],
      operationType: map['operation_type'],
      operationParameters: jsonDecode(map['operation_parameters']),
      operationDate: DateTime.parse(map['operation_date']),
      snapshotPath: map['snapshot_path'],
      previousStateId: map['previous_state_id'],
    );
  }
}