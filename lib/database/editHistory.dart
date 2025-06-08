import 'package:hive/hive.dart';

part 'editHistory.g.dart';

@HiveType(typeId: 0)
class EditHistory extends HiveObject {
  @HiveField(0)
  int? historyId;

  @HiveField(1)
  int imageId;

  @HiveField(2)
  String operationType;

  @HiveField(3)
  Map<String, dynamic> operationParameters;

  @HiveField(4)
  DateTime operationDate;

  @HiveField(5)
  String? snapshotPath; // Deprecated

  @HiveField(6)
  List<int>? snapshotBytes;

  EditHistory({
    this.historyId,
    required this.imageId,
    required this.operationType,
    required this.operationParameters,
    required this.operationDate,
    this.snapshotPath,
    this.snapshotBytes,
  });

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

  Map<String, dynamic> toMap() {
    return {
      'historyId': historyId,
      'imageId': imageId,
      'operationType': operationType,
      'operationParameters': operationParameters,
      'operationDate': operationDate.toIso8601String(),
      'snapshotPath': snapshotPath,
      'snapshotBytes': snapshotBytes,
    };
  }


}