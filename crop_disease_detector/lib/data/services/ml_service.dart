import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_plus/tflite_plus.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';
import '../models/prediction_model.dart';

class MLService {
  static final MLService _instance = MLService._internal();
  factory MLService() => _instance;
  MLService._internal();

  bool _isModelLoaded = false;
  final List<PredictionModel> _sampleResults = [
    PredictionModel(label: 'Tomato - Early Blight', confidence: 0.95),
    PredictionModel(label: 'Tomato - Healthy', confidence: 0.03),
    PredictionModel(label: 'Tomato - Late Blight', confidence: 0.02),
  ];

  Future<void> loadModel() async {
    if (_isModelLoaded) return;

    try {
      // In a real app, you would load your actual model file
      // String? res = await TflitePlus.loadModel(
      //   model: "assets/models/plant_disease_model.tflite",
      //   labels: "assets/models/labels.txt",
      //   numThreads: 1,
      //   isAsset: true,
      //   useGpuDelegate: false,
      // );

      // For now, we'll simulate loading
      await Future.delayed(const Duration(seconds: 1));
      _isModelLoaded = true;
      debugPrint('Model loaded successfully');
    } catch (e) {
      debugPrint('Failed to load model: $e');
      throw Exception('Failed to load model: $e');
    }
  }

  Future<List<PredictionModel>> predictImage(Uint8List imageBytes) async {
    if (!_isModelLoaded) {
      await loadModel();
    }

    try {
      // Process the image
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) throw Exception('Failed to decode image');

      // Resize image to model input size (typically 224x224 for most models)
      img.Image resizedImage = img.copyResize(image, width: 224, height: 224);

      // Convert image to byte array
      List<int> imageInts = resizedImage.getBytes();
      Uint8List processedBytes = Uint8List.fromList(imageInts);

      // In a real app, you would run inference here:
      // var recognitions = await TflitePlus.runModelOnBinary(
      //   binary: processedBytes,
      //   inputType: 'image',
      // );

      // For development, return sample results
      await Future.delayed(const Duration(seconds: 2)); // Simulate processing

      // Sort by confidence descending
      _sampleResults.sort((a, b) => b.confidence.compareTo(a.confidence));

      return _sampleResults;
    } catch (e) {
      debugPrint('Prediction error: $e');
      throw Exception('Failed to analyze image: $e');
    }
  }

  Future<void> disposeModel() async {
    if (_isModelLoaded) {
      // await TflitePlus.close();
      _isModelLoaded = false;
    }
  }

  // Helper method to preprocess image for the model
  Uint8List _preprocessImage(img.Image image) {
    // Normalize pixel values to [0,1] or [-1,1] based on model requirements
    // This is model-specific
    return Uint8List.fromList(image.getBytes());
  }
}