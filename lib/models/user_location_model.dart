import 'package:cloud_firestore/cloud_firestore.dart';

class UserLocationModel {
  final String uid;
  final String displayName;
  final String username;
  final String avatarUrl;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final bool showLocation;
  final List<String> visibleTo; // Users who can see this location. Empty means visible to all followers/following if showLocation is true.

  UserLocationModel({
    required this.uid,
    required this.displayName,
    required this.username,
    required this.avatarUrl,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.showLocation,
    this.visibleTo = const [],
  });

  factory UserLocationModel.fromMap(Map<String, dynamic> data, String id) {
    final timestampData = data['timestamp'];
    DateTime parsedTime = DateTime.now();
    if (timestampData is Timestamp) {
      parsedTime = timestampData.toDate();
    } else if (timestampData is String) {
      parsedTime = DateTime.tryParse(timestampData) ?? DateTime.now();
    }

    return UserLocationModel(
      uid: id,
      displayName: data['displayName']?.toString() ?? '',
      username: data['username']?.toString() ?? '',
      avatarUrl: data['avatarUrl']?.toString() ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      timestamp: parsedTime,
      showLocation: data['showLocation'] ?? true,
      visibleTo: data['visibleTo'] != null
          ? List<String>.from(data['visibleTo'].map((e) => e.toString()))
          : const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'username': username,
      'avatarUrl': avatarUrl,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': Timestamp.fromDate(timestamp),
      'showLocation': showLocation,
      'visibleTo': visibleTo,
    };
  }
}
