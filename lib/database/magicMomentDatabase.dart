import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../pagesSettings/classesSettings/app_localizations.dart';
import 'editHistory.dart';
import 'objectsModels.dart';

class MagicMomentDatabase {
  static final MagicMomentDatabase instance = MagicMomentDatabase._init();

  MagicMomentDatabase._init();

  Future<void> initBasic() async {
    try {
      await Hive.initFlutter();
      // Register all adapters upfront to avoid adapter errors
      Hive.registerAdapter(EditHistoryAdapter());
      Hive.registerAdapter(ImageDataAdapter());
      Hive.registerAdapter(CurrentStateAdapter());
      Hive.registerAdapter(DrawingAdapter());
      Hive.registerAdapter(StickerAdapter());
      Hive.registerAdapter(TextObjectAdapter());
      Hive.registerAdapter(FilterDataAdapter());
      Hive.registerAdapter(CollageDataAdapter());
      Hive.registerAdapter(CollageImageAdapter());
      Hive.registerAdapter(AdjustSettingsAdapter());

      // Open basic boxes
      await Hive.openBox<EditHistory>('edit_history');
      await Hive.openBox<ImageData>('image');
      await Hive.openBox<CurrentState>('current_state');
      debugPrint('Hive basic initialization completed');
    } catch (e, stackTrace) {
      debugPrint('Error during basic Hive initialization: $e\n$stackTrace');
      throw Exception('Failed basic database initialization: $e');
    }
  }

  Future<void> initComplete() async {
    try {
      // Open remaining boxes
      await Future.wait([
        Hive.openBox<Sticker>('stickers'),
        Hive.openBox<Drawing>('drawings'),
        Hive.openBox<TextObject>('texts'),
        Hive.openBox<FilterData>('filter'),
        Hive.openBox<CollageData>('collage'),
        Hive.openBox<CollageImage>('collage_images'),
      ]);
      debugPrint('Hive complete initialization finished');
    } catch (e, stackTrace) {
      debugPrint('Error during complete Hive initialization: $e\n$stackTrace');
    }
  }

  @Deprecated('Use initBasic() and initComplete() instead')
  Future<void> init() async {
    await initBasic();
    await initComplete();
  }

  Future<void> ensureBoxesOpen() async {
    try {
      if (!Hive.isBoxOpen('stickers')) {
        await Hive.openBox<Sticker>('stickers');
      }
      if (!Hive.isBoxOpen('drawings')) {
        await Hive.openBox<Drawing>('drawings');
      }
      if (!Hive.isBoxOpen('texts')) {
        await Hive.openBox<TextObject>('texts');
      }
      if (!Hive.isBoxOpen('filter')) {
        await Hive.openBox<FilterData>('filter');
      }
      if (!Hive.isBoxOpen('collage')) {
        await Hive.openBox<CollageData>('collage');
      }
      if (!Hive.isBoxOpen('collage_images')) {
        await Hive.openBox<CollageImage>('collage_images');
      }
      debugPrint('Ensured all necessary boxes are open');
    } catch (e, stackTrace) {
      debugPrint('Error ensuring boxes open: $e\n$stackTrace');
      throw Exception('Failed to open Hive boxes: $e');
    }
  }

  Box<EditHistory> get editHistoryBox => Hive.box<EditHistory>('edit_history');
  Box<Sticker> get stickersBox => Hive.box<Sticker>('stickers');
  Box<Drawing> get drawingsBox => Hive.box<Drawing>('drawings');
  Box<TextObject> get textsBox => Hive.box<TextObject>('texts');
  Box<ImageData> get imagesBox => Hive.box<ImageData>('image');
  Box<FilterData> get filtersBox => Hive.box<FilterData>('filter');
  Box<CollageData> get collagesBox => Hive.box<CollageData>('collage');
  Box<CollageImage> get collageImagesBox => Hive.box<CollageImage>('collage_images');
  Box<CurrentState> get currentStateBox => Hive.box<CurrentState>('current_state');

