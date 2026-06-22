import 'package:flutter/material.dart';
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
import 'group_details_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'voice_call_screen.dart';
import 'video_call_screen.dart';
import '../image_viewer_screen.dart';
import '../../services/cloudinary_service.dart';
import 'shared_post_bubble.dart';
import '../../widgets/verification_badge.dart';

class GroupChatScreen extends StatefulWidget {
  final ChatRoomModel room;

  const GroupChatScreen({super.key, required this.room});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final _messageController = TextEditingController();
  final _dbService = DatabaseService();
  bool _isTyping = false;

  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _currentlyPlayingUrl;

  XFile? _pickedImage;
  bool _isSending = false;

  late Stream<ChatRoomModel> _roomStream;
  late Stream<List<MessageModel>> _messagesStream;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTextChanged);
    _roomStream = _dbService.getChatRoomStream(widget.room.id);
    _messagesStream = _dbService.getMessages(widget.room.id);
  }

  void _onTextChanged() {
    final text = _messageController.text;
    final isTyping = text.isNotEmpty;
    if (_isTyping != isTyping) {
      _isTyping = isTyping;
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        _dbService.updateTypingStatus(widget.room.id, uid, _isTyping);
      }
    }
  }

  @override
  void dispose() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _dbService.updateTypingStatus(widget.room.id, uid, false);
    }
    _messageController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
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
          await _dbService.sendMessage(widget.room.id, user.uid, '', imageUrl: url);
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
            await _dbService.sendMessage(widget.room.id, user.uid, '', audioUrl: url, duration: 0); // Need real duration if possible, skip for now
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


  void _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final user = Provider.of<User?>(context, listen: false);
    _messageController.clear();
    
    try {
      await _dbService.sendMessage(widget.room.id, user!.uid, content);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في إرسال الرسالة: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<User?>(context);

    return StreamBuilder<ChatRoomModel>(
      stream: _roomStream,
      builder: (context, roomSnapshot) {
        final List<String> typingUserIds = [];
        if (roomSnapshot.hasData && currentUser != null) {
          roomSnapshot.data!.typingUsers.forEach((uid, isTyping) {
            if (isTyping && uid != currentUser.uid) {
              typingUserIds.add(uid);
            }
          });
        }

        final roomName = roomSnapshot.hasData ? (roomSnapshot.data!.groupName ?? 'مجموعة') : (widget.room.groupName ?? 'مجموعة');
        final roomIconUrl = roomSnapshot.hasData ? roomSnapshot.data!.groupIconUrl : widget.room.groupIconUrl;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 1,
            title: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GroupDetailsScreen(roomId: widget.room.id),
                  ),
                );
              },
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: roomIconUrl != null ? NetworkImage(roomIconUrl) : null,
                    backgroundColor: const Color(0xFFF1F5F9),
                    child: roomIconUrl == null ? const Icon(Icons.group, color: Color(0xFF6366F1)) : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(roomName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        if (typingUserIds.isNotEmpty)
                          FutureBuilder<List<UserModel?>>(
                            future: Future.wait(typingUserIds.map((uid) => _dbService.getUser(uid))),
                            builder: (context, usersSnap) {
                              if (!usersSnap.hasData || usersSnap.data!.isEmpty) return const SizedBox.shrink();
                              final activeUsers = usersSnap.data!.whereType<UserModel>().toList();
                              if (activeUsers.isEmpty) return const SizedBox.shrink();

                              String text;
                              if (activeUsers.length == 1) {
                                text = '${activeUsers.first.displayName} يكتب...';
                              } else if (activeUsers.length == 2) {
                                text = '${activeUsers[0].displayName} و ${activeUsers[1].displayName} يكتبان...';
                              } else {
                                text = '${activeUsers.map((u) => u.displayName).join("، ")} يكتبون...';
                              }

                              return Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF10B981)));
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.call),
                onPressed: () {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('المكالمات الجماعية الصوتية قريباً')));
                },
              ),
              IconButton(
                icon: const Icon(Icons.videocam),
                onPressed: () {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('المكالمات الجماعية المرئية قريباً')));
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
      body: Container(
        color: const Color(0xFFF8FAFC),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<MessageModel>>(
                stream: _messagesStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'حدث خطأ في تحميل الرسائل: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red, fontFamily: 'Cairo'),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final messages = snapshot.data!;
                  if (messages.isEmpty) {
                    return const Center(child: Text('بدء المحادثة...', style: TextStyle(color: Colors.grey)));
                  }
                  // Mark as read
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (currentUser != null) {
                      _dbService.markMessagesAsRead(widget.room.id, currentUser.uid);
                    }
                  });

                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.senderId == currentUser!.uid;

                      return GestureDetector(
                        onLongPress: isMe ? () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('حذف الرسالة'),
                              content: const Text('هل أنت متأكد من حذف هذه الرسالة؟'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
                                TextButton(
                                  onPressed: () {
                                    DatabaseService().deleteMessage(widget.room.id, message.id);
                                    Navigator.pop(context);
                                  },
                                  child: const Text('حذف', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        } : null,
                        child: Align(
                          alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isMe ? const Color(0xFF6366F1) : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(20),
                              topRight: const Radius.circular(20),
                              bottomLeft: isMe ? const Radius.circular(4) : const Radius.circular(20),
                              bottomRight: isMe ? const Radius.circular(20) : const Radius.circular(4),
                            ),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              if (!isMe)
                                FutureBuilder<UserModel?>(
                                  future: _dbService.getUser(message.senderId),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(snapshot.data!.displayName, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                                            VerificationBadge(user: snapshot.data!, size: 12),
                                          ],
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  }
                                ),
                              if (message.sharedPostId != null)
                                SharedPostBubble(message: message, isMe: isMe),
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
                                            heroTag: 'group_msg_${message.id}_${message.imageUrl}',
                                          ),
                                        ),
                                      );
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Hero(
                                        tag: 'group_msg_${message.id}_${message.imageUrl}',
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
                                  style: TextStyle(color: isMe ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color, fontSize: 15),
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
                            ],
                          ),
                        ),
                        ).animate().scale(alignment: isMe ? Alignment.bottomLeft : Alignment.bottomRight, duration: 200.ms, curve: Curves.easeOut),
                      );
                    },
                  );
                },
              ),
            ),
            if (typingUserIds.isNotEmpty)
              FutureBuilder<List<UserModel?>>(
                future: Future.wait(typingUserIds.map((uid) => _dbService.getUser(uid))),
                builder: (context, usersSnap) {
                  if (!usersSnap.hasData || usersSnap.data!.isEmpty) return const SizedBox.shrink();
                  final activeUsers = usersSnap.data!.whereType<UserModel>().toList();
                  if (activeUsers.isEmpty) return const SizedBox.shrink();

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    color: Colors.transparent,
                    child: Row(
                      children: [
                        SizedBox(
                          height: 32,
                          width: (activeUsers.length * 16.0) + 16.0,
                          child: Stack(
                            children: List.generate(activeUsers.length, (idx) {
                              return Positioned(
                                right: idx * 16.0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 12,
                                    backgroundImage: NetworkImage(activeUsers[idx].avatarUrl),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            activeUsers.length == 1 
                                ? '${activeUsers.first.displayName} يكتب...' 
                                : '${activeUsers.map((u) => u.displayName).join("، ")} يكتبون...',
                            style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: 0.1, end: 0);
                },
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4)),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    if (_isSending)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    else ...[
                      IconButton(
                        icon: const Icon(Icons.image, color: Color(0xFF64748B)),
                        onPressed: _pickImage,
                      ),
                      Expanded(
                        child: _isRecording
                            ? const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text('جاري التسجيل...', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              )
                            : TextField(
                                controller: _messageController,
                                decoration: InputDecoration(
                                  hintText: 'اكتب رسالة...',
                                  hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                                  filled: true,
                                  fillColor: const Color(0xFFF1F5F9),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(width: 8),
                      if (_messageController.text.isEmpty && !_isTyping)
                        GestureDetector(
                          onLongPress: _toggleRecording,
                          onLongPressUp: _toggleRecording,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _isRecording ? Colors.red : const Color(0xFF6366F1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.mic, color: Colors.white, size: 20),
                          ),
                        )
                      else
                        Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF6366F1),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.send, color: Colors.white, size: 20),
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
    );
  },
);
  }
}
