import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/db_service.dart';
import '../services/location_service.dart';

class LocationSettingsSheet extends StatefulWidget {
  final UserModel currentUser;
  const LocationSettingsSheet({super.key, required this.currentUser});

  @override
  State<LocationSettingsSheet> createState() => _LocationSettingsSheetState();
}

class _LocationSettingsSheetState extends State<LocationSettingsSheet> {
  final _locationService = LocationService();
  final _dbService = DatabaseService();
  bool _showLocation = true;
  List<String> _visibleTo = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final doc = await FirebaseFirestore.instance.collection('locations').doc(widget.currentUser.uid).get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      if (mounted) {
        setState(() {
          _showLocation = data['showLocation'] ?? true;
          _visibleTo = data['visibleTo'] != null
              ? List<String>.from(data['visibleTo'].map((e) => e.toString()))
              : [];
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _saveSettings() async {
    setState(() => _isLoading = true);
    await _locationService.updateVisibilitySettings(
      widget.currentUser.uid,
      showLocation: _showLocation,
      visibleTo: _visibleTo,
    );
    if (mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ إعدادات الخصوصية للموقع بنجاح', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Friends list (mutual follow)
    final mutualFriendsUids = widget.currentUser.following.where((uid) => widget.currentUser.followers.contains(uid)).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B), // Dark slate premium theme
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade600,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'خصوصية الموقع 📍',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Cairo',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'اختر من يستطيع رؤية موقعك الجغرافي على الخريطة.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontFamily: 'Cairo',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SwitchListTile(
                  activeColor: const Color(0xFF6366F1),
                  title: const Text(
                    'إظهار الموقع على الخريطة',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                  ),
                  subtitle: const Text(
                    'عند الإيقاف، سيختفي موقعك تماماً عن الجميع',
                    style: TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Cairo'),
                  ),
                  value: _showLocation,
                  onChanged: (val) {
                    setState(() {
                      _showLocation = val;
                    });
                  },
                ),
                const Divider(color: Colors.grey, height: 24),
                if (_showLocation) ...[
                  const Text(
                    'رؤية مخصصة للأصدقاء:',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (mutualFriendsUids.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'لا يوجد أصدقاء مشتركين حالياً لتحديد خصوصيتهم.',
                        style: TextStyle(color: Colors.grey, fontFamily: 'Cairo', fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: mutualFriendsUids.length,
                        itemBuilder: (context, index) {
                          final friendUid = mutualFriendsUids[index];
                          return FutureBuilder<UserModel?>(
                            future: _dbService.getUser(friendUid),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return const SizedBox.shrink();
                              final friend = snapshot.data!;
                              final isSelected = _visibleTo.isEmpty || _visibleTo.contains(friend.uid);

                              return CheckboxListTile(
                                activeColor: const Color(0xFF6366F1),
                                title: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundImage: NetworkImage(friend.avatarUrl),
                                      radius: 18,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      friend.displayName,
                                      style: const TextStyle(color: Colors.white, fontFamily: 'Cairo'),
                                    ),
                                  ],
                                ),
                                value: isSelected,
                                onChanged: (checked) {
                                  setState(() {
                                    if (checked == true) {
                                      // If it was empty (meaning all), populate it with everyone except the newly selected one which is already there, wait:
                                      // To make it simple: if list is empty, user checks it, it remains empty or we add it.
                                      // Let's implement absolute selection: if _visibleTo is empty, it means "All Friends".
                                      // Once they uncheck one, we fill _visibleTo with all friends EXCEPT the unchecked one.
                                      if (_visibleTo.isEmpty) {
                                        _visibleTo = List.from(mutualFriendsUids);
                                      }
                                      if (!_visibleTo.contains(friend.uid)) {
                                        _visibleTo.add(friend.uid);
                                      }
                                      // If we selected everyone, we can just make it empty again to signify "All Friends"
                                      if (_visibleTo.length == mutualFriendsUids.length) {
                                        _visibleTo.clear();
                                      }
                                    } else {
                                      if (_visibleTo.isEmpty) {
                                        _visibleTo = List.from(mutualFriendsUids);
                                      }
                                      _visibleTo.remove(friend.uid);
                                    }
                                  });
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    'حفظ الإعدادات',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo'),
                  ),
                ),
              ],
            ),
    );
  }
}

// Location settings sheet with Firestore support
