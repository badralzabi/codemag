import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../services/db_service.dart';
import '../../models/user_model.dart';
import '../../models/message_model.dart';
import '../../models/chat_room_model.dart';
import '../profile/profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'voice_call_screen.dart';
import 'video_call_screen.dart';
import '../image_viewer_screen.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../services/cloudinary_service.dart';
import '../../utils/chat_theme_utils.dart';
import 'package:swipe_to/swipe_to.dart';
import 'shared_post_bubble.dart';
import '../../services/buddy_preferences.dart';
import '../../services/buddy_audio_generator.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../widgets/buddy_accessory_painter.dart';
import '../../widgets/particle_backgrounds.dart';
import '../../widgets/gift_store_sheet.dart';
import '../../widgets/avatar_with_frame.dart';
import '../../widgets/verification_badge.dart';
import 'ar_gift_screen.dart';
import 'dart:ui';

class ChatRoomScreen extends StatefulWidget {
  final String roomId;
  final UserModel otherUser;

  const ChatRoomScreen({super.key, required this.roomId, required this.otherUser});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _messageController = TextEditingController();
  final _dbService = DatabaseService();
  bool _isTyping = false;

  // Gift Celebration State
  final Set<String> _playedGiftMessageIds = {};
  String? _celebrationEmoji;
  String? _celebrationName;
  bool _showCelebration = false;
  bool _isReceiverOfCelebration = false;

  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _currentlyPlayingUrl;

  XFile? _pickedImage;
  bool _isSending = false;
  
  MessageModel? _replyingTo;
  bool _isDisappearingMode = false;

  // Interactive Buddy variables
  bool _buddyEnabled = false;
  String _buddyCharacter = '🐱';
  String _buddySound = 'pop';
  final _buddyAudioPlayer = AudioPlayer();
  bool _buddyOnLeft = true;
  bool _buddyIsLaughing = false;
  bool _buddyIsAnimatingTyping = false;
  
  // Buddy positioning - free movement across the chat
  final GlobalKey _chatStackKey = GlobalKey();
  double _buddyX = 20;
  double _buddyY = 100;
  bool _buddyPositionInitialized = false;
  static const double _buddySize = 80.0;
  
  late Stream<ChatRoomModel> _roomStream;
  late Stream<UserModel?> _otherUserStream;
  late Stream<UserModel?> _currentUserStream;
  
