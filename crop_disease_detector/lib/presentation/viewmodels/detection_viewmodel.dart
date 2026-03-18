import 'package:flutter/material.dart';
import 'dart:io';
import '../../data/services/detection_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/models/detection_model.dart';
import '../../data/models/user_model.dart';

class DetectionViewModel extends ChangeNotifier {
  final DetectionService _detectionService = DetectionService();
  final AuthService _authService = AuthService();

  List<Detection> _userDetections = [];
  List<Detection> _publicFeed = [];
  Detection? _selectedDetection;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isUploading = false;

  // Add currentUserId getter
  String? get currentUserId => _authService.currentUser?.uid;

  List<Detection> get userDetections => _userDetections;
  List<Detection> get publicFeed => _publicFeed;
  Detection? get selectedDetection => _selectedDetection;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isUploading => _isUploading;

  // Stream for user detections
  void listenToUserDetections(String userId) {
    _detectionService.getUserDetections(userId).listen((detections) {
      _userDetections = detections;
      notifyListeners();
    });
  }

  // Stream for public feed
  void listenToPublicFeed() {
    _detectionService.getPublicFeed().listen((detections) {
      _publicFeed = detections;
      notifyListeners();
    });
  }

  // Upload new detection
  Future<Detection?> uploadDetection({
    required File imageFile,
    required String diseaseName,
    required double confidence,
    Map<String, dynamic>? diseaseDetails,
    String? notes,
    bool isPublic = true,
    List<String>? tags,
  }) async {
    _isUploading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final userData = await _authService.getUserData(currentUser.uid);
      if (userData == null) throw Exception('User data not found');

      final detection = await _detectionService.uploadDetection(
        userId: currentUser.uid,
        username: userData.username,
        userPhotoURL: userData.photoURL,
        diseaseName: diseaseName,
        confidence: confidence,
        imageFile: imageFile,
        diseaseDetails: diseaseDetails,
        notes: notes,
        isPublic: isPublic,
        tags: tags,
      );

      return detection;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  // Select detection for viewing
  void selectDetection(Detection detection) {
    _selectedDetection = detection;
    notifyListeners();
  }

  // Clear selected detection
  void clearSelectedDetection() {
    _selectedDetection = null;
    notifyListeners();
  }

  // Toggle like
  Future<void> toggleLike(String detectionId) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    try {
      await _detectionService.toggleLike(detectionId, currentUser.uid);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Delete detection
  Future<bool> deleteDetection(String detectionId, String imageURL) async {
    try {
      await _detectionService.deleteDetection(detectionId, imageURL);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Search detections
  Future<List<Detection>> searchDetections(String query) async {
    try {
      return await _detectionService.searchDetections(query);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}