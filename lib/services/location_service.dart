import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/user_location_model.dart';
import '../models/user_model.dart';

class LocationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream of locations for users who are mutually followed AND allow sharing
  Stream<List<UserLocationModel>> getFriendsLocationsStream(UserModel currentUser) {
    // Friends are people who follow you AND you follow them (mutual follow)
    final mutualFriends = currentUser.following.where((uid) => currentUser.followers.contains(uid)).toList();
    
    if (mutualFriends.isEmpty) {
      return Stream.value([]);
    }

    return _db
        .collection('locations')
        .snapshots()
        .map((snapshot) {
      final List<UserLocationModel> locations = [];
      for (var doc in snapshot.docs) {
        if (!mutualFriends.contains(doc.id)) continue;
        
        final loc = UserLocationModel.fromMap(doc.data(), doc.id);
        
        // Check if location sharing is enabled globally for this user
        if (!loc.showLocation) continue;

        // Check if user set specific visibility restrictions
        if (loc.visibleTo.isNotEmpty && !loc.visibleTo.contains(currentUser.uid)) {
          continue;
        }

        locations.add(loc);
      }
      return locations;
    });
  }

  // Get current user's location settings
  Stream<UserLocationModel?> getUserLocationSettings(String uid) {
    return _db.collection('locations').doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserLocationModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    });
  }

  // Update/Upload location
  Future<void> updateLocation(UserModel user, Position position) async {
    final docRef = _db.collection('locations').doc(user.uid);
    final docSnapshot = await docRef.get();
    
    bool showLocation = true;
    List<String> visibleTo = [];
    
    if (docSnapshot.exists && docSnapshot.data() != null) {
      final data = docSnapshot.data()!;
      showLocation = data['showLocation'] ?? true;
      visibleTo = data['visibleTo'] != null
          ? List<String>.from(data['visibleTo'].map((e) => e.toString()))
          : [];
    }

    await docRef.set({
      'displayName': user.displayName,
      'username': user.username,
      'avatarUrl': user.avatarUrl,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'timestamp': FieldValue.serverTimestamp(),
      'showLocation': showLocation,
      'visibleTo': visibleTo,
    }, SetOptions(merge: true));
  }

  // Update visibility settings
  Future<void> updateVisibilitySettings(String uid, {required bool showLocation, required List<String> visibleTo}) async {
    await _db.collection('locations').doc(uid).set({
      'showLocation': showLocation,
      'visibleTo': visibleTo,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Determine permissions and get current position
  Future<Position?> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return null;
    } 

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 4));
    } catch (e) {
      print("Location fetch timeout/error: $e");
      // Return a default mock position (Palestine center) to let the map load
      return Position(
        latitude: 31.9522,
        longitude: 35.2332,
        timestamp: DateTime.now(),
        accuracy: 0.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
    }
  }
}
