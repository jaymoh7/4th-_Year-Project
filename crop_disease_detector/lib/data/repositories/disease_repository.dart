import '../models/disease_model.dart';

class DiseaseRepository {
  // In-memory database of diseases
  final Map<String, Disease> _diseaseDatabase = {
    'Tomato - Early Blight': Disease(
      name: 'Tomato Early Blight',
      description: 'Early blight is a common fungal disease that affects tomatoes, caused by Alternaria solani. It appears as dark spots with concentric rings on lower leaves.',
      causes: [
        'Fungus Alternaria solani',
        'Warm, humid conditions',
        'Poor air circulation',
        'Splash water from rain or irrigation',
      ],
      organicTreatments: [
        'Remove infected leaves immediately',
        'Apply copper-based fungicides',
        'Use neem oil spray weekly',
        'Apply compost tea as foliar spray',
      ],
      chemicalTreatments: [
        'Chlorothalonil-based fungicides',
        'Mancozeb fungicides',
        'Apply at first sign of disease',
      ],
      preventionTips: [
        'Use disease-resistant varieties',
        'Practice crop rotation',
        'Water at base of plants, not leaves',
        'Mulch around plants to prevent soil splash',
        'Provide adequate spacing for air circulation',
      ],
      imageUrl: 'assets/images/early_blight.jpg',
    ),
    'Tomato - Healthy': Disease(
      name: 'Healthy Tomato Plant',
      description: 'Your tomato plant appears healthy with no signs of disease. Continue good care practices to maintain plant health.',
      causes: [],
      organicTreatments: [
        'Continue regular care routine',
        'Monitor for pests regularly',
        'Maintain proper watering schedule',
      ],
      chemicalTreatments: [],
      preventionTips: [
        'Water consistently',
        'Provide adequate sunlight',
        'Use balanced fertilizer',
        'Maintain good air circulation',
        'Inspect plants weekly',
      ],
      imageUrl: 'assets/images/healthy_tomato.jpg',
    ),
    'Tomato - Late Blight': Disease(
      name: 'Tomato Late Blight',
      description: 'Late blight is a serious fungal disease caused by Phytophthora infestans. It appears as water-soaked spots on leaves that quickly turn brown and papery.',
      causes: [
        'Fungus-like organism Phytophthora infestans',
        'Cool, wet weather',
        'Poor air circulation',
        'Infected plant debris',
      ],
      organicTreatments: [
        'Remove and destroy infected plants immediately',
        'Apply copper fungicides preventatively',
        'Use Bacillus subtilis-based products',
      ],
      chemicalTreatments: [
        'Apply fungicides containing chlorothalonil',
        'Use mancozeb or metalaxyl products',
        'Rotate fungicide classes to prevent resistance',
      ],
      preventionTips: [
        'Plant resistant varieties',
        'Ensure good air circulation',
        'Avoid overhead watering',
        'Remove plant debris at season end',
        'Monitor weather forecasts for favorable conditions',
      ],
      imageUrl: 'assets/images/late_blight.jpg',
    ),
  };

  // Get disease details by name
  Disease? getDiseaseByName(String diseaseName) {
    return _diseaseDatabase[diseaseName];
  }

  // Get all diseases
  List<Disease> getAllDiseases() {
    return _diseaseDatabase.values.toList();
  }

  // Add or update disease
  void addDisease(String key, Disease disease) {
    _diseaseDatabase[key] = disease;
  }

  // Search diseases
  List<Disease> searchDiseases(String query) {
    return _diseaseDatabase.values
        .where((disease) =>
        disease.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}