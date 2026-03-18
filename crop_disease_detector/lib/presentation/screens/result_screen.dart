import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/camera_viewmodel.dart';
import '../viewmodels/history_viewmodel.dart';
import '../../data/services/ml_service.dart';
import '../../data/repositories/disease_repository.dart';
import '../../data/models/disease_model.dart';
import '../../data/models/prediction_model.dart';
import '../../data/models/detection_model.dart';  // Add this import
import '../../data/models/history_model.dart';

class ResultScreen extends StatefulWidget {
  // Update to accept either Detection or DetectionHistory
  final dynamic initialDetection;  // Use dynamic to accept both types

  const ResultScreen({super.key, this.initialDetection});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final MLService _mlService = MLService();
  final DiseaseRepository _diseaseRepo = DiseaseRepository();
  List<PredictionModel> _predictions = [];
  bool _isAnalyzing = true;
  String? _errorMessage;
  bool _isSaved = false;
  String? _imagePath;
  String? _diseaseName;
  double? _confidence;

  @override
  void initState() {
    super.initState();
    _initializeFromDetection();
  }

  void _initializeFromDetection() {
    // Check if we have initial detection
    if (widget.initialDetection != null) {
      // Handle Detection type
      if (widget.initialDetection is Detection) {
        final detection = widget.initialDetection as Detection;
        setState(() {
          _imagePath = detection.localImagePath;
          _diseaseName = detection.diseaseName;
          _confidence = detection.confidence;
          _predictions = [
            PredictionModel(
              label: detection.diseaseName,
              confidence: detection.confidence,
            )
          ];
          _isAnalyzing = false;
          _isSaved = true; // Already saved
        });
      }
      // Handle DetectionHistory type
      else if (widget.initialDetection is DetectionHistory) {
        final history = widget.initialDetection as DetectionHistory;
        setState(() {
          _imagePath = history.imagePath;
          _diseaseName = history.diseaseName;
          _confidence = history.confidence;
          _predictions = [
            PredictionModel(
              label: history.diseaseName,
              confidence: history.confidence,
            )
          ];
          _isAnalyzing = false;
          _isSaved = true; // Already saved
        });
      }
    } else {
      // No initial detection, analyze new image
      _analyzeImage();
    }
  }

  Future<void> _analyzeImage() async {
    try {
      final cameraVM = Provider.of<CameraViewModel>(context, listen: false);
      final imageFile = cameraVM.capturedImage;

      if (imageFile == null) {
        setState(() {
          _errorMessage = 'No image captured';
          _isAnalyzing = false;
        });
        return;
      }

      // Read image bytes
      final imageBytes = await imageFile.readAsBytes();

      // Get predictions
      final predictions = await MLService().predictImage(imageBytes);

      setState(() {
        _predictions = predictions;
        _isAnalyzing = false;
        _imagePath = imageFile.path;
        if (predictions.isNotEmpty) {
          _diseaseName = predictions.first.label;
          _confidence = predictions.first.confidence;
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isAnalyzing = false;
      });
    }
  }

  Future<void> _saveToHistory() async {
    try {
      final cameraVM = Provider.of<CameraViewModel>(context, listen: false);
      final historyVM = Provider.of<HistoryViewModel>(context, listen: false);

      final topPrediction = _predictions.isNotEmpty ? _predictions.first : null;
      if (topPrediction == null) return;

      final diseaseDetails = _diseaseRepo.getDiseaseByName(topPrediction.label);

      final detection = DetectionHistory.fromPrediction(
        imagePath: cameraVM.capturedImage?.path ?? '',
        diseaseName: topPrediction.label,
        confidence: topPrediction.confidence,
        disease: diseaseDetails,
      );

      await historyVM.addDetection(detection);

      setState(() {
        _isSaved = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved to history'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Result'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _predictions.isNotEmpty ? () {} : null,
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.pushNamed(context, '/history');
            },
          ),
        ],
      ),
      body: _isAnalyzing
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Analyzing image...'),
          ],
        ),
      )
          : _errorMessage != null
          ? _buildErrorWidget()
          : _buildResultWidget(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Analysis Failed',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultWidget() {
    final topPrediction = _predictions.isNotEmpty ? _predictions.first : null;
    final diseaseDetails = topPrediction != null
        ? _diseaseRepo.getDiseaseByName(topPrediction.label)
        : null;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Preview
          if (_imagePath != null)
            Hero(
              tag: 'result_image',
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  image: DecorationImage(
                    image: FileImage(File(_imagePath!)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Confidence Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.health_and_safety,
                                color: Colors.green[700],
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _diseaseName ?? topPrediction?.label ?? 'Unknown',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: _confidence ?? topPrediction?.confidence ?? 0,
                                      backgroundColor: Colors.grey[200],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _getConfidenceColor(
                                            _confidence ?? topPrediction?.confidence ?? 0),
                                      ),
                                      minHeight: 8,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Confidence: ${((_confidence ?? topPrediction?.confidence ?? 0) * 100).toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Disease Details
                if (diseaseDetails != null) ...[
                  _buildDetailSection(
                    'Description',
                    diseaseDetails.description,
                    Icons.description,
                  ),

                  if (diseaseDetails.causes.isNotEmpty)
                    _buildListSection(
                      'Causes',
                      diseaseDetails.causes,
                      Icons.warning,
                      Colors.orange,
                    ),

                  if (diseaseDetails.organicTreatments.isNotEmpty)
                    _buildListSection(
                      'Organic Treatments',
                      diseaseDetails.organicTreatments,
                      Icons.eco,
                      Colors.green,
                    ),

                  if (diseaseDetails.chemicalTreatments.isNotEmpty)
                    _buildListSection(
                      'Chemical Treatments',
                      diseaseDetails.chemicalTreatments,
                      Icons.science,
                      Colors.blue,
                    ),

                  _buildListSection(
                    'Prevention Tips',
                    diseaseDetails.preventionTips,
                    Icons.tips_and_updates,
                    Colors.purple,
                  ),
                ],

                const SizedBox(height: 16),

                // Other Possible Diseases
                if (_predictions.length > 1)
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Other Possibilities',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._predictions.skip(1).map((prediction) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(prediction.label),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${(prediction.confidence * 100).toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: _getConfidenceColor(prediction.confidence),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('New Scan'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSaved ? null : _saveToHistory,
                        icon: Icon(_isSaved ? Icons.check : Icons.bookmark),
                        label: Text(_isSaved ? 'Saved' : 'Save'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: _isSaved ? Colors.green : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, String content, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: const TextStyle(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListSection(
      String title,
      List<String> items,
      IconData icon,
      Color color,
      ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(fontSize: 16, color: color)),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(height: 1.5),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.5) return Colors.orange;
    return Colors.red;
  }
}