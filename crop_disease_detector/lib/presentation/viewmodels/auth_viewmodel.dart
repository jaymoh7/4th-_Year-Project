import 'package:firebase_auth/firebase_auth.dart';  // Add this import for User
import 'package:flutter/material.dart';
import '../../data/services/auth_service.dart';
import '../../data/models/user_model.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AppUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;
  bool get isEmailVerified => _currentUser?.isEmailVerified ?? false;

  AuthViewModel() {
    _authService.authStateChanges.listen((User? user) {
      if (user != null) {
        _loadUserData(user.uid);
      } else {
        _currentUser = null;
        _isAuthenticated = false;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserData(String uid) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _authService.getUserData(uid);
      _isAuthenticated = _currentUser != null;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String username,
    String? displayName,
    String? phoneNumber,
    DateTime? dateOfBirth,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.signUpWithEmail(
        email: email,
        password: password,
        username: username,
        displayName: displayName,
        phoneNumber: phoneNumber,
        dateOfBirth: dateOfBirth,
      );

      _currentUser = user;
      _isAuthenticated = user != null;
      return user != null;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.signInWithEmail(email, password);
      _currentUser = user;
      _isAuthenticated = user != null;
      return user != null;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.signInWithGoogle();
      _currentUser = user;
      _isAuthenticated = user != null;
      return user != null;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      _currentUser = null;
      _isAuthenticated = false;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendVerificationEmail() async {
    try {
      await _authService.resendVerificationEmail();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> checkEmailVerification() async {
    final verified = await _authService.isEmailVerified();
    if (verified && _currentUser != null) {
      _currentUser = _currentUser!.copyWith(isEmailVerified: true);
      await _authService.updateUserProfile(_currentUser!);
      notifyListeners();
    }
    return verified;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}