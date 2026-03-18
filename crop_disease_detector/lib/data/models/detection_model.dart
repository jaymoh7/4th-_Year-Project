import 'package:cloud_firestore/cloud_firestore.dart';

class Detection {
  final String id;
  final String userId;
  final String username;
  final String? userPhotoURL;
  final String diseaseName;
  final double confidence;
  final String imageURL;
  final String? localImagePath;
  final Map<String, dynamic>? diseaseDetails;
  final DateTime timestamp;
  final String? notes;
  final LocationInfo? location;
  final int likes;
  final List<String> likedBy;
  final int comments;
  final bool isPublic;
  final List<String> tags;

  Detection({
    required this.id,
    required this.userId,
    required this.username,
    this.userPhotoURL,
    required this.diseaseName,
    required this.confidence,
    required this.imageURL,
    this.localImagePath,
    this.diseaseDetails,
    required this.timestamp,
    this.notes,
    this.location,
    this.likes = 0,
    this.likedBy = const [],
    this.comments = 0,
    this.isPublic = true,
    this.tags = const [],
  });

  factory Detection.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Detection(
      id: doc.id,
      userId: data['userId'] ?? '',
      username: data['username'] ?? 'Anonymous',
      userPhotoURL: data['userPhotoURL'],
      diseaseName: data['diseaseName'] ?? 'Unknown',
      confidence: (data['confidence'] ?? 0).toDouble(),
      imageURL: data['imageURL'] ?? '',
      localImagePath: data['localImagePath'],
      diseaseDetails: data['diseaseDetails'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      notes: data['notes'],
      location: data['location'] != null
          ? LocationInfo.fromMap(data['location'])
          : null,
      likes: data['likes'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      comments: data['comments'] ?? 0,
      isPublic: data['isPublic'] ?? true,
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'username': username,
      'userPhotoURL': userPhotoURL,
      'diseaseName': diseaseName,
      'confidence': confidence,
      'imageURL': imageURL,
      'localImagePath': localImagePath,
      'diseaseDetails': diseaseDetails,
      'timestamp': Timestamp.fromDate(timestamp),
      'notes': notes,
      'location': location?.toMap(),
      'likes': likes,
      'likedBy': likedBy,
      'comments': comments,
      'isPublic': isPublic,
      'tags': tags,
    };
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class LocationInfo {
  final double latitude;
  final double longitude;
  final String? address;
  final String? city;
  final String? country;

  LocationInfo({
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
    this.country,
  });

  factory LocationInfo.fromMap(Map<String, dynamic> map) {
    return LocationInfo(
      latitude: map['latitude'] ?? 0.0,
      longitude: map['longitude'] ?? 0.0,
      address: map['address'],
      city: map['city'],
      country: map['country'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'city': city,
      'country': country,
    };
  }
}