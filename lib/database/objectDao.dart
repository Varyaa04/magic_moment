import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'objectsModels.dart';
import 'magicMomentDatabase.dart';

class ObjectDao {
  final MagicMomentDatabase _db = MagicMomentDatabase.instance;

  Future<void> _ensureBoxesOpen() async {
    await _db.ensureBoxesOpen();
  }

  Future<int> insertSticker(Sticker sticker) async {
    await _ensureBoxesOpen();
    try {
      if (sticker.imageId == null) {
        throw Exception('Sticker.imageId cannot be null');
      }
      final key = await _db.stickersBox.add(sticker);
      debugPrint('Inserted sticker with id: $key');
      return key;
    } catch (e, stackTrace) {
      debugPrint('Error inserting sticker: $e\n$stackTrace');
      throw Exception('Failed to insert sticker: $e');
    }
  }

  Future<void> batchInsertStickers(List<Sticker> stickers) async {
    await _ensureBoxesOpen();
    try {
      await _db.stickersBox.addAll(stickers);
      debugPrint('Batch inserted ${stickers.length} stickers');
    } catch (e, stackTrace) {
      debugPrint('Error batch inserting stickers: $e\n$stackTrace');
      throw Exception('Failed to batch insert stickers: $e');
    }
  }

  Future<List<Sticker>> getStickers(int imageId) async {
    await _ensureBoxesOpen();
    try {
      final stickers = _db.stickersBox.values
          .where((sticker) => sticker.imageId == imageId && !sticker.isDeleted)
          .toList();
      debugPrint('Retrieved ${stickers.length} stickers for imageId: $imageId');
      return stickers;
    } catch (e, stackTrace) {
      debugPrint('Error getting stickers for imageId $imageId: $e\n$stackTrace');
      return [];
    }
  }

  Future<void> softDeleteSticker(int id) async {
    await _ensureBoxesOpen();
    try {
      final sticker = _db.stickersBox.get(id);
      if (sticker != null) {
        final updatedSticker = Sticker(
          id: sticker.id,
          imageId: sticker.imageId,
          path: sticker.path,
          positionX: sticker.positionX,
          positionY: sticker.positionY,
          scale: sticker.scale,
          rotation: sticker.rotation,
          historyId: sticker.historyId,
          isAsset: sticker.isAsset,
          isDeleted: true,
        );
        await _db.stickersBox.put(id, updatedSticker);
        debugPrint('Soft deleted sticker with id: $id');
      }
    } catch (e, stackTrace) {
      debugPrint('Error soft deleting sticker $id: $e\n$stackTrace');
      throw Exception('Failed to soft delete sticker: $e');
    }
  }

  Future<int> insertDrawing(Drawing drawing) async {
    await _ensureBoxesOpen();
    try {
      final key = await _db.drawingsBox.add(drawing);
      debugPrint('Inserted drawing with id: $key');
      return key;
    } catch (error, stackTrace) {
      debugPrint('Error inserting drawing: $error\n$stackTrace');
      throw Exception('Failed to insert drawing: $error');
    }
  }

  Future<void> batchInsertDrawings(List<Drawing> drawings) async {
    await _ensureBoxesOpen();
    try {
      await _db.drawingsBox.addAll(drawings);
      debugPrint('Batch inserted ${drawings.length} drawings');
    } catch (e, stackTrace) {
      debugPrint('Error batch inserting drawings: $e\n$stackTrace');
      throw Exception('Failed to batch insert drawings: $e');
    }
  }

  Future<List<Drawing>> getDrawings(int imageId) async {
    await _ensureBoxesOpen();
    try {
      final drawings = _db.drawingsBox.values
          .where((drawing) => drawing.imageId == imageId && !drawing.isDeleted)
          .toList();
      debugPrint('Retrieved ${drawings.length} drawings for imageId: $imageId');
      return drawings;
    } catch (e, stackTrace) {
      debugPrint('Error getting drawings for imageId $imageId: $e\n$stackTrace');
      return [];
    }
  }

