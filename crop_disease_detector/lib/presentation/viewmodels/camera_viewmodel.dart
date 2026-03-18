import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CameraViewModel extends ChangeNotifier {
  final ImagePicker _picker = ImagePicker();
  XFile? _capturedImage;
  bool _isProcessing = false;

  XFile? get capturedImage => _capturedImage;
  bool get isProcessing => _isProcessing;

  Future<void> captureImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        _capturedImage = image;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error capturing image: $e');
    }
  }

  Future<void> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        _capturedImage = image;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void clearImage() {
    _capturedImage = null;
    notifyListeners();
  }

  void setProcessing(bool processing) {
    _isProcessing = processing;
    notifyListeners();
  }
}