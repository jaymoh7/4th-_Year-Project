import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String username;
  final String? displayName;
  final String? phoneNumber;
  final DateTime? dateOfBirth;
  final String? photoURL;
  final bool isEmailVerified;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final List<String> followers;
  final List<String> following;
  final int totalDetections;
  final Map<String, dynamic>? settings;

  AppUser({
    required this.uid,
    required this.email,
    required this.username,
    this.displayName,
    this.phoneNumber,
    this.dateOfBirth,
    this.photoURL,
    required this.isEmailVerified,
    required this.createdAt,
    required this.lastLoginAt,
    this.followers = const [],
    this.following = const [],
    this.totalDetections = 0,
    this.settings,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      displayName: data['displayName'],
      phoneNumber: data['phoneNumber'],
      dateOfBirth: data['dateOfBirth'] != null
          ? (data['dateOfBirth'] as Timestamp).toDate()
          : null,
      photoURL: data['photoURL'],
      isEmailVerified: data['isEmailVerified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp).toDate(),
      followers: List<String>.from(data['followers'] ?? []),
      following: List<String>.from(data['following'] ?? []),
      totalDetections: data['totalDetections'] ?? 0,
      settings: data['settings'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'username': username,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'photoURL': photoURL,
      'isEmailVerified': isEmailVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
      'followers': followers,
      'following': following,
      'totalDetections': totalDetections,
      'settings': settings ?? {},
    };
  }

  AppUser copyWith({
    String? displayName,
    String? phoneNumber,
    String? photoURL,
    bool? isEmailVerified,
    DateTime? lastLoginAt,
    List<String>? followers,
    List<String>? following,
    int? totalDetections,
    Map<String, dynamic>? settings,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      username: username,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfBirth: dateOfBirth,
      photoURL: photoURL ?? this.photoURL,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      totalDetections: totalDetections ?? this.totalDetections,
      settings: settings ?? this.settings,
    );
  }
}