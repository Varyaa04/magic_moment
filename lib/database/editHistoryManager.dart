import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:MagicMoment/database/editHistory.dart';
import 'package:MagicMoment/database/magicMomentDatabase.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../pagesSettings/classesSettings/app_localizations.dart';

class EditHistoryManager {
  final MagicMomentDatabase db;
  final int imageId;
  List<EditHistory> _history = [];
  int _currentIndex = -1;

  EditHistoryManager({required this.db, required this.imageId});

  bool get canUndo => _currentIndex > 0;
  bool get canRedo => _currentIndex < _history.length - 1;

  Future<void> loadHistory() async {
    try {
      debugPrint('Loading history for imageId: $imageId');
      _history = await db.getAllHistoryForImage(imageId);
      _currentIndex = _history.isNotEmpty ? _history.length - 1 : -1;
      debugPrint(
          'History loaded: ${_history.length} entries, currentIndex: $_currentIndex');
    } catch (e, stackTrace) {
      debugPrint('Error loading history: $e\n$stackTrace');
      _history = [];
      _currentIndex = -1;
    }
  }

  Future<void> addOperation({
    required BuildContext context,
    required String operationType,
    required Map<String, dynamic> parameters,
    String? snapshotPath,
    List<int>? snapshotBytes,
  }) async {
    try {
      debugPrint('Adding operation with imageId: $imageId'); // Добавьте эту строку
      if (snapshotPath != null && snapshotPath.isEmpty) {
        throw ArgumentError(AppLocalizations.of(context)?.error ?? 'snapshotPath cannot be empty if provided');
      }
      if (kIsWeb && snapshotPath != null) {
        throw ArgumentError('snapshotPath is not supported on web; use snapshotBytes');
      }
      if (!kIsWeb && snapshotBytes != null) {
        throw ArgumentError('snapshotBytes is not supported on non-web; use snapshotPath');
      }

      if (!kIsWeb && snapshotPath != null) {
        final existing = _history.any((entry) => entry.snapshotPath == snapshotPath);
        if (existing) {
          throw Exception('Snapshot path already exists: $snapshotPath');
        }
      }

      final history = EditHistory(
        historyId: null,
        imageId: imageId,
        operationType: operationType,
        operationParameters: parameters,
        operationDate: DateTime.now(),
        snapshotPath: snapshotPath,
        snapshotBytes: snapshotBytes,
      );

      final historyId = await db.insertHistory(history);
      debugPrint('Added operation: $operationType, historyId: $historyId, snapshot: $snapshotPath');

      if (_currentIndex < _history.length - 1) {
        final toRemove = _history.sublist(_currentIndex + 1);
        for (var entry in toRemove) {
          if (!kIsWeb && entry.snapshotPath != null && entry.snapshotPath!.isNotEmpty) {
            final file = File(entry.snapshotPath!);
            if (await file.exists()) {
              await file.delete();
              debugPrint('Deleted snapshot: ${entry.snapshotPath}');
            }
          }
          if (entry.historyId != null) {
            await db.deleteHistory(entry.historyId!);
            debugPrint('Deleted history entry: ${entry.historyId}');
          }
        }
        _history.removeRange(_currentIndex + 1, _history.length);
      }

      _history.add(history.copyWith(historyId: historyId));
      _currentIndex = _history.length - 1;
      await db.updateCurrentState(imageId, historyId, snapshotPath, snapshotBytes);
    } catch (e, stackTrace) {
      debugPrint('Error adding operation: $e\n$stackTrace');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)?.error ?? 'Error'}: $e'),
          ),
        );
      }
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

  Future<String?> getCurrentSnapshotPath() async {
    if (_currentIndex >= 0 && _currentIndex < _history.length) {
      debugPrint(
          'Current snapshot path: ${_history[_currentIndex].snapshotPath}');
      return _history[_currentIndex].snapshotPath;
    }
    debugPrint('No current snapshot available');
    return null;
  }

  Future<List<int>?> getCurrentSnapshotBytes() async {
    if (_currentIndex >= 0 && _currentIndex < _history.length) {
      debugPrint('Current snapshot bytes retrieved');
      return _history[_currentIndex].snapshotBytes;
    }
    debugPrint('No current snapshot bytes available');
    return null;
  }

  Future<void> cleanupSnapshots() async {
    try {
      if (!kIsWeb) {
        for (var entry in _history) {
          if (entry.snapshotPath != null && entry.snapshotPath!.isNotEmpty) {
            final file = File(entry.snapshotPath!);
            if (await file.exists()) {
              await file.delete();
              debugPrint('Cleaned up snapshot: ${entry.snapshotPath}');
            }
          }
        }
      } else {
        debugPrint('Snapshot cleanup skipped on web');
      }
      _history.clear();
      _currentIndex = -1;
    } catch (e, stackTrace) {
      debugPrint('Error cleaning up snapshots: $e\n$stackTrace');
    }
  }
}
