import 'dart:io';  // Add this import for File
import 'package:flutter/material.dart';
import '../../data/services/history_service.dart';  // Fix the path
import '../../data/models/history_model.dart';

class HistoryViewModel extends ChangeNotifier {
  final HistoryService _historyService = HistoryService();  // Now this will work
  List<DetectionHistory> _detections = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  List<DetectionHistory> get detections => _searchQuery.isEmpty
      ? _detections
      : _detections.where((d) =>
      d.diseaseName.toLowerCase().contains(_searchQuery.toLowerCase())
  ).toList();

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalCount => _detections.length;

  Future<void> loadHistory() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _historyService.initialize();
      _detections = _historyService.getAllDetections();
    } catch (e) {
      _errorMessage = 'Failed to load history: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void search(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> addDetection(DetectionHistory detection) async {
    try {
      await _historyService.addDetection(detection);
      await loadHistory(); // Reload to get updated list
    } catch (e) {
      _errorMessage = 'Failed to save detection: $e';
      notifyListeners();
    }
  }

  Future<void> deleteDetection(DetectionHistory detection) async {
    try {
      await _historyService.deleteDetection(detection);
      _detections.remove(detection);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to delete: $e';
      notifyListeners();
    }
  }

  Future<void> clearAllHistory() async {
    try {
      await _historyService.clearHistory();
      _detections.clear();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to clear history: $e';
      notifyListeners();
    }
  }

  Map<String, int> getStatistics() {
    return _historyService.getDiseaseStatistics();
  }
}