  Future<void> migrateImageIds(BuildContext context) async {
    try {
      for (var sticker in stickersBox.values.where((s) => s.imageId == 0)) {
        final history = editHistoryBox.values.firstWhere(
              (h) => h.historyId == sticker.historyId,
          orElse: () {
            debugPrint('History not found for sticker ${sticker.id}');
            return null as EditHistory;
          },
        );
        if (history == null) continue;

        final updatedSticker = Sticker(
          id: sticker.id,
          imageId: history.imageId,
          path: sticker.path,
          positionX: sticker.positionX,
          positionY: sticker.positionY,
          scale: sticker.scale,
          rotation: sticker.rotation,
          historyId: sticker.historyId,
          isAsset: sticker.isAsset,
          isDeleted: sticker.isDeleted,
        );
        await stickersBox.put(sticker.id, updatedSticker);
      }

      for (var drawing in drawingsBox.values.where((d) => d.imageId == 0)) {
        final history = editHistoryBox.values.firstWhere(
              (h) => h.historyId == drawing.historyId,
          orElse: () {
            debugPrint('History not found for drawing ${drawing.id}');
            return null as EditHistory;
          },
        );
        if (history == null) continue;

        final updatedDrawing = Drawing(
          id: drawing.id,
          imageId: history.imageId,
          drawingPath: drawing.drawingPath,
          color: drawing.color,
          strokeWidth: drawing.strokeWidth,
          isDeleted: drawing.isDeleted,
          historyId: drawing.historyId,
        );
        await drawingsBox.put(drawing.id, updatedDrawing);
      }

      for (var text in textsBox.values.where((t) => t.imageId == 0)) {
        final history = editHistoryBox.values.firstWhere(
              (h) => h.historyId == text.historyId,
          orElse: () {
            debugPrint('History not found for text ${text.id}');
            return null as EditHistory;
          },
        );
        if (history == null) continue;

        final updatedText = TextObject(
          id: text.id,
          imageId: history.imageId,
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
          isDeleted: text.isDeleted,
        );
        await textsBox.put(text.id, updatedText);
      }

      debugPrint('Image IDs migrated successfully');
    } catch (e, stackTrace) {
      debugPrint('Error migrating image IDs: $e\n$stackTrace');
      throw Exception('${AppLocalizations.of(context)?.error ?? 'Error'}: Failed to migrate image IDs: $e');
    }
  }

  Future<void> close() async {
    await Hive.close();
    debugPrint('All Hive boxes closed');
  }

  Future<int> updateCurrentState(int imageId, int lastHistoryId, List<int>? snapshotBytes) async {
    try {
      final state = CurrentState(
        imageId: imageId,
        lastHistoryId: lastHistoryId,
        currentSnapshotBytes: snapshotBytes,
      );
      await currentStateBox.put('state_$imageId', state);
      debugPrint('Updated current state for imageId: $imageId, historyId: $lastHistoryId');
      return 1;
    } catch (e, stackTrace) {
      debugPrint('Error updating current state for image $imageId: $e\n$stackTrace');
      throw Exception('Failed to update current state: $e');
    }
  }

  Future<int> deleteHistory(int id) async {
    try {
      await editHistoryBox.delete(id);
      debugPrint('Deleted history entry with id: $id');
      return 1;
    } catch (e, stackTrace) {
      debugPrint('Error deleting history: $e\n$stackTrace');
      throw Exception('Failed to delete history: $e');
    }
  }

  Future<Map<String, dynamic>?> getCurrentState(int imageId) async {
    try {
      final state = currentStateBox.get('state_$imageId');
      debugPrint('Retrieved current state for imageId: $imageId');
      return state?.toMap();
    } catch (e, stackTrace) {
      debugPrint('Error getting current state for image $imageId: $e\n$stackTrace');
      return null;
    }
  }

  Future<int> insertImage(ImageData image) async {
    try {
      final key = await imagesBox.add(image);
      debugPrint('Inserted image with id: $key');
      if (key < 0 || key > 0xFFFFFFFF) {
        throw Exception('Generated key $key is out of valid range (0 to 0xFFFFFFFF)');
      }
      return key;
    } catch (e, stackTrace) {
      debugPrint('Error inserting image: $e\n$stackTrace');
      throw Exception('Failed to insert image: $e');
    }
  }

  Future<List<ImageData>> getAllImages() async {
    try {
      final images = imagesBox.values.toList();
      debugPrint('Retrieved ${images.length} images');
      return images;
    } catch (e, stackTrace) {
      debugPrint('Error getting images: $e\n$stackTrace');
      return [];
    }
  }

