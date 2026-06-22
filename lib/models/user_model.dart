import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String username;
  final String displayName;
  final String avatarUrl;
  final String bio;
  final bool isOnline;
  final DateTime lastSeen;
  final List<String> followers;
  final List<String> following;
  final List<String> savedPosts;
  final bool isVerified;
  final bool isPrivate;
  final List<String> followRequests;
  final int buddyPoints;
  final List<String> unlockedAccessories;
  final String? equippedAccessory;
  final DateTime? lastWheelSpin;
  final List<String> unlockedThemes;
  final List<String> unlockedFrames;
  final String? equippedFrame;
  final List<String> unlockedVerifications;
  final String? equippedVerification;
  final List<String> blockedUsers;
  final List<String> unlockedStickers;
  final List<String> recentStickers;
  final List<String> favoriteStickers;

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    required this.displayName,
    this.avatarUrl = 'https://ui-avatars.com/api/?name=User',
    this.bio = '',
    this.isOnline = true,
    DateTime? lastSeen,
    this.followers = const [],
    this.following = const [],
    this.savedPosts = const [],
    this.isVerified = false,
    this.isPrivate = false,
    this.followRequests = const [],
    this.buddyPoints = 0,
    this.unlockedAccessories = const [],
    this.equippedAccessory,
    this.lastWheelSpin,
    this.unlockedThemes = const ['default'],
    this.unlockedFrames = const [],
    this.equippedFrame,
    this.unlockedVerifications = const [],
    this.equippedVerification,
    this.blockedUsers = const [],
    this.unlockedStickers = const [],
    this.recentStickers = const [],
    this.favoriteStickers = const [],
  }) : lastSeen = lastSeen ?? DateTime.now();

  static List<String> _safeList(dynamic val) {
    if (val == null) return const [];
    if (val is List) {
      return val.map((e) => e.toString()).toList();
    }
    return const [];
  }

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    try {
      final lastSeenData = data['lastSeen'];
      DateTime parsedLastSeen;
      if (lastSeenData is Timestamp) {
        parsedLastSeen = lastSeenData.toDate();
      } else if (lastSeenData is int) {
        parsedLastSeen = DateTime.fromMillisecondsSinceEpoch(lastSeenData);
      } else if (lastSeenData is String) {
        parsedLastSeen = DateTime.tryParse(lastSeenData) ?? DateTime.now();
      } else {
        parsedLastSeen = DateTime.now();
      }

      final wheelSpinData = data['lastWheelSpin'];
      DateTime? parsedWheelSpin;
      if (wheelSpinData is Timestamp) {
        parsedWheelSpin = wheelSpinData.toDate();
      } else if (wheelSpinData is int) {
        parsedWheelSpin = DateTime.fromMillisecondsSinceEpoch(wheelSpinData);
      } else if (wheelSpinData is String) {
        parsedWheelSpin = DateTime.tryParse(wheelSpinData);
      }

      return UserModel(
        uid: documentId,
        email: data['email']?.toString() ?? '',
        username: data['username']?.toString() ?? '',
        displayName: data['displayName']?.toString() ?? '',
        avatarUrl: data['avatarUrl']?.toString() ?? 'https://ui-avatars.com/api/?name=User',
        bio: data['bio']?.toString() ?? '',
        isOnline: data['isOnline'] == true,
        lastSeen: parsedLastSeen,
        followers: _safeList(data['followers']),
        following: _safeList(data['following']),
        savedPosts: _safeList(data['savedPosts']),
        isVerified: data['isVerified'] == true,
        isPrivate: data['isPrivate'] == true,
        followRequests: _safeList(data['followRequests']),
        buddyPoints: data['buddyPoints'] is int ? data['buddyPoints'] as int : 0,
        unlockedAccessories: _safeList(data['unlockedAccessories']),
        equippedAccessory: data['equippedAccessory']?.toString(),
        lastWheelSpin: parsedWheelSpin,
        unlockedThemes: data['unlockedThemes'] != null
            ? _safeList(data['unlockedThemes'])
            : const ['default'],
        unlockedFrames: _safeList(data['unlockedFrames']),
        equippedFrame: data['equippedFrame']?.toString(),
        unlockedVerifications: _safeList(data['unlockedVerifications']),
        equippedVerification: data['equippedVerification']?.toString(),
        blockedUsers: _safeList(data['blockedUsers']),
        unlockedStickers: _safeList(data['unlockedStickers']),
        recentStickers: _safeList(data['recentStickers']),
        favoriteStickers: _safeList(data['favoriteStickers']),
      );
    } catch (e, stack) {
      print('Error parsing UserModel for $documentId: $e\n$stack');
      return UserModel(
        uid: documentId,
        email: data['email']?.toString() ?? '',
        username: data['username']?.toString() ?? 'unknown',
        displayName: data['displayName']?.toString() ?? 'مستخدم غير معروف',
        avatarUrl: 'https://ui-avatars.com/api/?name=User',
        bio: '',
        isOnline: false,
        lastSeen: DateTime.now(),
        followers: const [],
        following: const [],
        savedPosts: const [],
        isVerified: false,
        isPrivate: false,
        followRequests: const [],
         buddyPoints: 0,
        unlockedAccessories: const [],
        equippedAccessory: null,
        lastWheelSpin: null,
        unlockedThemes: const ['default'],
        unlockedFrames: const [],
        equippedFrame: null,
        unlockedVerifications: const [],
        equippedVerification: null,
        blockedUsers: const [],
        unlockedStickers: const [],
        recentStickers: const [],
        favoriteStickers: const [],
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'username': username,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'isOnline': isOnline,
      'lastSeen': Timestamp.fromDate(lastSeen),
      'followers': followers,
      'following': following,
      'savedPosts': savedPosts,
      'isVerified': isVerified,
      'isPrivate': isPrivate,
      'followRequests': followRequests,
      'buddyPoints': buddyPoints,
      'unlockedAccessories': unlockedAccessories,
      if (equippedAccessory != null) 'equippedAccessory': equippedAccessory,
      if (lastWheelSpin != null) 'lastWheelSpin': Timestamp.fromDate(lastWheelSpin!),
      'unlockedThemes': unlockedThemes,
      'unlockedFrames': unlockedFrames,
      if (equippedFrame != null) 'equippedFrame': equippedFrame,
      'unlockedVerifications': unlockedVerifications,
      if (equippedVerification != null) 'equippedVerification': equippedVerification,
      'blockedUsers': blockedUsers,
      'unlockedStickers': unlockedStickers,
      'recentStickers': recentStickers,
      'favoriteStickers': favoriteStickers,
    };
  }
}
