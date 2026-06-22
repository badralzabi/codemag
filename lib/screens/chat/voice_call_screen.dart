import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:ui';
import '../../services/db_service.dart';
import '../../models/user_model.dart';

class VoiceCallScreen extends StatefulWidget {
  final String channelName;
  final bool isCaller;
  final String receiverUid;
  final String otherUserUid;

  const VoiceCallScreen({
    super.key,
    required this.channelName,
    required this.isCaller,
    required this.receiverUid,
    required this.otherUserUid,
  });

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen>
    with TickerProviderStateMixin {
  final String _appId = "15883aeb9838405a8e4fee9495242003";
  late RtcEngine _engine;

  // Call state
  bool _localUserJoined = false;
  bool _isMuted = false;
  bool _isSpeakerOn = false; // Default: earpiece (سماعة داخلية)

  // Timer
  int _secondsElapsed = 0;
  Timer? _callTimer;

  // Animation for pulse effect
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initAgora();
  }

  Future<void> _initAgora() async {
    await [Permission.microphone].request();

    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(appId: _appId));

    // Set default audio route to earpiece (سماعة داخلية)
    await _engine.setDefaultAudioRouteToSpeakerphone(false);

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          setState(() => _localUserJoined = true);
          _startTimer();
        },
        onUserJoined:
            (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("Remote user $remoteUid joined");
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          _endCall();
        },
        onAudioRoutingChanged: (routing) {
          // routing: 0=default, 1=headset, 2=earpiece, 3=speakerphone, 4=bluetooth
          debugPrint("Audio routing changed: $routing");
        },
      ),
    );

    await _engine.enableAudio();
    await _engine.joinChannel(
      token: '',
      channelId: widget.channelName,
      uid: 0,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );
  }

  void _startTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _secondsElapsed++);
    });
  }

  void _toggleSpeaker() {
    setState(() => _isSpeakerOn = !_isSpeakerOn);
    _engine.setEnableSpeakerphone(_isSpeakerOn);
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    _engine.muteLocalAudioStream(_isMuted);
  }

  void _endCall() async {
    _callTimer?.cancel();
    await FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.receiverUid)
        .delete();

    if (mounted) {
      await _engine.leaveChannel();
      Navigator.pop(context);
    }
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _pulseController.dispose();
    _engine.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: StreamBuilder<UserModel?>(
        stream: DatabaseService().getUserStream(widget.otherUserUid),
        builder: (context, snapshot) {
          final otherUser = snapshot.data;
          
          return Stack(
            children: [
              // Background Gradient and Avatar
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF1E293B), Colors.black],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ScaleTransition(
                          scale: _pulseAnimation,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.15), width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blueAccent.withOpacity(0.3),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                              image: otherUser != null
                                  ? DecorationImage(image: NetworkImage(otherUser.avatarUrl), fit: BoxFit.cover)
                                  : null,
                            ),
                            child: otherUser == null ? const CircularProgressIndicator() : null,
                          ),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          otherUser?.displayName ?? 'جاري الاتصال...',
                          style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _localUserJoined ? 'يرن...' : 'جاري الاتصال...',
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Top Overlay (Name & Timer)
              if (otherUser != null)
                Positioned(
                  top: 50,
                  left: 20,
                  right: 20,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: NetworkImage(otherUser.avatarUrl),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    otherUser.displayName,
                                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    _formatDuration(_secondsElapsed),
                                    style: TextStyle(color: Colors.greenAccent.shade400, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              
              // Bottom Controls
              Positioned(
                bottom: 30,
                left: 20,
                right: 20,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildControlButton(
                            icon: _isMuted ? Icons.mic_off : Icons.mic,
                            isActive: !_isMuted,
                            onTap: _toggleMute,
                          ),
                          GestureDetector(
                            onTap: _endCall,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: Colors.redAccent, blurRadius: 10, spreadRadius: 2),
                                ],
                              ),
                              child: const Icon(Icons.call_end, color: Colors.white, size: 32),
                            ),
                          ),
                          _buildControlButton(
                            icon: _isSpeakerOn ? Icons.volume_up : Icons.hearing,
                            isActive: _isSpeakerOn,
                            onTap: _toggleSpeaker,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildControlButton({required IconData icon, required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isActive ? Colors.white : Colors.white54, size: 28),
      ),
    );
  }
}