  Future<ImageData?> getImage(int id) async {
    try {
      final image = imagesBox.get(id);
      debugPrint('Retrieved image with id: $id');
      return image;
    } catch (e, stackTrace) {
      debugPrint('Error getting image $id: $e\n$stackTrace');
      return null;
    }
  }

  Future<int> updateImage(ImageData image) async {
    try {
      await imagesBox.put(image.imageId!, image);
      debugPrint('Updated image with id: ${image.imageId}');
      return 1;
    } catch (e, stackTrace) {
      debugPrint('Error updating image: $e\n$stackTrace');
      throw Exception('Failed to update image: $e');
    }
  }

  Future<int> deleteImage(int id) async {
    try {
      await imagesBox.delete(id);
      debugPrint('Deleted image with id: $id');
      return 1;
    } catch (e, stackTrace) {
      debugPrint('Error deleting image: $e\n$stackTrace');
      throw Exception('Failed to delete image: $e');
    }
  }

  Future<int> insertFilter(FilterData filter) async {
    try {
      final key = await filtersBox.add(filter);
      debugPrint('Inserted filter with id: $key');
      return key;
    } catch (e, stackTrace) {
      debugPrint('Error inserting filter: $e\n$stackTrace');
      throw Exception('Failed to insert filter: $e');
    }
  }

  Future<List<FilterData>> getAllFilters() async {
    try {
      final filters = filtersBox.values.toList();
      debugPrint('Retrieved ${filters.length} filters');
      return filters;
    } catch (e, stackTrace) {
      debugPrint('Error getting filters: $e\n$stackTrace');
      return [];
    }
  }

  Future<FilterData?> getFilter(int id) async {
    try {
      final filter = filtersBox.get(id);
      debugPrint('Retrieved filter with id: $id');
      return filter;
    } catch (e, stackTrace) {
      debugPrint('Error getting filter $id: $e\n$stackTrace');
      return null;
    }
  }

  Future<int> updateFilter(FilterData filter) async {
    try {
      await filtersBox.put(filter.filterId!, filter);
      debugPrint('Updated filter with id: ${filter.filterId}');
      return 1;
    } catch (e, stackTrace) {
      debugPrint('Error updating filter: $e\n$stackTrace');
      throw Exception('Failed to update filter: $e');
    }
  }

  Future<int> deleteFilter(int id) async {
    try {
      await filtersBox.delete(id);
      debugPrint('Deleted filter with id: $id');
      return 1;
    } catch (e, stackTrace) {
      debugPrint('Error deleting filter: $e\n$stackTrace');
      throw Exception('Failed to delete filter: $e');
    }
  }

  Future<int> insertCollage(CollageData collage) async {
    try {
      final key = await collagesBox.add(collage);
      debugPrint('Inserted collage with id: $key');
      return key;
    } catch (e, stackTrace) {
      debugPrint('Error inserting collage: $e\n$stackTrace');
      throw Exception('Failed to insert collage: $e');
    }
  }

  Future<List<CollageData>> getAllCollage() async {
    try {
      final collages = collagesBox.values.toList();
      debugPrint('Retrieved ${collages.length} collages');
      return collages;
    } catch (e, stackTrace) {
      debugPrint('Error getting collages: $e\n$stackTrace');
      return [];
    }
  }

  Future<CollageData?> getCollage(int id) async {
    try {
      final collage = collagesBox.get(id);
      debugPrint('Retrieved collage with id: $id');
      return collage;
    } catch (e, stackTrace) {
      debugPrint('Error getting collage $id: $e\n$stackTrace');
      return null;
    }
  }

  Future<int> updateCollage(CollageData collage) async {
    try {
      await collagesBox.put(collage.collageId!, collage);
      debugPrint('Updated collage with id: ${collage.collageId}');
      return 1;
    } catch (e, stackTrace) {
      debugPrint('Error updating collage: $e\n$stackTrace');
      throw Exception('Failed to update collage: $e');
    }
  }

  Future<int> deleteCollage(int id) async {
    try {
      await collagesBox.delete(id);
      debugPrint('Deleted collage with id: $id');
      return 1;
    } catch (e, stackTrace) {
      debugPrint('Error deleting collage: $e\n$stackTrace');
      throw Exception('Failed to delete collage: $e');
    }
  }

