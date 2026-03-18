import 'package:hive/hive.dart';
import 'disease_model.dart';

part 'history_model.g.dart';

@HiveType(typeId: 0)
class DetectionHistory extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String imagePath;

  @HiveField(2)
  final String diseaseName;

  @HiveField(3)
  final double confidence;

  @HiveField(4)
  final DateTime timestamp;

  @HiveField(5)
  final Map<String, dynamic>? diseaseDetails;

  DetectionHistory({
    required this.id,
    required this.imagePath,
    required this.diseaseName,
    required this.confidence,
    required this.timestamp,
    this.diseaseDetails,
  });

  factory DetectionHistory.fromPrediction({
    required String imagePath,
    required String diseaseName,
    required double confidence,
    Disease? disease,
  }) {
    return DetectionHistory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      imagePath: imagePath,
      diseaseName: diseaseName,
      confidence: confidence,
      timestamp: DateTime.now(),
      diseaseDetails: disease?.toJson(),
    );
  }

  // Helper getters
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year(s) ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month(s) ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day(s) ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour(s) ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute(s) ago';
    } else {
      return 'Just now';
    }
  }

  String get confidencePercentage =>
      '${(confidence * 100).toStringAsFixed(1)}%';
}