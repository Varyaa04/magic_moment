import 'package:MagicMoment/database/magicMomentDatabase.dart';
class EditHistoryManager {
  final magicMomentDatabase db;
  final int imageId;

  List<EditHistory> _history = [];
  int _currentIndex = -1;

  EditHistoryManager({required this.db, required this.imageId});

  Future<void> loadHistory() async {
    _history = await db.getAllHistoryForImage(imageId);
    _currentIndex = _history.length - 1;
  }

  bool get canUndo => _currentIndex >= 0;
  bool get canRedo => _currentIndex < _history.length - 1;

  Future<void> addOperation({
    required String operationType,
    required Map<String, dynamic> parameters,
    String? snapshotPath,
  }) async {
    if (canRedo) {
      for (int i = _currentIndex + 1; i < _history.length; i++) {
        if (_history[i].historyId != null) {
          await db.deleteHistory(_history[i].historyId!);
        }
      }
      _history = _history.sublist(0, _currentIndex + 1);
    }

    final newEntry = EditHistory(
      imageId: imageId,
      operationType: operationType,
      operationParameters: parameters,
      operationDate: DateTime.now(),
      snapshotPath: snapshotPath,
      previousStateId: canUndo ? _history[_currentIndex].historyId : null,
    );

    final id = await db.insertHistory(newEntry);
    newEntry.historyId = id;

    _history.add(newEntry);
    _currentIndex = _history.length - 1;

    await db.updateCurrentState(
      imageId,
      newEntry.historyId!,
      newEntry.snapshotPath,
    );
  }

  Future<EditHistory?> undo() async {
    if (!canUndo) return null;

    final entry = _history[_currentIndex];
    _currentIndex--;

    if (_currentIndex >= 0) {
      await db.updateCurrentState(
        imageId,
        _history[_currentIndex].historyId!,
        _history[_currentIndex].snapshotPath,
      );
    } else {
      await db.updateCurrentState(imageId, -1, null);
    }

    return entry;
  }

  Future<EditHistory?> redo() async {
    if (!canRedo) return null;

    _currentIndex++;
    final entry = _history[_currentIndex];

    await db.updateCurrentState(
      imageId,
      entry.historyId!,
      entry.snapshotPath,
    );

    return entry;
  }

  Future<String?> getCurrentSnapshotPath() async {
    if (!canUndo) return null;
    return _history[_currentIndex].snapshotPath;
  }
}