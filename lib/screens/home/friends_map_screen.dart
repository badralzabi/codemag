import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../../models/user_model.dart';
import '../../models/user_location_model.dart';
import '../../services/location_service.dart';
import '../../services/db_service.dart';
import '../../widgets/location_settings_sheet.dart';

class FriendsMapScreen extends StatefulWidget {
  final UserModel currentUser;
  const FriendsMapScreen({super.key, required this.currentUser});

  @override
  State<FriendsMapScreen> createState() => _FriendsMapScreenState();
}

class _FriendsMapScreenState extends State<FriendsMapScreen> {
  final _dbService = DatabaseService();
  final _locationService = LocationService();
  
  final MapController _mapController = MapController();
  LatLng _myCurrentLatLng = const LatLng(31.9522, 35.2332); // Default center: Palestine/Jordan region
  bool _permissionGranted = false;
  bool _loadingLocation = true;
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<UserModel?>? _currentUserSubscription;
  List<UserLocationModel> _friendsLocations = [];
  StreamSubscription<List<UserLocationModel>>? _friendsLocationsSubscription;

  @override
  void initState() {
    super.initState();
    _requestAndStartTracking();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _currentUserSubscription?.cancel();
    _friendsLocationsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _requestAndStartTracking() async {
    final Position? position = await _locationService.determinePosition();
    if (position != null) {
      if (mounted) {
        setState(() {
          _myCurrentLatLng = LatLng(position.latitude, position.longitude);
          _permissionGranted = true;
          _loadingLocation = false;
        });
        _mapController.move(_myCurrentLatLng, 13.0);
      }
      
      // Update once immediately
      await _locationService.updateLocation(widget.currentUser, position);

      // Start listening to active location updates
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((Position newPos) {
        if (mounted) {
          setState(() {
            _myCurrentLatLng = LatLng(newPos.latitude, newPos.longitude);
          });
        }
        _locationService.updateLocation(widget.currentUser, newPos);
      });

      // Subscribe to user changes to dynamically update friends location subscription
      _currentUserSubscription?.cancel();
      _currentUserSubscription = _dbService.getUserStream(widget.currentUser.uid).listen((freshUser) {
        if (freshUser != null) {
          _friendsLocationsSubscription?.cancel();
          _friendsLocationsSubscription = _locationService
              .getFriendsLocationsStream(freshUser)
              .listen((locations) {
            if (mounted) {
              setState(() {
                _friendsLocations = locations;
              });
            }
          });
        }
      });
    } else {
      // Fallback location to bypass geolocator block on browsers
      if (mounted) {
        setState(() {
          _myCurrentLatLng = const LatLng(31.9522, 35.2332);
          _permissionGranted = true;
          _loadingLocation = false;
        });
      }
      
      // Subscribe to user changes to dynamically update friends location subscription even on browser fallback
      _currentUserSubscription?.cancel();
      _currentUserSubscription = _dbService.getUserStream(widget.currentUser.uid).listen((freshUser) {
        if (freshUser != null) {
          _friendsLocationsSubscription?.cancel();
          _friendsLocationsSubscription = _locationService
              .getFriendsLocationsStream(freshUser)
              .listen((locations) {
            if (mounted) {
              setState(() {
                _friendsLocations = locations;
              });
            }
          });
        }
      });
    }
  }

  void _openSettings() async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LocationSettingsSheet(currentUser: widget.currentUser),
    );

    if (updated == true) {
      // Re-trigger location updates configuration
      _requestAndStartTracking();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'خريطة الأصدقاء 🗺️',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.privacy_tip_outlined, color: Colors.white),
            onPressed: _openSettings,
            tooltip: 'خصوصية الموقع',
          ),
        ],
      ),
      body: _loadingLocation
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF6366F1)),
                  SizedBox(height: 16),
                  Text(
                    'جاري تحديد موقعك الجغرافي...',
                    style: TextStyle(color: Colors.white, fontFamily: 'Cairo'),
                  ),
                ],
              ),
            )
          : !_permissionGranted
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_off, size: 80, color: Colors.redAccent),
                        const SizedBox(height: 16),
                        const Text(
                          'مطلوب صلاحية الموقع الجغرافي',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'يرجى تفعيل خدمات الموقع الجغرافي ومنح صلاحيات التطبيق لرؤية أصدقائك على الخريطة.',
                          style: TextStyle(color: Colors.grey, fontSize: 14, fontFamily: 'Cairo'),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _requestAndStartTracking,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.my_location, color: Colors.white),
                          label: const Text(
                            'طلب صلاحية الموقع الجغرافي',
                            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _myCurrentLatLng,
                        initialZoom: 13.0,
                        maxZoom: 18.0,
                        minZoom: 3.0,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all & ~InteractiveFlag.rotate, // enable all except rotation for cleaner control
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                          subdomains: const ['a', 'b', 'c', 'd'],
                        ),
                        MarkerLayer(
                          markers: [
                            // Current user marker
                            Marker(
                              point: _myCurrentLatLng,
                              width: 70,
                              height: 70,
                              child: _buildUserLocationMarker(
                                widget.currentUser.avatarUrl,
                                'أنت',
                                isMe: true,
                              ),
                            ),
                            // Friends markers
                            ..._friendsLocations.map((friend) {
                              return Marker(
                                point: LatLng(friend.latitude, friend.longitude),
                                width: 70,
                                height: 70,
                                child: _buildUserLocationMarker(
                                  friend.avatarUrl,
                                  friend.displayName,
                                  isMe: false,
                                ),
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      bottom: 24,
                      right: 16,
                      child: FloatingActionButton(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        onPressed: () {
                          _mapController.move(_myCurrentLatLng, 15.0);
                        },
                        child: const Icon(Icons.my_location),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildUserLocationMarker(String avatarUrl, String name, {required bool isMe}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isMe ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Text(
            name,
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 2),
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isMe ? const Color(0xFF6366F1) : const Color(0xFF10B981),
                  width: 3,
                ),
                boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6, spreadRadius: 1)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.network(
                  avatarUrl.isNotEmpty ? avatarUrl : 'https://ui-avatars.com/api/?name=$name',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey,
                      child: const Icon(Icons.person, size: 20, color: Colors.white),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isMe ? const Color(0xFF6366F1) : const Color(0xFF10B981),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
