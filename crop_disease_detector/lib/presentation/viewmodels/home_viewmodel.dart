import 'package:flutter/material.dart';

class HomeViewModel extends ChangeNotifier {
  String _welcomeMessage = "Welcome to Crop Disease Detector";
  bool _isLoading = false;

  String get welcomeMessage => _welcomeMessage;
  bool get isLoading => _isLoading;

  void updateMessage(String message) {
    _welcomeMessage = message;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> navigateToCamera(BuildContext context) async {
    // Navigation will be handled by GoRouter
  }
}