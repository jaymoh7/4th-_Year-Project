class Disease {
  final String name;
  final String description;
  final List<String> causes;
  final List<String> organicTreatments;
  final List<String> chemicalTreatments;
  final List<String> preventionTips;
  final String imageUrl;

  Disease({
    required this.name,
    required this.description,
    required this.causes,
    required this.organicTreatments,
    required this.chemicalTreatments,
    required this.preventionTips,
    required this.imageUrl,
  });

  factory Disease.fromJson(Map<String, dynamic> json) {
    return Disease(
      name: json['name'],
      description: json['description'],
      causes: List<String>.from(json['causes']),
      organicTreatments: List<String>.from(json['organicTreatments']),
      chemicalTreatments: List<String>.from(json['chemicalTreatments']),
      preventionTips: List<String>.from(json['preventionTips']),
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'causes': causes,
      'organicTreatments': organicTreatments,
      'chemicalTreatments': chemicalTreatments,
      'preventionTips': preventionTips,
      'imageUrl': imageUrl,
    };
  }
}

class PredictionResult {
  final String diseaseName;
  final double confidence;
  final Disease? diseaseDetails;

  PredictionResult({
    required this.diseaseName,
    required this.confidence,
    this.diseaseDetails,
  });
}