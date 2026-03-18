import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/detection_model.dart';
import '../models/user_model.dart';

class DetectionService {
  static final DetectionService _instance = DetectionService._internal();
  factory DetectionService() => _instance;
  DetectionService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload detection
  Future<Detection> uploadDetection({
    required String userId,
    required String username,
    String? userPhotoURL,
    required String diseaseName,
    required double confidence,
    required File imageFile,
    Map<String, dynamic>? diseaseDetails,
    String? notes,
    bool isPublic = true,
    List<String>? tags,
  }) async {
    try {
      // Upload image to Firebase Storage
      final imageURL = await _uploadImage(imageFile, userId);

      // Create detection object
      final detection = Detection(
        id: _firestore.collection('detections').doc().id,
        userId: userId,
        username: username,
        userPhotoURL: userPhotoURL,
        diseaseName: diseaseName,
        confidence: confidence,
        imageURL: imageURL,
        localImagePath: imageFile.path,
        diseaseDetails: diseaseDetails,
        timestamp: DateTime.now(),
        notes: notes,
        isPublic: isPublic,
        tags: tags ?? [],
      );

      // Save to Firestore
      await _firestore
          .collection('detections')
          .doc(detection.id)
          .set(detection.toFirestore());

      // Update user's detection count
      await _firestore.collection('users').doc(userId).update({
        'totalDetections': FieldValue.increment(1),
      });

      return detection;
    } catch (e) {
      print('Upload detection error: $e');
      rethrow;
    }
  }

  // Upload image to storage
  Future<String> _uploadImage(File imageFile, String userId) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage
        .ref()
        .child('detections')
        .child(userId)
        .child(fileName);

    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  // Get user's detections
  Stream<List<Detection>> getUserDetections(String userId) {
    return _firestore
        .collection('detections')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Detection.fromFirestore(doc))
          .toList();
    });
  }

  // Get public detections feed
  Stream<List<Detection>> getPublicFeed() {
    return _firestore
        .collection('detections')
        .where('isPublic', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Detection.fromFirestore(doc))
          .toList();
    });
  }

  // Get detections by disease
  Stream<List<Detection>> getDetectionsByDisease(String diseaseName) {
    return _firestore
        .collection('detections')
        .where('diseaseName', isEqualTo: diseaseName)
        .where('isPublic', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Detection.fromFirestore(doc))
          .toList();
    });
  }

  // Like/unlike detection
  Future<void> toggleLike(String detectionId, String userId) async {
    final detectionRef = _firestore.collection('detections').doc(detectionId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(detectionRef);
      if (!snapshot.exists) return;

      final likedBy = List<String>.from(snapshot.data()?['likedBy'] ?? []);

      if (likedBy.contains(userId)) {
        likedBy.remove(userId);
        transaction.update(detectionRef, {
          'likes': FieldValue.increment(-1),
          'likedBy': likedBy,
        });
      } else {
        likedBy.add(userId);
        transaction.update(detectionRef, {
          'likes': FieldValue.increment(1),
          'likedBy': likedBy,
        });
      }
    });
  }

  // Add comment (simplified - you'd want a separate comments collection)
  Future<void> addComment(String detectionId, String userId, String username, String comment) async {
    final commentRef = _firestore
        .collection('detections')
        .doc(detectionId)
        .collection('comments')
        .doc();

    await commentRef.set({
      'userId': userId,
      'username': username,
      'comment': comment,
      'timestamp': Timestamp.now(),
    });

    // Increment comment count
    await _firestore.collection('detections').doc(detectionId).update({
      'comments': FieldValue.increment(1),
    });
  }

  // Get comments for a detection
  Stream<QuerySnapshot> getComments(String detectionId) {
    return _firestore
        .collection('detections')
        .doc(detectionId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Delete detection
  Future<void> deleteDetection(String detectionId, String imageURL) async {
    // Delete from Firestore
    await _firestore.collection('detections').doc(detectionId).delete();

    // Delete image from Storage
    try {
      final ref = _storage.refFromURL(imageURL);
      await ref.delete();
    } catch (e) {
      print('Error deleting image: $e');
    }
  }

  // Search detections
  Future<List<Detection>> searchDetections(String query) async {
    final snapshot = await _firestore
        .collection('detections')
        .where('isPublic', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .get();

    return snapshot.docs
        .map((doc) => Detection.fromFirestore(doc))
        .where((detection) =>
    detection.diseaseName.toLowerCase().contains(query.toLowerCase()) ||
        detection.notes?.toLowerCase().contains(query.toLowerCase()) == true)
        .toList();
  }
}