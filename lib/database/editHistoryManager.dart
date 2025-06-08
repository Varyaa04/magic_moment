import 'package:flutter/cupertino.dart';
import 'package:MagicMoment/database/editHistory.dart';
import 'package:MagicMoment/database/magicMomentDatabase.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../pagesSettings/classesSettings/app_localizations.dart';

class EditHistoryManager {
  final MagicMomentDatabase db;
  final int imageId;
  List<EditHistory> _history = [];
  int _currentIndex = -1;
  int get currentIndex => _currentIndex;

  EditHistoryManager({required this.db, required this.imageId});

  bool get canUndo => _currentIndex > 0;
  bool get canRedo => _currentIndex < _history.length - 1;

  Future<void> loadHistory() async {
    try {
      debugPrint('Loading history for imageId: $imageId');
      _history = await db.getAllHistoryForImage(imageId);
      _currentIndex = _history.isNotEmpty ? _history.length - 1 : -1;
      debugPrint('History loaded: ${_history.length} entries, currentIndex: $_currentIndex');
    } catch (e, stackTrace) {
      debugPrint('Error loading history: $e\n$stackTrace');
      _history = [];
      _currentIndex = -1;
    }
  }

  Future<void> saveSnapshot({
    required BuildContext context,
    required Uint8List snapshot,
  }) async {
    try {
      final compressedSnapshot = await FlutterImageCompress.compressWithList(
        snapshot,
        minWidth: 800,
        quality: 70,
        format: CompressFormat.jpeg,
      );
      await addOperation(
        context: context,
        operationType: 'Snapshot',
        parameters: {
          'snapshot_size': compressedSnapshot.length,
        },
        snapshotBytes: compressedSnapshot,
      );
      debugPrint('Snapshot added to history for imageId: $imageId');
    } catch (e, stackTrace) {
      debugPrint('Error saving snapshot: $e\n$stackTrace');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)?.error ?? 'Error'}: Failed to save snapshot'),
          ),
        );
      }
      rethrow;
    }
  }

  Future<EditHistory> addOperation({
    required BuildContext context,
    required String operationType,
    required Map<String, dynamic> parameters,
    List<int>? snapshotBytes,
  }) async {
    try {
      final normalizedOperationType = operationType.toLowerCase();
      final history = EditHistory(
        historyId: null,
        imageId: imageId,
        operationType: normalizedOperationType,
        operationParameters: parameters,
        operationDate: DateTime.now(),
        snapshotBytes: snapshotBytes,
      );

      final historyId = await db.insertHistory(history);
      debugPrint('Added operation: $normalizedOperationType, historyId: $historyId');

      if (_currentIndex < _history.length - 1) {
        final toRemove = _history.sublist(_currentIndex + 1);
        for (var entry in toRemove) {
          if (entry.historyId != null) {
            await db.deleteHistory(entry.historyId!);
            debugPrint('Deleted history entry: ${entry.historyId}');
          }
        }
        _history.removeRange(_currentIndex + 1, _history.length);
      }
      final newHistory = history.copyWith(historyId: historyId);
      _history.add(newHistory);
      _currentIndex = _history.length - 1;
      await db.updateCurrentState(imageId, historyId, snapshotBytes);
      return newHistory;
    } catch (e, stackTrace) {
      debugPrint('Error adding operation: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<EditHistory?> undo() async {
    if (!canUndo) {
      debugPrint('Cannot undo: already at the start of history');
      return null;
    }
    _currentIndex--;
    debugPrint('Undo to index: $_currentIndex');
    return _history[_currentIndex];
  }

  Future<EditHistory?> redo() async {
    if (!canRedo) {
      debugPrint('Cannot redo: already at the end of history');
      return null;
    }
    _currentIndex++;
    debugPrint('Redo to index: $_currentIndex');
    return _history[_currentIndex];
  }

  void setCurrentIndex(int index) {
    if (index >= 0 && index < _history.length) {
      _currentIndex = index;
      debugPrint('Set current history index to: $index');
    }
  }

  Future<Uint8List?> getCurrentSnapshotBytes() async {
    if (_currentIndex >= 0 && _currentIndex < _history.length) {
      final snapshotBytes = _history[_currentIndex].snapshotBytes;
      debugPrint('Current snapshot bytes: ${snapshotBytes != null ? "Available" : "Null"}');
      return snapshotBytes != null ? Uint8List.fromList(snapshotBytes) : null;
    }
    debugPrint('No current snapshot bytes available');
    return null;
  }

  Future<void> cleanupSnapshots() async {
    try {
      _history.clear();
      _currentIndex = -1;
      debugPrint('History cleared');
    } catch (e, stackTrace) {
      debugPrint('Error cleaning up snapshots: $e\n$stackTrace');
    }
  }
}