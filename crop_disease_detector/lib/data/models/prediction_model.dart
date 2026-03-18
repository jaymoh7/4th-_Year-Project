class PredictionModel {
  final String label;
  final double confidence;

  PredictionModel({required this.label, required this.confidence});

  factory PredictionModel.fromMap(Map<String, dynamic> map) {
    return PredictionModel(
      label: map['label'] ?? '',
      confidence: map['confidence']?.toDouble() ?? 0.0,
    );
  }
}