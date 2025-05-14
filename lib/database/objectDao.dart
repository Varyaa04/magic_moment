import 'package:sqflite/sqflite.dart';
import 'objectsModels.dart';
import 'magicMomentDatabase.dart';

class ObjectDao {
  Future<Database> get _db async => await MagicMomentDatabase.instance.database;

  // стикеры
  Future<int> insertSticker(Sticker sticker) async {
    final db = await _db;
    return db.insert('stickers', sticker.toMap());
  }

  Future<List<Sticker>> getStickers(int imageId) async {
    final db = await _db;
    final maps = await db.query(
      'stickers',
      where: 'image_id = ? AND isDeleted = 0',
      whereArgs: [imageId],
    );
    return maps.map((e) => Sticker.fromMap(e)).toList();
  }

  Future<void> softDeleteSticker(int id) async {
    final db = await _db;
    await db.update('stickers', {'isDeleted': 1}, where: 'id = ?', whereArgs: [id]);
  }

  // рисунки
  Future<int> insertDrawing(Drawing drawing) async {
    final db = await _db;
    return db.insert('drawings', drawing.toMap());
  }

  Future<List<Drawing>> getDrawings(int imageId) async {
    final db = await _db;
    final maps = await db.query(
      'drawings',
      where: 'image_id = ? AND isDeleted = 0',
      whereArgs: [imageId],
    );
    return maps.map((e) => Drawing.fromMap(e)).toList();
  }

  Future<void> softDeleteDrawing(int id) async {
    final db = await _db;
    await db.update('drawings', {'isDeleted': 1}, where: 'id = ?', whereArgs: [id]);
  }

  // текст
  Future<int> insertText(TextObject text) async {
    final db = MagicMomentDatabase.instance;
    return await db.insertText(text);
  }

  Future<List<TextObject>> getTexts(int imageId) async {
    final db = MagicMomentDatabase.instance;
    return await db.getTexts(imageId);
  }

  Future<void> softDeleteText(int id) async {
    final db = await MagicMomentDatabase.instance.database;
    await db.update(
      'texts',
      {'isDeleted': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
