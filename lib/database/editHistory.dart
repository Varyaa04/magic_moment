import 'dart:convert';
import 'package:hive/hive.dart';

part 'editHistory.g.dart';

@HiveType(typeId: 0)
class EditHistory {
  @HiveField(0)
  final int? historyId;
  @HiveField(1)
  final int imageId;
  @HiveField(2)
  final String operationType;
  @HiveField(3)
  final Map<String, dynamic> operationParameters;
  @HiveField(4)
  final DateTime operationDate;
  @HiveField(5)
  final String? snapshotPath; // Для Android
  @HiveField(6)
  final List<int>? snapshotBytes; // Для веба

  EditHistory({
    this.historyId,
    required this.imageId,
    required this.operationType,
    required this.operationParameters,
    required this.operationDate,
    this.snapshotPath,
    this.snapshotBytes,
  });

  Map<String, dynamic> toMap() {
    return {
      'history_id': historyId,
      'image_id': imageId,
      'operation_type': operationType,
      'operation_parameters': jsonEncode(operationParameters),
      'operation_date': operationDate.toIso8601String(),
      'snapshot_path': snapshotPath,
      'snapshot_bytes': snapshotBytes,
    };
  }

  factory EditHistory.fromMap(Map<String, dynamic> map) {
    return EditHistory(
      historyId: map['history_id'] as int?,
      imageId: map['image_id'] as int,
      operationType: map['operation_type'] as String,
      operationParameters: Map<String, dynamic>.from(jsonDecode(map['operation_parameters'] as String)),
      operationDate: DateTime.parse(map['operation_date'] as String),
      snapshotPath: map['snapshot_path'] as String?,
      snapshotBytes: map['snapshot_bytes'] as List<int>?,
    );
  }

  EditHistory copyWith({
    int? historyId,
    int? imageId,
    String? operationType,
    Map<String, dynamic>? operationParameters,
    DateTime? operationDate,
    String? snapshotPath,
    List<int>? snapshotBytes,
  }) {
    return EditHistory(
      historyId: historyId ?? this.historyId,
      imageId: imageId ?? this.imageId,
      operationType: operationType ?? this.operationType,
      operationParameters: operationParameters ?? this.operationParameters,
      operationDate: operationDate ?? this.operationDate,
      snapshotPath: snapshotPath ?? this.snapshotPath,
      snapshotBytes: snapshotBytes ?? this.snapshotBytes,
    );
  }
}