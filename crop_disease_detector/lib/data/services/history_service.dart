import 'dart:io';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../models/history_model.dart';

class HistoryService {
  static final HistoryService _instance = HistoryService._internal();
  factory HistoryService() => _instance;
  HistoryService._internal();

  static const String _boxName = 'detection_history';
  late Box<DetectionHistory> _historyBox;

  bool get isInitialized => Hive.isBoxOpen(_boxName);

  Future<void> initialize() async {
    if (!isInitialized) {
      final appDocumentDir = await getApplicationDocumentsDirectory();
      Hive.init(appDocumentDir.path);

      // Register adapter if not already registered
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(DetectionHistoryAdapter());
      }

      try {
        _historyBox = await Hive.openBox<DetectionHistory>(_boxName);
      } catch (e) {
        // If opening fails, try to delete and recreate
        await Hive.deleteBoxFromDisk(_boxName);
        _historyBox = await Hive.openBox<DetectionHistory>(_boxName);
      }
    } else {
      _historyBox = Hive.box<DetectionHistory>(_boxName);
    }
  }

  Future<void> addDetection(DetectionHistory detection) async {
    await initialize();
    await _historyBox.add(detection);
  }

  List<DetectionHistory> getAllDetections() {
    if (!isInitialized) return [];
    return _historyBox.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<DetectionHistory> getRecentDetections({int limit = 10}) {
    final all = getAllDetections();
    return all.take(limit).toList();
  }

  List<DetectionHistory> getDetectionsByDisease(String diseaseName) {
    if (!isInitialized) return [];
    return _historyBox.values
        .where((detection) => detection.diseaseName.toLowerCase().contains(diseaseName.toLowerCase()))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> deleteDetection(DetectionHistory detection) async {
    await initialize();
    await detection.delete();
  }

  Future<void> clearHistory() async {
    await initialize();
    await _historyBox.clear();
  }

  // Get detection by ID
  DetectionHistory? getDetectionById(String id) {
    if (!isInitialized) return null;
    try {
      return _historyBox.values.firstWhere(
            (detection) => detection.id == id,
      );
    } catch (e) {
      return null;
    }
  }

  // Statistics
  Map<String, int> getDiseaseStatistics() {
    if (!isInitialized) return {};
    final stats = <String, int>{};
    for (var detection in _historyBox.values) {
      final diseaseName = detection.diseaseName;
      stats[diseaseName] = (stats[diseaseName] ?? 0) + 1;
    }
    // Sort by count descending
    var sortedEntries = stats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sortedEntries);
  }

  int get totalDetections {
    if (!isInitialized) return 0;
    return _historyBox.length;
  }

  DateTime? get firstDetectionDate {
    if (!isInitialized || _historyBox.isEmpty) return null;
    return _historyBox.values
        .reduce((a, b) => a.timestamp.isBefore(b.timestamp) ? a : b)
        .timestamp;
  }

  DateTime? get lastDetectionDate {
    if (!isInitialized || _historyBox.isEmpty) return null;
    return _historyBox.values
        .reduce((a, b) => a.timestamp.isAfter(b.timestamp) ? a : b)
        .timestamp;
  }

  // Export functionality
  Future<String> exportAsCSV() async {
    await initialize();
    final buffer = StringBuffer();

    // Write headers
    buffer.writeln('ID,Disease Name,Confidence,Date,Image Path');

    // Write data
    for (var detection in getAllDetections()) {
      buffer.writeln(
          '${detection.id},'
              '"${detection.diseaseName}",'
              '${detection.confidence},'
              '"${detection.timestamp.toIso8601String()}",'
              '"${detection.imagePath}"'
      );
    }

    // Save to file
    final appDir = await getApplicationDocumentsDirectory();
    final file = File('${appDir.path}/detection_history_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(buffer.toString());

    return file.path;
  }

  // Search functionality
  List<DetectionHistory> searchDetections(String query) {
    if (!isInitialized || query.isEmpty) return getAllDetections();

    final lowerQuery = query.toLowerCase();
    return _historyBox.values
        .where((detection) =>
    detection.diseaseName.toLowerCase().contains(lowerQuery) ||
        detection.formattedDate.toLowerCase().contains(lowerQuery))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // Get statistics by date range
  Map<String, int> getStatisticsByDateRange(DateTime start, DateTime end) {
    if (!isInitialized) return {};

    final stats = <String, int>{};
    for (var detection in _historyBox.values) {
      if (detection.timestamp.isAfter(start) && detection.timestamp.isBefore(end)) {
        final diseaseName = detection.diseaseName;
        stats[diseaseName] = (stats[diseaseName] ?? 0) + 1;
      }
    }

    // Sort by count descending
    var sortedEntries = stats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sortedEntries);
  }

  // Get detection count by month
  Map<String, int> getDetectionsByMonth() {
    if (!isInitialized) return {};

    final stats = <String, int>{};
    for (var detection in _historyBox.values) {
      final monthYear = '${detection.timestamp.month}/${detection.timestamp.year}';
      stats[monthYear] = (stats[monthYear] ?? 0) + 1;
    }
    return stats;
  }

  // Delete old detections (older than specified days)
  Future<int> deleteOldDetections(int days) async {
    await initialize();
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    int deletedCount = 0;

    for (var detection in _historyBox.values) {
      if (detection.timestamp.isBefore(cutoffDate)) {
        await detection.delete();
        deletedCount++;
      }
    }

    return deletedCount;
  }

  // Check if image file exists
  bool doesImageExist(DetectionHistory detection) {
    try {
      final file = File(detection.imagePath);
      return file.existsSync();
    } catch (e) {
      return false;
    }
  }

  // Get list of detections with missing images
  List<DetectionHistory> getDetectionsWithMissingImages() {
    if (!isInitialized) return [];

    return _historyBox.values
        .where((detection) => !doesImageExist(detection))
        .toList();
  }

  // Update detection (if needed)
  Future<void> updateDetection(DetectionHistory updatedDetection) async {
    await initialize();

    // Find the key for this detection
    final key = _historyBox.keys.firstWhere(
          (k) => _historyBox.get(k)?.id == updatedDetection.id,
      orElse: () => null,
    );

    if (key != null) {
      await _historyBox.put(key, updatedDetection);
    }
  }
}