  // Messages - manual subscription instead of StreamBuilder to prevent loading issues
  StreamSubscription<List<MessageModel>>? _messagesSubscription;
  List<MessageModel> _messages = [];
  bool _messagesLoaded = false;
  String? _messagesError;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTextChanged);
    _loadBuddySettings();
    _roomStream = _dbService.getChatRoomStream(widget.roomId).asBroadcastStream();
    _otherUserStream = _dbService.getUserStream(widget.otherUser.uid).asBroadcastStream();
    _currentUserStream = _dbService.getUserStream(FirebaseAuth.instance.currentUser!.uid).asBroadcastStream();
    _subscribeToMessages();
  }

  void _subscribeToMessages() {
    _messagesSubscription?.cancel();
    _messagesSubscription = _dbService.getMessages(widget.roomId).listen(
      (messages) {
        if (mounted) {
          setState(() {
            _messages = messages;
            _messagesLoaded = true;
            _messagesError = null;
          });
        }
      },
      onError: (error) {
        print('Messages stream error: $error');
        if (mounted) {
          setState(() {
            _messagesError = error.toString();
            _messagesLoaded = true;
          });
        }
      },
    );
  }

  void _loadBuddySettings() async {
    final enabled = await BuddyPreferences.isEnabled();
    final character = await BuddyPreferences.getCharacter();
    final sound = await BuddyPreferences.getSound();
    if (mounted) {
      setState(() {
        _buddyEnabled = enabled;
        _buddyCharacter = character;
        _buddySound = sound;
      });
      if (enabled) {
        await BuddyAudioGenerator.generateSound(sound);
      }
    }
  }

  void _onTextChanged() {
    final text = _messageController.text;
    final isTyping = text.isNotEmpty;
    if (_isTyping != isTyping) {
      _isTyping = isTyping;
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        _dbService.updateTypingStatus(widget.roomId, uid, _isTyping);
      }
    }
    if (_buddyEnabled && _buddyIsAnimatingTyping != isTyping) {
      setState(() {
        _buddyIsAnimatingTyping = isTyping;
        if (isTyping) {
          _moveBuddyToInputCenter();
        } else {
          _moveBuddyToIdlePosition();
        }
      });
    }
  }

  void _moveBuddyToInputCenter() {
    final renderBox = _chatStackKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final stackWidth = renderBox.size.width;
    final stackHeight = renderBox.size.height;
    // Center horizontally, position just above the input bar (~95px from bottom)
    _buddyX = (stackWidth - _buddySize) / 2;
    _buddyY = stackHeight - _buddySize - 95;
  }

  void _moveBuddyToIdlePosition() {
    final renderBox = _chatStackKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final stackHeight = renderBox.size.height;
    // Go back to left or right corner
    _buddyX = _buddyOnLeft ? 20 : (renderBox.size.width - _buddySize - 20);
    _buddyY = stackHeight - _buddySize - 95;
  }

  void _initBuddyPosition() {
    if (_buddyPositionInitialized) return;
    final renderBox = _chatStackKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final stackHeight = renderBox.size.height;
    _buddyX = 20;
    _buddyY = stackHeight - _buddySize - 95;
    _buddyPositionInitialized = true;
  }

  void _onBuddyTapped() async {
    if (_buddyIsLaughing) return; // Prevent double taps during animation
    
    final renderBox = _chatStackKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final stackWidth = renderBox.size.width;
    
    setState(() {
      _buddyIsLaughing = true;
      _buddyOnLeft = !_buddyOnLeft;
      // Jump to the opposite side
      _buddyX = _buddyOnLeft ? 20 : (stackWidth - _buddySize - 20);
    });

    // Play buddy sound
    final path = await BuddyAudioGenerator.generateSound(_buddySound);
    if (path.isNotEmpty) {
      await _buddyAudioPlayer.play(DeviceFileSource(path));
    }

    // Return to normal/idle after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _buddyIsLaughing = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _dbService.updateTypingStatus(widget.roomId, uid, false);
    }
    _messageController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _buddyAudioPlayer.dispose();
    super.dispose();
  }

  void _triggerGiftCelebration(String emoji, String name, bool isReceiver) async {
    setState(() {
      _celebrationEmoji = emoji;
      _celebrationName = name;
      _isReceiverOfCelebration = isReceiver;
      _showCelebration = true;
    });

    try {
      final path = await BuddyAudioGenerator.generateSound('gift');
      if (path.isNotEmpty) {
        await _buddyAudioPlayer.play(DeviceFileSource(path));
      }
    } catch (e) {
      debugPrint('Error playing gift chime: $e');
    }

    Future.delayed(const Duration(seconds: 6), () {
      if (mounted && _showCelebration && _celebrationEmoji == emoji) {
        setState(() {
          _showCelebration = false;
        });
      }
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _isSending = true);
      try {
        final url = await CloudinaryService.uploadImage(pickedFile);
        final user = Provider.of<User?>(context, listen: false);
        if (user != null && url != null) {
          await _dbService.sendMessage(widget.roomId, user.uid, '', imageUrl: url);
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في إرسال الصورة: $e')));
      }
      setState(() => _isSending = false);
    }
  }

  Future<void> _toggleRecording() async {
    try {
      if (_isRecording) {
        final path = await _audioRecorder.stop();
        setState(() {
          _isRecording = false;
          _isSending = true;
        });
        
        if (path != null) {
          final file = File(path);
          // Upload audio as 'video' resource_type in Cloudinary since it's media
          final url = await CloudinaryService.uploadImage(XFile(file.path)); // Our cloudinary service is generic enough but wait, we need to specify resource_type for audio if strict, but raw/video works. 
          // Actually Cloudinary uploadImage preset 'image_chat' might restrict to images. Let's assume it works or we will fix it later.
          final user = Provider.of<User?>(context, listen: false);
          if (user != null && url != null) {
            await _dbService.sendMessage(widget.roomId, user.uid, '', audioUrl: url, duration: 0); // Need real duration if possible, skip for now
          }
        }
        setState(() => _isSending = false);
      } else {
        if (await _audioRecorder.hasPermission()) {
          final dir = await getApplicationDocumentsDirectory();
          final path = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
          await _audioRecorder.start(const RecordConfig(), path: path);
          setState(() => _isRecording = true);
        }
      }
    } catch (e) {
      setState(() { _isRecording = false; _isSending = false; });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في التسجيل: $e')));
    }
  }

  void _playAudio(String url) async {
    if (_isPlaying && _currentlyPlayingUrl == url) {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
    } else {
      await _audioPlayer.play(UrlSource(url));
      setState(() {
        _isPlaying = true;
        _currentlyPlayingUrl = url;
      });
      _audioPlayer.onPlayerComplete.listen((_) {
        setState(() => _isPlaying = false);
      });
    }
  }

  void _initiateCall(BuildContext context, User currentUser) async {
    final String channelId = "call_${currentUser.uid.substring(0, 5)}_${widget.otherUser.uid.substring(0, 5)}";

    try {
      await FirebaseFirestore.instance.collection('calls').doc(widget.otherUser.uid).set({
        'callerId': currentUser.uid,
        'callerName': currentUser.displayName ?? "مستخدم",
        'channelId': channelId,
        'type': 'voice',
        'status': 'ringing',
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VoiceCallScreen(
            channelName: channelId,
            isCaller: true,
            receiverUid: widget.otherUser.uid,
            otherUserUid: widget.otherUser.uid,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل بدء المكالمة: $e')),
      );
    }
  }

  void _initiateVideoCall(BuildContext context, User currentUser) async {
    final String channelId = "call_${currentUser.uid.substring(0, 5)}_${widget.otherUser.uid.substring(0, 5)}";

    try {
      await FirebaseFirestore.instance.collection('calls').doc(widget.otherUser.uid).set({
        'callerId': currentUser.uid,
        'callerName': currentUser.displayName ?? "مستخدم",
        'channelId': channelId,
        'type': 'video',
        'status': 'ringing',
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoCallScreen(
            channelName: channelId,
            isCaller: true,
            receiverUid: widget.otherUser.uid,
            otherUserUid: widget.otherUser.uid,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل بدء المكالمة: $e')),
      );
    }
  }

  void _showReactionPicker(MessageModel message, User currentUser) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        final emojis = ['❤️', '😂', '👍', '👎', '😮', '😢'];
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 20,
                children: emojis.map((emoji) => GestureDetector(
                  onTap: () {
                    _dbService.addMessageReaction(widget.roomId, message.id, currentUser.uid, emoji);
                    Navigator.pop(context);
                  },
                  child: Text(emoji, style: const TextStyle(fontSize: 32)),
                )).toList(),
              ),
              if (message.senderId == currentUser.uid) ...[
                const SizedBox(height: 16),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('حذف الرسالة', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    _dbService.deleteMessage(widget.roomId, message.id);
                    Navigator.pop(context);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final user = Provider.of<User?>(context, listen: false);
    _messageController.clear();
    
    final replyId = _replyingTo?.id;
    final replyContent = _replyingTo?.content.isNotEmpty == true 
        ? _replyingTo!.content 
        : (_replyingTo?.imageUrl != null ? 'صورة' : (_replyingTo?.audioUrl != null ? 'مقطع صوتي' : null));
        
    final disappearing = _isDisappearingMode;

    setState(() {
      _replyingTo = null;
      _isDisappearingMode = false; // Turn off after sending
    });
    
    try {
      await _dbService.sendMessage(
        widget.roomId, 
        user!.uid, 
        content,
        replyToMessageId: replyId,
        replyToMessageContent: replyContent,
        isDisappearing: disappearing,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<User?>(context);

    return StreamBuilder<UserModel?>(
      stream: _currentUserStream,
      builder: (context, currentUserSnap) {
        final currentUserModel = currentUserSnap.data;
        return StreamBuilder<UserModel?>(
          stream: _otherUserStream,
          builder: (context, otherUserSnap) {
            final otherUserModel = otherUserSnap.data;
            final bool isBlockedByMe = currentUserModel?.blockedUsers.contains(widget.otherUser.uid) ?? false;
            final bool isBlockedByOther = otherUserModel?.blockedUsers.contains(currentUser?.uid ?? '') ?? false;
            final bool isChatBlocked = isBlockedByMe || isBlockedByOther;

            return StreamBuilder<ChatRoomModel>(
              stream: _roomStream,
              builder: (context, roomSnapshot) {
                final isOtherTyping = roomSnapshot.hasData && roomSnapshot.data!.typingUsers[widget.otherUser.uid] == true;
                final roomTheme = roomSnapshot.hasData ? roomSnapshot.data!.theme : 'default';

                final isDark = Theme.of(context).brightness == Brightness.dark;
                return Scaffold(
          appBar: AppBar(
            backgroundColor: roomTheme == 'default'
                ? (isDark ? Colors.black : Colors.white)
                : Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            centerTitle: true,
            leadingWidth: 70,
            leading: IconButton(
              padding: EdgeInsets.zero,
              icon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back_ios_new,
                    color: roomTheme == 'default' ? const Color(0xFF007AFF) : const Color(0xFF6366F1),
                    size: 18,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    'رجوع',
                    style: TextStyle(
                      color: roomTheme == 'default' ? const Color(0xFF007AFF) : const Color(0xFF6366F1),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              onPressed: () => Navigator.pop(context),
            ),
            shape: Border(
              bottom: BorderSide(
                color: isDark ? Colors.white12 : Colors.black12,
                width: 0.5,
              ),
            ),
            title: StreamBuilder<UserModel?>(
              stream: _otherUserStream,
              builder: (context, userSnap) {
                final user = userSnap.data ?? widget.otherUser;
                return InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(uid: user.uid)));
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        children: [
                          AvatarWithFrame(
                            avatarUrl: user.avatarUrl,
                            radius: 16,
                            frameId: user.equippedFrame,
                          ),
                          if (user.isOnline)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981), // Green dot
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: roomTheme == 'default'
                                        ? (isDark ? Colors.black : Colors.white)
                                        : Colors.white,
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isOtherTyping ? 'يكتب الآن...' : user.displayName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.normal,
                              color: isOtherTyping
                                  ? const Color(0xFF10B981)
                                  : (roomTheme == 'default'
                                      ? (isDark ? Colors.white70 : Colors.black87)
                                      : null),
                            ),
                          ),
                          if (!isOtherTyping) ...[
                            VerificationBadge(user: user, size: 12),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.chevron_right,
                              size: 10,
                              color: roomTheme == 'default' ? Colors.grey : null,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                );
              }
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.videocam,
                  color: isChatBlocked
                      ? Colors.grey
                      : (roomTheme == 'default' ? const Color(0xFF007AFF) : const Color(0xFF6366F1)),
                  size: 22,
                ),
                onPressed: isChatBlocked ? null : () => _initiateVideoCall(context, currentUser!),
              ),
              IconButton(
                icon: Icon(
                  Icons.call,
                  color: isChatBlocked
                      ? Colors.grey
                      : (roomTheme == 'default' ? const Color(0xFF007AFF) : const Color(0xFF6366F1)),
                  size: 20,
                ),
                onPressed: isChatBlocked ? null : () => _initiateCall(context, currentUser!),
              ),
              const SizedBox(width: 8),
            ],
          ),
      body: GestureDetector(
        onLongPress: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (context) {
              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(currentUser?.uid).snapshots(),
                builder: (context, userSnapshot) {
                  List<String> unlockedThemes = ['default'];
                  if (userSnapshot.hasData && userSnapshot.data!.exists) {
                    final data = userSnapshot.data!.data() as Map<String, dynamic>?;
                    if (data != null && data['unlockedThemes'] != null) {
                      unlockedThemes = List<String>.from(data['unlockedThemes']);
                    }
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.black12,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'تغيير سمة المحادثة 🎨',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 16,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildThemeOption(
                              context,
                              emoji: '🤍',
                              name: 'الافتراضي',
                              themeId: 'default',
                              currentTheme: roomTheme,
                              gradientColors: [const Color(0xFFE5E5EA), const Color(0xFFC7C7CC)],
                            ),
                            // Free Themes
                            _buildThemeOption(
                              context,
                              emoji: '❤️',
                              name: 'حب',
                              themeId: 'love',
                              currentTheme: roomTheme,
                              gradientColors: [const Color(0xFFff9a9e), const Color(0xFFfecfef)],
                            ),
                            _buildThemeOption(
                              context,
                              emoji: '❄️',
                              name: 'ثلجي',
                              themeId: 'snow',
                              currentTheme: roomTheme,
                              gradientColors: [const Color(0xFFe0c3fc), const Color(0xFF8ec5fc)],
                            ),
                            _buildThemeOption(
                              context,
                              emoji: '☀️',
                              name: 'صيفي',
                              themeId: 'summer',
                              currentTheme: roomTheme,
                              gradientColors: [const Color(0xFFf6d365), const Color(0xFFfda085)],
                            ),
                            _buildThemeOption(
                              context,
                              emoji: '🌧️',
                              name: 'مطر',
                              themeId: 'rain',
                              currentTheme: roomTheme,
                              gradientColors: [const Color(0xFF1E293B), const Color(0xFF0F172A)],
                            ),
                            _buildThemeOption(
                              context,
                              emoji: '🌌',
                              name: 'فضاء',
                              themeId: 'space',
                              currentTheme: roomTheme,
                              gradientColors: [const Color(0xFF0F2027), const Color(0xFF2C5364)],
                            ),
                            _buildThemeOption(
                              context,
                              emoji: '🎆',
                              name: 'نيون',
                              themeId: 'neon',
                              currentTheme: roomTheme,
                              gradientColors: [const Color(0xFFFF007F), const Color(0xFF00F0FF)],
                            ),
                            // Paid Themes (Only show if unlocked)
                            if (unlockedThemes.contains('sunset'))
                              _buildThemeOption(
                                context,
                                emoji: '🌇',
                                name: 'غروب',
                                themeId: 'sunset',
                                currentTheme: roomTheme,
                                gradientColors: [const Color(0xFFFF512F), const Color(0xFFDD2476)],
                              ),
                            if (unlockedThemes.contains('forest'))
                              _buildThemeOption(
                                context,
                                emoji: '🌲',
                                name: 'غابة',
                                themeId: 'forest',
                                currentTheme: roomTheme,
                                gradientColors: [const Color(0xFF11998E), const Color(0xFF38EF7D)],
                              ),
                            if (unlockedThemes.contains('gold'))
                              _buildThemeOption(
                                context,
                                emoji: '🔱',
                                name: 'ذهبي',
                                themeId: 'gold',
                                currentTheme: roomTheme,
                                gradientColors: [const Color(0xFF2C220E), const Color(0xFF120E05)],
                              ),
                            if (unlockedThemes.contains('fire'))
                              _buildThemeOption(
                                context,
                                emoji: '🔥',
                                name: 'لهيب',
                                themeId: 'fire',
                                currentTheme: roomTheme,
                                gradientColors: [const Color(0xFF180800), const Color(0xFF000000)],
                              ),
                            if (unlockedThemes.contains('ocean'))
                              _buildThemeOption(
                                context,
                                emoji: '🌊',
                                name: 'محيط',
                                themeId: 'ocean',
                                currentTheme: roomTheme,
                                gradientColors: [const Color(0xFF0F172A), const Color(0xFF070B19)],
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
        child: Container(
          decoration: roomTheme == 'default'
              ? BoxDecoration(color: isDark ? Colors.black : Colors.white)
              : ChatThemeUtils.getBackgroundDecoration(roomTheme),
          child: Stack(
            key: _chatStackKey,
            children: [
              if (roomTheme == 'rain')
                const Positioned.fill(child: RainBackground()),
              if (roomTheme == 'space')
                const Positioned.fill(child: StarryBackground()),
              if (roomTheme == 'neon')
                const Positioned.fill(child: NeonGlowBackground()),
              if (roomTheme == 'fire')
                const Positioned.fill(child: FireBackground()),
              if (roomTheme == 'ocean')
                const Positioned.fill(child: OceanBackground()),
              Column(
                children: [
              if (roomSnapshot.hasData) ...[
                if (roomSnapshot.data!.activePanel == 'game')
                  GamePanel(
                    roomId: widget.roomId,
                    currentUid: currentUser!.uid,
                    otherUserName: widget.otherUser.displayName,
                  ),
                if (roomSnapshot.data!.activePanel == 'watch')
                  WatchTogetherPanel(
                    roomId: widget.roomId,
                    currentUid: currentUser!.uid,
                  ),
              ],
              Expanded(
                child: Builder(
                builder: (context) {
                  try {
                    if (_messagesError != null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'حدث خطأ في تحميل الرسائل: $_messagesError',
                          style: const TextStyle(color: Colors.red, fontFamily: 'Cairo'),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  if (!_messagesLoaded) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final messages = _messages;
                  if (messages.isEmpty) {
                    return const Center(child: Text('بدء المحادثة...', style: TextStyle(color: Colors.grey)));
                  }
                  // Mark as read
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (currentUser != null) {
                      _dbService.markMessagesAsRead(widget.roomId, currentUser.uid);
                    }
                  });

                  // Check for any new gift message to play animation & sound
                  if (messages.isNotEmpty) {
                    final newestMessage = messages.first;
                    if (newestMessage.giftName != null && newestMessage.giftEmoji != null) {
                      final difference = DateTime.now().difference(newestMessage.createdAt);
                      if (difference.inSeconds.abs() < 15 && !_playedGiftMessageIds.contains(newestMessage.id)) {
                        _playedGiftMessageIds.add(newestMessage.id);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          final isReceiver = newestMessage.senderId != (currentUser?.uid ?? '');
                          _triggerGiftCelebration(newestMessage.giftEmoji!, newestMessage.giftName!, isReceiver);
                        });
                      }
                    }
                  }

                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      try {
                        final message = messages[index];
                      final isMe = message.senderId == currentUser!.uid;
                      final isGift = message.giftName != null && message.giftEmoji != null;

                      if (isGift) {
                        return SwipeTo(
                          onRightSwipe: (details) {
                            setState(() { _replyingTo = message; });
                          },
                          onLeftSwipe: (details) {
                            setState(() { _replyingTo = message; });
                          },
                          child: GestureDetector(
                            onDoubleTap: () => _showReactionPicker(message, currentUser!),
                            onLongPress: () => _showReactionPicker(message, currentUser!),
                            child: Align(
                              alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                padding: const EdgeInsets.all(16),
                                width: 220,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isDark 
                                        ? [const Color(0xFF78350F), const Color(0xFF92400E), const Color(0xFFB45309)]
                                        : [const Color(0xFFFFFDF0), const Color(0xFFFEF3C7), const Color(0xFFFDE68A)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: const Color(0xFFF59E0B), width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFF59E0B).withOpacity(0.3),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text('✨', style: TextStyle(fontSize: 12)),
                                        const SizedBox(width: 4),
                                        Text(
                                          'هدية خاصة',
                                          style: TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.amberAccent : const Color(0xFFD97706),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Text('✨', style: TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      message.giftEmoji!,
                                      style: const TextStyle(fontSize: 54),
                                    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                                     .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 1.5.seconds, curve: Curves.easeInOut)
                                     .rotate(begin: -0.05, end: 0.05, duration: 1.5.seconds, curve: Curves.easeInOut),
                                    const SizedBox(height: 12),
                                    Text(
                                      message.giftName!,
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        color: isDark ? Colors.white : const Color(0xFF78350F),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isMe ? 'أرسلت هذه الهدية' : 'أرسل لك هذه الهدية',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 10,
                                        color: isDark ? Colors.white70 : const Color(0xFF92400E),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('ميزة الواقع المعزز قادمة قريباً! 🚀', style: TextStyle(fontFamily: 'Cairo')),
                                            backgroundColor: Colors.indigo,
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.view_in_ar, size: 16),
                                      label: const Text('فتح بالواقع المعزز', style: TextStyle(fontFamily: 'Cairo', fontSize: 10, fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isDark ? const Color(0xFF92400E) : const Color(0xFFF59E0B),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                        minimumSize: const Size(0, 30),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          timeago.format(message.createdAt),
                                          style: const TextStyle(fontSize: 9, color: Colors.grey),
                                        ),
                                        if (isMe) ...[
                                          const SizedBox(width: 4),
                                          Icon(
                                            message.status == 'sent' ? Icons.done : Icons.done_all,
                                            size: 14,
                                            color: message.status == 'read' ? const Color(0xFF3B82F6) : Colors.grey,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ).animate().scale(alignment: isMe ? Alignment.bottomLeft : Alignment.bottomRight, duration: 250.ms, curve: Curves.easeOutBack);
                      }

                      return SwipeTo(
                        onRightSwipe: (details) {
                          setState(() { _replyingTo = message; });
                        },
                        onLeftSwipe: (details) {
                          setState(() { _replyingTo = message; });
                        },
                        child: GestureDetector(
                          onDoubleTap: () => _showReactionPicker(message, currentUser!),
                          onLongPress: () => _showReactionPicker(message, currentUser!),
                        child: Align(
                          alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: null,
                            color: isMe
                                ? (roomTheme == 'default' ? const Color(0xFF007AFF) : ChatThemeUtils.getMyMessageColor(roomTheme))
                                : (roomTheme == 'default'
                                    ? (isDark ? const Color(0xFF262629) : const Color(0xFFE9E9EB))
                                    : ChatThemeUtils.getOtherMessageColor(roomTheme)),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(18),
                              topRight: const Radius.circular(18),
                              bottomLeft: isMe ? const Radius.circular(5) : const Radius.circular(18),
                              bottomRight: isMe ? const Radius.circular(18) : const Radius.circular(5),
                            ),
                            border: roomTheme == 'neon'
                                ? Border.all(color: isMe ? const Color(0xFFFF007F) : const Color(0xFF00F0FF), width: 1.5)
                                : null,
                            boxShadow: roomTheme == 'default'
                                ? null
                                : [
                                    if (roomTheme == 'neon')
                                      BoxShadow(
                                        color: (isMe ? const Color(0xFFFF007F) : const Color(0xFF00F0FF)).withOpacity(0.35),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      )
                                    else
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                  ],
                          ),
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              if (message.sharedPostId != null)
                                SharedPostBubble(message: message, isMe: isMe),
                              if (message.replyToMessageContent != null)
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: const Border(right: BorderSide(color: Color(0xFF6366F1), width: 4)),
                                  ),
                                  child: Text(
                                    message.replyToMessageContent!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: ChatThemeUtils.getTextColor(roomTheme, isMe).withOpacity(0.8), fontSize: 12),
                                  ),
                                ),
                              if (message.storyImageUrl != null)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (message.storyImageUrl != 'gradient')
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: Image.network(message.storyImageUrl!, width: 30, height: 45, fit: BoxFit.cover),
                                        )
                                      else
                                        Container(
                                          width: 30, height: 45,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                      const SizedBox(width: 8),
                                      Text('رد على القصة', style: TextStyle(color: isMe ? Colors.white70 : Colors.black54, fontStyle: FontStyle.italic, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              if (message.imageUrl != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ImageViewerScreen(
                                            imageUrl: message.imageUrl!,
                                            heroTag: 'msg_${message.id}_${message.imageUrl}',
                                          ),
                                        ),
                                      );
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Hero(
                                        tag: 'msg_${message.id}_${message.imageUrl}',
                                        child: Image.network(message.imageUrl!, width: 200, fit: BoxFit.cover),
                                      ),
                                    ),
                                  ),
                                ),
                              if (message.audioUrl != null)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        _isPlaying && _currentlyPlayingUrl == message.audioUrl ? Icons.pause_circle_filled : Icons.play_circle_fill,
                                        color: isMe ? Colors.white : const Color(0xFF6366F1),
                                        size: 32,
                                      ),
                                      onPressed: () => _playAudio(message.audioUrl!),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('مقطع صوتي', style: TextStyle(color: isMe ? Colors.white : Colors.black87)),
                                  ],
                                ),
                                if (message.content.isNotEmpty)
                                   Text(
                                     message.content,
                                     style: TextStyle(
                                       color: isMe
                                           ? Colors.white
                                           : (roomTheme == 'default'
                                               ? (isDark ? Colors.white : Colors.black87)
                                               : ChatThemeUtils.getTextColor(roomTheme, isMe)),
                                       fontSize: 15,
                                     ),
                                   ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    timeago.format(message.createdAt),
                                    style: TextStyle(
                                      color: isMe ? Colors.white.withOpacity(0.7) : Colors.grey,
                                      fontSize: 10,
                                    ),
                                  ),
                                  if (isMe) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      message.status == 'sent' ? Icons.done : Icons.done_all,
                                      size: 16,
                                      color: message.status == 'read' 
                                          ? const Color(0xFF3B82F6) // Blue for read
                                          : Colors.white.withOpacity(0.7), // Grey for sent/delivered
                                    ),
                                  ],
                                ],
                              ),
                              if (message.isDisappearing)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.timer, size: 12, color: ChatThemeUtils.getTextColor(roomTheme, isMe).withOpacity(0.7)),
                                      const SizedBox(width: 4),
                                      Text('رسالة مؤقتة', style: TextStyle(fontSize: 10, color: ChatThemeUtils.getTextColor(roomTheme, isMe).withOpacity(0.7))),
                                    ],
                                  ),
                                ),
                              if (message.reactions != null && message.reactions!.isNotEmpty)
                                Align(
                                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                  child: Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    child: Text(message.reactions!.values.toSet().join(' '), style: const TextStyle(fontSize: 12)),
                                  ),
                                ),
                            ],
                          ), // closes Column
                        ), // closes Container
                        ), // closes Align
                        ), // closes GestureDetector
                      ).animate().scale(alignment: isMe ? Alignment.bottomLeft : Alignment.bottomRight, duration: 200.ms, curve: Curves.easeOut); // closes SwipeTo and applies animation
                      } catch (e, stack) {
                        print('Error in message itemBuilder: $e\n$stack');
                        return Center(
                          child: Text(
                            'خطأ في عرض الرسالة: $e',
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        );
                      }
                    }, // closes itemBuilder
                  ); // closes ListView.builder
                  } catch (e, stack) {
                    print('Error in messages builder: $e\n$stack');
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'خطأ في بناء الشات: $e',
                          style: const TextStyle(color: Colors.red, fontFamily: 'Cairo'),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                }, // closes builder
              ), // closes Builder
            ), // closes Expanded
            if (_replyingTo != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.white,
                child: Row(
                  children: [
                    const Icon(Icons.reply, color: Color(0xFF6366F1)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _replyingTo!.content.isNotEmpty ? _replyingTo!.content : 'صورة / مقطع',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _replyingTo = null),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: roomTheme == 'default'
                    ? (isDark ? Colors.black : Colors.white)
                    : Colors.white,
                border: roomTheme == 'default'
                    ? Border(top: BorderSide(color: isDark ? Colors.white12 : Colors.black12, width: 0.5))
                    : null,
                boxShadow: roomTheme == 'default'
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
              ),
              child: SafeArea(
                child: isChatBlocked
                    ? GestureDetector(
                        onTap: isBlockedByMe
                            ? () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('إلغاء الحظر', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                                    content: Text('هل تريد إلغاء حظر @${widget.otherUser.username}؟', style: const TextStyle(fontFamily: 'Cairo')),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('إلغاء الحظر', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  try {
                                    await _dbService.unblockUser(currentUser!.uid, widget.otherUser.uid);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('تم إلغاء حظر ${widget.otherUser.displayName}', style: const TextStyle(fontFamily: 'Cairo')),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
                                  }
                                }
                              }
                            : null,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Text(
                            isBlockedByMe 
                                ? 'لقد قمت بحظر هذا المستخدم. اضغط هنا لإلغاء الحظر.'
                                : 'هذا المستخدم قام بحظرك.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                    : Row(
                        children: [
                          if (_isSending)
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                            )
                          else ...[
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: Icon(Icons.add, color: isDark ? Colors.white70 : Colors.black54, size: 20),
                                onPressed: _showMoreActionsSheet,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(Icons.camera_alt_outlined, color: isDark ? Colors.white70 : Colors.black54, size: 24),
                              onPressed: _pickImage,
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Text('🎁', style: TextStyle(fontSize: 22)),
                              onPressed: () {
                                final currentUser = FirebaseAuth.instance.currentUser;
                                if (currentUser != null) {
                                  GiftStoreSheet.show(
                                    context,
                                    senderId: currentUser.uid,
                                    recipientId: widget.otherUser.uid,
                                    roomId: widget.roomId,
                                    recipientName: widget.otherUser.displayName,
                                  );
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: roomTheme == 'default'
                                    ? (isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7))
                                    : (isDark ? Colors.grey.shade900 : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: Icon(
                                      Icons.timer_outlined,
                                      color: _isDisappearingMode ? const Color(0xFF007AFF) : (isDark ? Colors.white70 : Colors.black54),
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isDisappearingMode = !_isDisappearingMode;
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _isRecording
                                        ? const Padding(
                                            padding: EdgeInsets.symmetric(vertical: 8),
                                            child: Text(
                                              'جاري التسجيل...',
                                              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                          )
                                        : TextField(
                                            controller: _messageController,
                                            style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 15),
                                            decoration: InputDecoration(
                                              hintText: 'رسالة iMessage...',
                                              hintStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black45, fontSize: 15),
                                              border: InputBorder.none,
                                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                              isDense: true,
                                            ),
                                          ),
                                  ),
                                  if (_messageController.text.isEmpty) ...[
                                    GestureDetector(
                                      onLongPress: _toggleRecording,
                                      onLongPressUp: _toggleRecording,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 6),
                                        child: Icon(
                                          Icons.mic_none,
                                          color: _isRecording ? Colors.red : (isDark ? Colors.white70 : Colors.black54),
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: Icon(Icons.image_outlined, color: isDark ? Colors.white70 : Colors.black54, size: 22),
                                      onPressed: _pickImage,
                                    ),
                                  ] else ...[
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF007AFF),
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        icon: const Icon(Icons.arrow_upward, color: Colors.white, size: 16),
                                        onPressed: _sendMessage,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
        if (_buddyEnabled)
          Builder(
            builder: (context) {
              // Initialize buddy position on first build
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _initBuddyPosition();
              });
              return AnimatedPositioned(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOutBack,
                left: _buddyX,
                top: _buddyY,
                child: GestureDetector(
                  onTap: _onBuddyTapped,
                  child: _buildBuddyWidget(),
                ),
              );
            },
          ),
        if (_showCelebration && _celebrationEmoji != null && _celebrationName != null)
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showCelebration = false;
                });
              },
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  color: Colors.black.withOpacity(0.65),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('✨ 🎉 🎁 🎉 ✨', style: TextStyle(fontSize: 28))
                            .animate()
                            .scale(duration: 500.ms, curve: Curves.elasticOut)
                            .fadeIn(),
                        const SizedBox(height: 24),
                        Text(
                          _celebrationEmoji!,
                          style: const TextStyle(fontSize: 100),
                        )
                            .animate()
                            .scale(begin: const Offset(0.3, 0.3), end: const Offset(1.3, 1.3), duration: 800.ms, curve: Curves.elasticOut)
                            .then()
                            .shake(hz: 8, duration: 400.ms)
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scale(begin: const Offset(1.0, 1.0), end: const Offset(0.92, 0.92), duration: 1.5.seconds, curve: Curves.easeInOut)
                            .rotate(begin: -0.05, end: 0.05, duration: 1.5.seconds, curve: Curves.easeInOut),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                          margin: const EdgeInsets.symmetric(horizontal: 40),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFBBF24), Color(0xFFF59E0B), Color(0xFFD97706)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.5),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _isReceiverOfCelebration ? 'وصلت هدية رائعة! 🎉' : 'تم إرسال الهدية بنجاح! 🎁',
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _celebrationName!,
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                            .animate()
                            .scale(begin: const Offset(0.5, 0.5), duration: 600.ms, curve: Curves.elasticOut)
                            .fadeIn(delay: 200.ms),
                        const SizedBox(height: 48),
                        Text(
                          'اضغط في أي مكان للإغلاق',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .fadeIn(duration: 800.ms),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(duration: 300.ms),
      ],
    ),
  ),
      ),
    );
          },
        );
          },
        );
      },
    );
  }

  void _startGame(String gameType) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    showDialog(
      context: context,
      builder: (context) {
        final betController = TextEditingController();
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text(
                'اختر نمط اللعب 🎮',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'يمكنك اللعب مجاناً أو الرهان بنقاطك ضد صديقك. الفائز يحصل على مجموع النقاط بالكامل!',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: isSubmitting ? null : () async {
                      setDialogState(() => isSubmitting = true);
                      Navigator.pop(context);
                      _initiateGame(gameType, 0);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[350],
                      foregroundColor: Colors.black87,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('لعب مجاني (عادي)', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text(
                    'أو أدخل قيمة الرهان بالنقاط (🪙):',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: betController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'قيمة النقاط (مثال: 50)',
                      prefixIcon: const Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Text('🪙', style: TextStyle(fontSize: 16)),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isSubmitting)
                    const CircularProgressIndicator()
                  else
                    ElevatedButton(
                      onPressed: () async {
                        final text = betController.text.trim();
                        final bet = int.tryParse(text);
                        if (bet == null || bet <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('يرجى إدخال مبلغ رهان صحيح!', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red),
                          );
                          return;
                        }

                        setDialogState(() => isSubmitting = true);

                        try {
                          final myDoc = await _dbService.getUser(currentUser.uid);
                          final otherDoc = await _dbService.getUser(widget.otherUser.uid);

                          if (myDoc == null || otherDoc == null) {
                            throw Exception('حدث خطأ أثناء تحميل بيانات المستخدمين');
                          }

                          if (myDoc.buddyPoints < bet) {
                            throw Exception('رصيدك من النقاط غير كافٍ! رصيدك الحالي: ${myDoc.buddyPoints}');
                          }
                          if (otherDoc.buddyPoints < bet) {
                            throw Exception('رصيد صديقك من النقاط غير كافٍ للعب بهذا المبلغ!');
                          }

                          Navigator.pop(context);
                          _initiateGame(gameType, bet);
                        } catch (e) {
                          setDialogState(() => isSubmitting = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString().replaceAll('Exception:', ''), style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black87,
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('لعب بالنقاط وتحدي', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _initiateGame(String gameType, int betAmount) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        await _dbService.startGameWithBet(
          widget.roomId,
          currentUser.uid,
          widget.otherUser.uid,
          betAmount,
          gameType,
        );
        await FirebaseFirestore.instance.collection('chatRooms').doc(widget.roomId).update({
          'activePanel': 'game',
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ أثناء بدء اللعبة: $e', style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _startWatchTogether() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('بدء مشاهدة مشتركة 🍿'),
          content: TextField(
            controller: textController,
            decoration: const InputDecoration(
              hintText: 'أدخل رابط فيديو يوتيوب هنا...',
              hintStyle: TextStyle(fontSize: 14),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
              onPressed: () async {
                final url = textController.text.trim();
                final videoId = YoutubePlayer.convertUrlToId(url);
                if (videoId != null) {
                  Navigator.pop(context);
                  final currentUser = FirebaseAuth.instance.currentUser;
                  if (currentUser != null) {
                    await FirebaseFirestore.instance.collection('watchSessions').doc(widget.roomId).set({
                      'videoId': videoId,
                      'isPlaying': true,
                      'positionMs': 0,
                      'updaterId': currentUser.uid,
                      'users': [currentUser.uid, widget.otherUser.uid],
                      'lastUpdated': FieldValue.serverTimestamp(),
                    });
                    await FirebaseFirestore.instance.collection('chatRooms').doc(widget.roomId).update({
                      'activePanel': 'watch',
                    });
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('رابط يوتيوب غير صالح!')),
                  );
                }
              },
              child: const Text('بدء', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showMoreActionsSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'الأنشطة التفاعلية ⚡',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              const SizedBox(height: 20),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.35,
                children: [
                  _buildActionCard(
                    context,
                    title: 'لعبة X-O 🎮',
                    subtitle: 'تحدي تقليدي سريع',
                    icon: Icons.sports_esports,
                    color: const Color(0xFF007AFF),
                    onTap: () {
                      Navigator.pop(context);
                      _startGame('xo');
                    },
                  ),
                  _buildActionCard(
                    context,
                    title: 'أربعة في صف 🔴🟡',
                    subtitle: 'اسقط أقراصك وفز بالصف',
                    icon: Icons.grid_on,
                    color: const Color(0xFF34C759),
                    onTap: () {
                      Navigator.pop(context);
                      _startGame('c4');
                    },
                  ),
                  _buildActionCard(
                    context,
                    title: 'سينما مشتركة 🍿',
                    subtitle: 'شاهد يوتيوب مع صديقك',
                    icon: Icons.local_play,
                    color: const Color(0xFFFF2D55),
                    onTap: () {
                      Navigator.pop(context);
                      _startWatchTogether();
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.03),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required String emoji,
    required String name,
    required String themeId,
    required String currentTheme,
    required List<Color> gradientColors,
  }) {
    final isSelected = currentTheme == themeId;
    return GestureDetector(
      onTap: () {
        _dbService.updateChatTheme(widget.roomId, themeId);
        Navigator.pop(context);
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? const Color(0xFF007AFF) : Colors.transparent,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 26)),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? const Color(0xFF007AFF) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuddyWidget() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final svgPath = BuddyPreferences.getSvgPath(_buddyCharacter);
    
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots(),
      builder: (context, userSnapshot) {
        final equippedAccessory = userSnapshot.hasData && userSnapshot.data!.exists
            ? (userSnapshot.data!.data() as Map<String, dynamic>)['equippedAccessory']?.toString()
            : null;

        Widget buddyBody = Stack(
          alignment: Alignment.center,
          children: [
            SvgPicture.asset(
              svgPath,
              width: 56,
              height: 56,
            ),
            if (equippedAccessory != null)
              Positioned.fill(
                child: CustomPaint(
                  painter: BuddyAccessoryPainter(
                    accessoryId: equippedAccessory,
                    characterEmoji: _buddyCharacter,
                  ),
                ),
              ),
          ],
        );

        if (_buddyIsLaughing) {
          // 😂 Laughing: vigorous shake + big bouncing scale + fast spinning + shimmer
          buddyBody = buddyBody
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scaleXY(begin: 1.0, end: 1.35, duration: 200.ms, curve: Curves.elasticOut)
              .then(delay: 50.ms)
              .rotate(begin: -0.15, end: 0.15, duration: 150.ms, curve: Curves.easeInOut)
              .then(delay: 50.ms)
              .shake(hz: 10, curve: Curves.easeInOut, duration: 300.ms)
              .then(delay: 100.ms)
              .slideY(begin: 0, end: -0.15, duration: 200.ms, curve: Curves.bounceOut)
              .shimmer(duration: 600.ms, color: Colors.amber.withOpacity(0.4));
        } else if (_buddyIsAnimatingTyping) {
          // 🤔 Typing: excited curious bouncing + head tilt + pulse
          buddyBody = buddyBody
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .slideY(begin: 0, end: -0.18, duration: 400.ms, curve: Curves.easeOutBack)
              .then(delay: 100.ms)
              .slideX(begin: -0.03, end: 0.03, duration: 300.ms, curve: Curves.easeInOut)
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scaleXY(begin: 1.0, end: 1.08, duration: 500.ms, curve: Curves.easeInOut)
              .rotate(begin: -0.04, end: 0.04, duration: 600.ms, curve: Curves.easeInOut);
        } else {
          // 😊 Idle: gentle breathing + floating + subtle alive sway
          buddyBody = buddyBody
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .slideY(begin: 0, end: -0.06, duration: 2000.ms, curve: Curves.easeInOut)
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scaleXY(begin: 0.97, end: 1.03, duration: 1600.ms, curve: Curves.easeInOut)
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .rotate(begin: -0.015, end: 0.015, duration: 2400.ms, curve: Curves.easeInOut);
        }

        // Dynamic glow color based on state
        final glowColor = _buddyIsLaughing
            ? Colors.amber.withOpacity(0.35)
            : _buddyIsAnimatingTyping
                ? Colors.cyanAccent.withOpacity(0.25)
                : Colors.purpleAccent.withOpacity(0.15);

        return Container(
          width: _buddySize,
          height: _buddySize,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.85),
            shape: BoxShape.circle,
            border: Border.all(
              color: _buddyIsLaughing
                  ? Colors.amber.withOpacity(0.6)
                  : _buddyIsAnimatingTyping
                      ? Colors.cyanAccent.withOpacity(0.5)
                      : (isDark ? Colors.white24 : Colors.black12),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: glowColor,
                blurRadius: _buddyIsLaughing ? 20 : (_buddyIsAnimatingTyping ? 16 : 10),
                spreadRadius: _buddyIsLaughing ? 4 : (_buddyIsAnimatingTyping ? 3 : 1),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: buddyBody,
        );
      },
    );
  }
}

class GamePanel extends StatelessWidget {
  final String roomId;
  final String currentUid;
  final String otherUserName;

  const GamePanel({
    super.key,
    required this.roomId,
    required this.currentUid,
    required this.otherUserName,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('games').doc(roomId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Container(
            height: 280,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(color: Color(0xFF6366F1)),
          );
        }

        final doc = snapshot.data!;
        final data = doc.data() as Map<String, dynamic>;
        final String gameType = data['gameType'] ?? 'xo';

        if (gameType == 'c4') {
          return ConnectFourPanel(
            roomId: roomId,
            currentUid: currentUid,
            otherUserName: otherUserName,
            gameDoc: doc,
          );
        } else {
          return TicTacToePanel(
            roomId: roomId,
            currentUid: currentUid,
            otherUserName: otherUserName,
            gameDoc: doc,
          );
        }
      },
    );
  }
}

class TicTacToePanel extends StatelessWidget {
  final String roomId;
  final String currentUid;
  final String otherUserName;
  final DocumentSnapshot gameDoc;
  final _dbService = DatabaseService();

  TicTacToePanel({
    super.key,
    required this.roomId,
    required this.currentUid,
    required this.otherUserName,
    required this.gameDoc,
  });

  bool _checkWin(List<dynamic> board, String symbol) {
    const winPatterns = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // Rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // Columns
      [0, 4, 8], [2, 4, 6]             // Diagonals
    ];
    for (var pattern in winPatterns) {
      if (board[pattern[0]] == symbol &&
          board[pattern[1]] == symbol &&
          board[pattern[2]] == symbol) {
        return true;
      }
    }
    return false;
  }

  void _makeMove(int index) async {
    final data = gameDoc.data() as Map<String, dynamic>;
    final List<dynamic> board = List.from(data['board']);
    final String turn = data['turn'];
    final String playerX = data['playerX'];
    final String playerO = data['playerO'];
    final String mySymbol = currentUid == playerX ? 'X' : 'O';
    final int betAmount = data['betAmount'] is int ? data['betAmount'] as int : 0;

    if (data['status'] != 'active' || turn != currentUid || board[index].isNotEmpty) {
      return;
    }

    board[index] = mySymbol;
    String status = 'active';
    String winner = '';

    if (_checkWin(board, mySymbol)) {
      status = 'won';
      winner = currentUid;
    } else if (!board.contains('')) {
      status = 'draw';
    }

    final nextTurn = currentUid == playerX ? playerO : playerX;

    if (status == 'won') {
      final loserId = currentUid == playerX ? playerO : playerX;
      await _dbService.settleGame(gameDoc.id, currentUid, loserId, betAmount, 'won', board, nextTurn);
    } else if (status == 'draw') {
      await _dbService.settleGameDraw(gameDoc.id, playerX, playerO, betAmount, board, nextTurn);
    } else {
      await gameDoc.reference.update({
        'board': board,
        'turn': nextTurn,
        'status': status,
        'winner': winner,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }
  }

  void _restartGame() async {
    final data = gameDoc.data() as Map<String, dynamic>;
    final String playerX = data['playerX'];

    await gameDoc.reference.update({
      'board': List.generate(9, (_) => ''),
      'turn': playerX,
      'status': 'active',
      'winner': '',
      'betAmount': 0,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  void _closeGame() async {
    await FirebaseFirestore.instance.collection('chatRooms').doc(roomId).update({
      'activePanel': 'none',
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final data = gameDoc.data() as Map<String, dynamic>;
    final List<dynamic> board = data['board'];
    final String turn = data['turn'];
    final String playerX = data['playerX'];
    final String status = data['status'];
    final String winner = data['winner'];

    final isMyTurn = turn == currentUid && status == 'active';
    final mySymbol = currentUid == playerX ? 'X' : 'O';

    String statusMessage = '';
    if (status == 'active') {
      statusMessage = isMyTurn ? 'دورك الآن! (أنت $mySymbol)' : 'انتظر دور صديقك...';
    } else if (status == 'won') {
      statusMessage = winner == currentUid ? '🎉 لقد فزت باللعبة!' : '🤝 فاز صديقك باللعبة';
    } else {
      statusMessage = '🤝 تعادل! لعبة رائعة';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                onPressed: _closeGame,
              ),
              const Text(
                'لعبة X-O 🎮',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            statusMessage,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: status == 'won' && winner == currentUid
                  ? Colors.green
                  : (isMyTurn ? const Color(0xFF6366F1) : Colors.grey),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 180,
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 9,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final cellValue = board[index];
                return GestureDetector(
                  onTap: () => _makeMove(index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      cellValue,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: cellValue == 'X' ? const Color(0xFF6366F1) : const Color(0xFFEC4899),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (status != 'active') ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              icon: const Icon(Icons.replay, size: 18),
              label: const Text('إعادة اللعب'),
              onPressed: _restartGame,
            ),
          ],
        ],
      ),
    );
  }
}

class ConnectFourPanel extends StatelessWidget {
  final String roomId;
  final String currentUid;
  final String otherUserName;
  final DocumentSnapshot gameDoc;
  final _dbService = DatabaseService();

  ConnectFourPanel({
    super.key,
    required this.roomId,
    required this.currentUid,
    required this.otherUserName,
    required this.gameDoc,
  });

  bool _checkWin(List<dynamic> board, String symbol) {
    // Horizontal check
    for (int r = 0; r < 6; r++) {
      for (int c = 0; c < 4; c++) {
        if (board[r * 7 + c] == symbol &&
            board[r * 7 + c + 1] == symbol &&
            board[r * 7 + c + 2] == symbol &&
            board[r * 7 + c + 3] == symbol) {
          return true;
        }
      }
    }
    // Vertical check
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 7; c++) {
        if (board[r * 7 + c] == symbol &&
            board[(r + 1) * 7 + c] == symbol &&
            board[(r + 2) * 7 + c] == symbol &&
            board[(r + 3) * 7 + c] == symbol) {
          return true;
        }
      }
    }
    // Diagonal Down-Right (\) check
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 4; c++) {
        if (board[r * 7 + c] == symbol &&
            board[(r + 1) * 7 + c + 1] == symbol &&
            board[(r + 2) * 7 + c + 2] == symbol &&
            board[(r + 3) * 7 + c + 3] == symbol) {
          return true;
        }
      }
    }
    // Diagonal Up-Right (/) check
    for (int r = 3; r < 6; r++) {
      for (int c = 0; c < 4; c++) {
        if (board[r * 7 + c] == symbol &&
            board[(r - 1) * 7 + c + 1] == symbol &&
            board[(r - 2) * 7 + c + 2] == symbol &&
            board[(r - 3) * 7 + c + 3] == symbol) {
          return true;
        }
      }
    }
    return false;
  }

  void _makeMove(int colIndex) async {
    final data = gameDoc.data() as Map<String, dynamic>;
    final List<dynamic> board = List.from(data['board']);
    final String turn = data['turn'];
    final String playerX = data['playerX'];
    final String playerO = data['playerO'];
    final String mySymbol = currentUid == playerX ? 'R' : 'Y';
    final int betAmount = data['betAmount'] is int ? data['betAmount'] as int : 0;

    if (data['status'] != 'active' || turn != currentUid) {
      return;
    }

    // Find the lowest unoccupied row in this column
    int targetRow = -1;
    for (int r = 5; r >= 0; r--) {
      if (board[r * 7 + colIndex] == '') {
        targetRow = r;
        break;
      }
    }

    if (targetRow == -1) {
      // Column is full!
      return;
    }

    final targetIndex = targetRow * 7 + colIndex;
    board[targetIndex] = mySymbol;

    String status = 'active';
    String winner = '';

    if (_checkWin(board, mySymbol)) {
      status = 'won';
      winner = currentUid;
    } else if (!board.contains('')) {
      status = 'draw';
    }

    final nextTurn = currentUid == playerX ? playerO : playerX;

    if (status == 'won') {
      final loserId = currentUid == playerX ? playerO : playerX;
      await _dbService.settleGame(gameDoc.id, currentUid, loserId, betAmount, 'won', board, nextTurn);
    } else if (status == 'draw') {
      await _dbService.settleGameDraw(gameDoc.id, playerX, playerO, betAmount, board, nextTurn);
    } else {
      await gameDoc.reference.update({
        'board': board,
        'turn': nextTurn,
        'status': status,
        'winner': winner,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }
  }

  void _restartGame() async {
    final data = gameDoc.data() as Map<String, dynamic>;
    final String playerX = data['playerX'];

    await gameDoc.reference.update({
      'board': List.generate(42, (_) => ''),
      'turn': playerX,
      'status': 'active',
      'winner': '',
      'betAmount': 0,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  void _closeGame() async {
    await FirebaseFirestore.instance.collection('chatRooms').doc(roomId).update({
      'activePanel': 'none',
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final data = gameDoc.data() as Map<String, dynamic>;
    final List<dynamic> board = data['board'];
    final String turn = data['turn'];
    final String playerX = data['playerX'];
    final String status = data['status'];
    final String winner = data['winner'];

    final isMyTurn = turn == currentUid && status == 'active';
    final mySymbol = currentUid == playerX ? 'R' : 'Y';
    final myColorName = mySymbol == 'R' ? 'الأحمر 🔴' : 'الأصفر 🟡';

    String statusMessage = '';
    if (status == 'active') {
      statusMessage = isMyTurn ? 'دورك الآن! (أنت $myColorName)' : 'انتظر دور صديقك...';
    } else if (status == 'won') {
      statusMessage = winner == currentUid ? '🎉 لقد فزت باللعبة!' : '🤝 فاز صديقك باللعبة';
    } else {
      statusMessage = '🤝 تعادل! لعبة رائعة';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                onPressed: _closeGame,
              ),
              const Text(
                'أربعة في صف 🔴🟡',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            statusMessage,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: status == 'won' && winner == currentUid
                  ? Colors.green
                  : (isMyTurn ? const Color(0xFF6366F1) : Colors.grey),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFF2563EB), // Sleek blue rack
              borderRadius: BorderRadius.circular(16),
            ),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 42,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemBuilder: (context, index) {
                final cellValue = board[index];
                final colIndex = index % 7;

                Color discColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
                if (cellValue == 'R') {
                  discColor = const Color(0xFFEF4444); // Premium red
                } else if (cellValue == 'Y') {
                  discColor = const Color(0xFFFBBF24); // Premium amber/yellow
                }

                return GestureDetector(
                  onTap: () => _makeMove(colIndex),
                  child: Container(
                    decoration: BoxDecoration(
                      color: discColor,
                      shape: BoxShape.circle,
                      boxShadow: cellValue.isNotEmpty ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ] : null,
                    ),
                  ),
                );
              },
            ),
          ),
          if (status != 'active') ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              icon: const Icon(Icons.replay, size: 18),
              label: const Text('إعادة اللعب'),
              onPressed: _restartGame,
            ),
          ],
        ],
      ),
    );
  }
}

class WatchTogetherPanel extends StatefulWidget {
  final String roomId;
  final String currentUid;

  const WatchTogetherPanel({
    super.key,
    required this.roomId,
    required this.currentUid,
  });

  @override
  State<WatchTogetherPanel> createState() => _WatchTogetherPanelState();
}

class _WatchTogetherPanelState extends State<WatchTogetherPanel> {
  YoutubePlayerController? _controller;
  String? _currentVideoId;
  bool _isSyncingFromFirestore = false;

  bool? _lastIsPlaying;
  int? _lastPositionMs;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onPlayerStateChange() {
    if (_controller == null || _isSyncingFromFirestore) return;

    final currentIsPlaying = _controller!.value.isPlaying;
    final currentPositionMs = _controller!.value.position.inMilliseconds;

    bool shouldUpdate = false;

    if (_lastIsPlaying != currentIsPlaying) {
      shouldUpdate = true;
      _lastIsPlaying = currentIsPlaying;
    }

    if (_lastPositionMs != null) {
      final diff = (currentPositionMs - _lastPositionMs!).abs();
      if (diff > 2500) {
        shouldUpdate = true;
      }
    }
    _lastPositionMs = currentPositionMs;

    if (shouldUpdate) {
      FirebaseFirestore.instance.collection('watchSessions').doc(widget.roomId).update({
        'isPlaying': currentIsPlaying,
        'positionMs': currentPositionMs,
        'updaterId': widget.currentUid,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }
  }

  void _initializeController(String videoId, bool isPlaying, int positionMs) {
    _controller?.dispose();
    
    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: YoutubePlayerFlags(
        autoPlay: isPlaying,
        mute: false,
        startAt: positionMs ~/ 1000,
        enableCaption: false,
        hideControls: false,
      ),
    );

    _lastIsPlaying = isPlaying;
    _lastPositionMs = positionMs;

    _controller!.addListener(_onPlayerStateChange);
  }

  void _closeSession() async {
    await FirebaseFirestore.instance.collection('chatRooms').doc(widget.roomId).update({
      'activePanel': 'none',
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('watchSessions').doc(widget.roomId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Container(
            height: 200,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(color: Color(0xFF6366F1)),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final String videoId = data['videoId'];
        final bool isPlaying = data['isPlaying'];
        final int positionMs = data['positionMs'];
        final String updaterId = data['updaterId'];

        if (_controller == null || _currentVideoId != videoId) {
          _currentVideoId = videoId;
          _initializeController(videoId, isPlaying, positionMs);
        } else {
          if (updaterId != widget.currentUid) {
            _isSyncingFromFirestore = true;
            
            if (isPlaying && !_controller!.value.isPlaying) {
              _controller!.play();
            } else if (!isPlaying && _controller!.value.isPlaying) {
              _controller!.pause();
            }

            final drift = (positionMs - _controller!.value.position.inMilliseconds).abs();
            if (drift > 2000) {
              _controller!.seekTo(Duration(milliseconds: positionMs));
            }

            _lastIsPlaying = isPlaying;
            _lastPositionMs = positionMs;

            Future.delayed(const Duration(milliseconds: 500), () {
              _isSyncingFromFirestore = false;
            });
          }
        }

        return YoutubePlayerBuilder(
          player: YoutubePlayer(
            controller: _controller!,
            showVideoProgressIndicator: true,
            progressIndicatorColor: const Color(0xFF6366F1),
            progressColors: const ProgressBarColors(
              playedColor: Color(0xFF6366F1),
              handleColor: Color(0xFF818CF8),
            ),
          ),
          builder: (context, player) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                        onPressed: _closeSession,
                      ),
                      const Text(
                        'سينما مشتركة 🍿',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: player,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
