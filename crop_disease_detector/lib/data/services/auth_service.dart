import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Stream of user changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current user
  User? get currentUser => _auth.currentUser;

  // Sign up with email and password
  Future<AppUser?> signUpWithEmail({
    required String email,
    required String password,
    required String username,
    String? displayName,
    String? phoneNumber,
    DateTime? dateOfBirth,
  }) async {
    try {
      // Check if username is unique
      final usernameExists = await _checkUsernameExists(username);
      if (usernameExists) {
        throw Exception('Username already taken');
      }

      // Create user in Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user == null) throw Exception('Failed to create user');

      // Send email verification
      await user.sendEmailVerification();

      // Create user profile in Firestore
      final appUser = AppUser(
        uid: user.uid,
        email: email,
        username: username,
        displayName: displayName,
        phoneNumber: phoneNumber,
        dateOfBirth: dateOfBirth,
        photoURL: user.photoURL,
        isEmailVerified: user.emailVerified,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(appUser.toFirestore());

      return appUser;
    } catch (e) {
      print('Sign up error: $e');
      rethrow;
    }
  }

  // Sign in with email and password
  Future<AppUser?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user == null) throw Exception('Failed to sign in');

      // Update last login
      await _firestore.collection('users').doc(user.uid).update({
        'lastLoginAt': Timestamp.fromDate(DateTime.now()),
      });

      // Get user data from Firestore
      return await getUserData(user.uid);
    } catch (e) {
      print('Sign in error: $e');
      rethrow;
    }
  }

  // Sign in with Google
  Future<AppUser?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;
      if (user == null) throw Exception('Failed to sign in');

      // Check if user exists in Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        // Create new user
        final appUser = AppUser(
          uid: user.uid,
          email: user.email!,
          username: user.email!.split('@')[0],
          displayName: user.displayName,
          photoURL: user.photoURL,
          isEmailVerified: user.emailVerified,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(appUser.toFirestore());

        return appUser;
      } else {
        // Update last login
        await _firestore.collection('users').doc(user.uid).update({
          'lastLoginAt': Timestamp.fromDate(DateTime.now()),
        });

        return AppUser.fromFirestore(userDoc);
      }
    } catch (e) {
      print('Google sign in error: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Get user data from Firestore
  Future<AppUser?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return AppUser.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Get user data error: $e');
      return null;
    }
  }

  // Check if username exists
  Future<bool> _checkUsernameExists(String username) async {
    final query = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Update user profile
  Future<void> updateUserProfile(AppUser user) async {
    await _firestore
        .collection('users')
        .doc(user.uid)
        .update(user.toFirestore());
  }

  // Check if email is verified
  Future<bool> isEmailVerified() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  // Resend verification email
  Future<void> resendVerificationEmail() async {
    await _auth.currentUser?.sendEmailVerification();
  }
}