  Future<List<EditHistory>> getAllHistory() async {
    try {
      final histories = editHistoryBox.values.toList();
      debugPrint('Retrieved ${histories.length} history entries');
      return histories;
    } catch (e, stackTrace) {
      debugPrint('Error getting all history: $e\n$stackTrace');
      return [];
    }
  }

  Future<EditHistory?> getHistory(int id) async {
    try {
      final history = editHistoryBox.get(id);
      debugPrint('Retrieved history with id: $id');
      return history;
    } catch (e, stackTrace) {
      debugPrint('Error getting history $id: $e\n$stackTrace');
      return null;
    }
  }

  Future<int> updateHistory(EditHistory history) async {
    try {
      await editHistoryBox.put(history.historyId!, history);
      debugPrint('Updated history with id: ${history.historyId}');
      return 1;
    } catch (e, stackTrace) {
      debugPrint('Error updating history: $e\n$stackTrace');
      throw Exception('Failed to update history: $e');
    }
  }

  Future<int> insertText(TextObject text) async {
    try {
      final key = await textsBox.add(text);
      debugPrint('Inserted text with id: $key');
      return key;
    } catch (e, stackTrace) {
      debugPrint('Error inserting text: $e\n$stackTrace');
      throw Exception('Failed to insert text: $e');
    }
  }

  Future<List<TextObject>> getTexts(int imageId) async {
    try {
      final texts = textsBox.values.where((text) => text.imageId == imageId && !text.isDeleted).toList();
      debugPrint('Retrieved ${texts.length} texts for imageId: $imageId');
      return texts;
    } catch (e, stackTrace) {
      debugPrint('Error getting texts for imageId $imageId: $e\n$stackTrace');
      return [];
    }
  }

  Future<void> softDeleteText(int id) async {
    try {
      final text = textsBox.get(id);
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
        await textsBox.put(id, updatedText);
        debugPrint('Soft deleted text with id: $id');
      }
    } catch (e, stackTrace) {
      debugPrint('Error soft deleting text $id: $e\n$stackTrace');
      throw Exception('Failed to soft delete text: $e');
    }
  }

  Future<int> insertCollageImage(CollageImage collageImage) async {
    try {
      final key = await collageImagesBox.add(collageImage);
      debugPrint('Inserted collage image with key: $key');
      return key;
    } catch (e, stackTrace) {
      debugPrint('Error inserting collage image: $e\n$stackTrace');
      throw Exception('Failed to insert collage image: $e');
    }
  }

  Future<int> insertHistory(EditHistory history) async {
    final box = await Hive.openBox<EditHistory>('edit_history');
    final key = await box.add(history);
    debugPrint('Inserted history entry with key: $key');
    return key;
  }

  Future<List<EditHistory>> getAllHistoryForImage(int imageId) async {
    final box = await Hive.openBox<EditHistory>('edit_history');
    final entries = box.values.where((entry) => entry.imageId == imageId).toList();
    debugPrint('Retrieved ${entries.length} history entries for imageId: $imageId');
    return entries;
  }

  Future<List<CollageImage>> getCollageImages(int collageId) async {
    try {
      final images = collageImagesBox.values.where((ci) => ci.collageId == collageId).toList();
      debugPrint('Retrieved ${images.length} collage images for collageId: $collageId');
      return images;
    } catch (e, stackTrace) {
      debugPrint('Error getting collage images for collageId $collageId: $e\n$stackTrace');
      return [];
    }
  }

  Future<int> deleteCollageImage(int collageId, int imageId) async {
    try {
      final valuesList = collageImagesBox.values.toList();
      final keys = valuesList
          .asMap()
          .entries
          .where((entry) => entry.value.collageId == collageId && entry.value.imageId == imageId)
          .map((entry) => entry.key)
          .toList();
      for (var key in keys) {
        await collageImagesBox.delete(key);
      }
      debugPrint('Deleted ${keys.length} collage images with collageId: $collageId, imageId: $imageId');
      return keys.length;
    } catch (e, stackTrace) {
      debugPrint('Error deleting collage image: $e\n$stackTrace');
      throw Exception('Failed to delete collage image: $e');
    }
  }
}