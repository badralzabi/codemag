import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'home/home_screen.dart';
import 'home/explore_screen.dart';
import 'chat/chat_list_screen.dart';
import 'reels/reels_screen.dart';
import 'profile/profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat/voice_call_screen.dart';
import 'chat/video_call_screen.dart';
import '../models/user_model.dart';
import '../services/db_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math';
import '../widgets/lucky_wheel_dialog.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isWheelShowing = false;

  void _checkAndShowLuckyWheel(String userId) async {
    if (_isWheelShowing) return;

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      final data = userDoc.data() as Map<String, dynamic>;
      final lastSpinVal = data['lastWheelSpin'];
      
      DateTime? lastSpin;
      if (lastSpinVal is Timestamp) {
        lastSpin = lastSpinVal.toDate();
      } else if (lastSpinVal is String) {
        lastSpin = DateTime.tryParse(lastSpinVal);
      }

      final now = DateTime.now();
      if (lastSpin == null || now.difference(lastSpin) >= const Duration(hours: 2)) {
        if (Random().nextDouble() < 0.35) {
          if (mounted) {
            setState(() {
              _isWheelShowing = true;
            });
            
            showDialog(
              context: context,
              barrierDismissible: false,
              barrierColor: Colors.black.withOpacity(0.65),
              builder: (context) => LuckyWheelDialog(userId: userId),
            ).then((_) {
              if (mounted) {
                setState(() {
                  _isWheelShowing = false;
                });
              }
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking lucky wheel: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    if (user == null) return const SizedBox();

    final pages = [
      const HomeScreen(),
      const ExploreScreen(),
      const ReelsScreen(),
      const ChatListScreen(),
      ProfileScreen(uid: user.uid),
    ];

    return Stack(
      children: [
        Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: pages,
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    height: 72,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF0F172A).withOpacity(0.75)
                          : Colors.white.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.05),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.35 : 0.08),
                          blurRadius: 24,
                          spreadRadius: 2,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNavItem(0, Icons.home_outlined, Icons.home, 'الرئيسية', user.uid),
                        _buildNavItem(1, Icons.search_outlined, Icons.search, 'استكشاف', user.uid),
                        _buildNavItem(2, Icons.play_circle_outline, Icons.play_circle_filled, 'ريلز', user.uid),
                        _buildNavItem(3, Icons.chat_bubble_outline, Icons.chat_bubble, 'المحادثات', user.uid),
                        _buildNavItem(4, Icons.person_outline, Icons.person, 'حسابي', user.uid),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Incoming Call Overlay Listener
        StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('calls').doc(user.uid).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.exists) {
              final callData = snapshot.data!.data() as Map<String, dynamic>;
              if (callData['status'] == 'ringing') {
                return Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.85),
                    ),
                    child: StreamBuilder<UserModel?>(
                      stream: DatabaseService().getUserStream(callData['callerId']),
                      builder: (context, callerSnapshot) {
                        final caller = callerSnapshot.data;
                        final isVideo = callData['type'] == 'video';

                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Pulsing Avatar
                              Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withOpacity(0.2), width: 4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isVideo ? Colors.purpleAccent : Colors.blueAccent).withOpacity(0.5),
                                      blurRadius: 40,
                                      spreadRadius: 10,
                                    ),
                                  ],
                                  image: caller != null
                                      ? DecorationImage(image: NetworkImage(caller.avatarUrl), fit: BoxFit.cover)
                                      : null,
                                ),
                                child: caller == null ? const CircularProgressIndicator() : null,
                              ),
                              const SizedBox(height: 32),
                              
                              // Caller Name
                              Text(
                                caller?.displayName ?? callData['callerName'] ?? 'مستخدم',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              // Call Type
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(isVideo ? Icons.videocam : Icons.phone, color: Colors.white70, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    isVideo ? 'مكالمة فيديو واردة...' : 'مكالمة صوتية واردة...',
                                    style: const TextStyle(color: Colors.white70, fontSize: 18),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 60),
                              
                              // Action Buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  // Decline
                                  GestureDetector(
                                    onTap: () async {
                                      await FirebaseFirestore.instance.collection('calls').doc(user.uid).delete();
                                    },
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: const BoxDecoration(
                                            color: Colors.redAccent,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(color: Colors.redAccent, blurRadius: 20, spreadRadius: 2),
                                            ],
                                          ),
                                          child: const Icon(Icons.call_end, color: Colors.white, size: 36),
                                        ),
                                        const SizedBox(height: 12),
                                        const Text('رفض', style: TextStyle(color: Colors.white, fontSize: 16)),
                                      ],
                                    ),
                                  ),
                                  
                                  // Accept
                                  GestureDetector(
                                    onTap: () {
                                      final channelId = callData['channelId'];
                                      final callerId = callData['callerId'];
                                      final isVideo = callData['type'] == 'video';
                                      
                                      // Capture navigator before async gap or before the stream rebuilds
                                      final navigator = Navigator.of(context);
                                      
                                      // Delete the call dialog
                                      FirebaseFirestore.instance.collection('calls').doc(user.uid).delete();
                                      
                                      // Navigate immediately
                                      navigator.push(
                                        MaterialPageRoute(
                                          builder: (context) => isVideo
                                              ? VideoCallScreen(
                                                  channelName: channelId,
                                                  isCaller: false,
                                                  receiverUid: user.uid,
                                                  otherUserUid: callerId,
                                                )
                                              : VoiceCallScreen(
                                                  channelName: channelId,
                                                  isCaller: false,
                                                  receiverUid: user.uid,
                                                  otherUserUid: callerId,
                                                ),
                                        ),
                                      );
                                    },
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: Colors.greenAccent.shade700,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(color: Colors.greenAccent.shade700, blurRadius: 20, spreadRadius: 2),
                                            ],
                                          ),
                                          child: Icon(isVideo ? Icons.videocam : Icons.call, color: Colors.white, size: 36),
                                        ),
                                        const SizedBox(height: 12),
                                        const Text('قبول', style: TextStyle(color: Colors.white, fontSize: 16)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }
                    ),
                  ),
                 ),
                );
              }
            }
            return const SizedBox();
          },
        ),
      ],
    );
  }

  Widget _buildNavItem(int index, IconData normalIcon, IconData selectedIcon, String label, String userId) {
    final isSelected = _selectedIndex == index;
    final primaryColor = const Color(0xFF6366F1); // Indigo

    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        _checkAndShowLuckyWheel(userId);
      },
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selectedIcon : normalIcon,
              color: isSelected ? primaryColor : const Color(0xFF64748B),
              size: 24,
            ).animate(target: isSelected ? 1 : 0)
             .scale(
               begin: const Offset(1, 1),
               end: const Offset(1.12, 1.12),
               curve: Curves.easeOutBack,
               duration: 200.ms,
             ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ).animate().fadeIn(duration: 150.ms).slideX(begin: 0.25, end: 0, curve: Curves.easeOut),
            ],
          ],
        ),
      ),
    );
  }
}