  Future<void> softDeleteDrawing(int id) async {
    await _ensureBoxesOpen();
    try {
      final drawing = _db.drawingsBox.get(id);
      if (drawing != null) {
        final updatedDrawing = Drawing(
          id: drawing.id,
          imageId: drawing.imageId,
          drawingPath: drawing.drawingPath,
          color: drawing.color,
          strokeWidth: drawing.strokeWidth,
          isDeleted: true,
          historyId: drawing.historyId,
        );
        await _db.drawingsBox.put(id, updatedDrawing);
        debugPrint('Soft deleted drawing with id: $id');
      }
    } catch (e, stackTrace) {
      debugPrint('Error soft deleting drawing $id: $e\n$stackTrace');
      throw Exception('Failed to soft delete drawing: $e');
    }
  }

  Future<int> insertText(TextObject text) async {
    await _ensureBoxesOpen();
    try {
      if (text.imageId == null) {
        throw Exception('TextObject.imageId cannot be null');
      }
      final key = await _db.textsBox.add(text);
      debugPrint('Inserted text with id: $key');
      return key;
    } catch (e, stackTrace) {
      debugPrint('Error inserting text: $e\n$stackTrace');
      throw Exception('Failed to insert text: $e');
    }
  }

  Future<void> batchInsertTexts(List<TextObject> texts) async {
    await _ensureBoxesOpen();
    try {
      await _db.textsBox.addAll(texts);
      debugPrint('Batch inserted ${texts.length} texts');
    } catch (e, stackTrace) {
      debugPrint('Error batch inserting texts: $e\n$stackTrace');
      throw Exception('Failed to batch insert texts: $e');
    }
  }

  Future<List<TextObject>> getTexts(int imageId) async {
    await _ensureBoxesOpen();
    try {
      final texts = _db.textsBox.values
          .where((text) => text.imageId == imageId && !text.isDeleted)
          .toList();
      debugPrint('Retrieved ${texts.length} texts for imageId: $imageId');
      return texts;
    } catch (e, stackTrace) {
      debugPrint('Error getting texts for imageId $imageId: $e\n$stackTrace');
      return [];
    }
  }

  Future<void> softDeleteText(int id) async {
    await _ensureBoxesOpen();
    try {
      final text = _db.textsBox.get(id);
      if (text != null) {
        final updatedText = TextObject(
          id: text.id,
          imageId: text.imageId,
          text: text.text,
          positionX: text.positionX,
          positionY: text.positionY,
          fontSize: text.fontSize,
          fontWeight: text.fontWeight,
          fontStyle: text.fontStyle,
          alignment: text.alignment,
          color: text.color,
          fontFamily: text.fontFamily,
          scale: text.scale,
          rotation: text.rotation,
          historyId: text.historyId,
          isDeleted: true,
        );
        await _db.textsBox.put(id, updatedText);
        debugPrint('Soft deleted text with id: $id');
      }
    } catch (e, stackTrace) {
      debugPrint('Error soft deleting text $id: $e\n$stackTrace');
      throw Exception('Failed to soft delete text: $e');
    }
  }

  Future<void> cleanupSnapshots() async {
    await _ensureBoxesOpen();
    try {
      final histories = _db.editHistoryBox.values;
      for (var history in histories) {
        try {
          if (history.snapshotPath != null && !kIsWeb) {
            final file = File(history.snapshotPath!);
            if (await file.exists()) {
              await file.delete();
              debugPrint('Deleted snapshot file: ${history.snapshotPath}');
            }
          }
        } catch (e, stackTrace) {
          debugPrint('Error at cleanupSnapshots: $e\n$stackTrace');
        }
      }
      debugPrint('Snapshot cleanup completed');
    } catch (error, stackTrace) {
      debugPrint('Error in cleanupSnapshots: $error\n$stackTrace');
      rethrow;
    }
  }
}