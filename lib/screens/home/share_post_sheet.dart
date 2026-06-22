import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/db_service.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../models/chat_room_model.dart';

class SharePostSheet extends StatefulWidget {
  final PostModel post;

  const SharePostSheet({super.key, required this.post});

  @override
  State<SharePostSheet> createState() => _SharePostSheetState();
}

class _SharePostSheetState extends State<SharePostSheet> {
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _sentRoomIds = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _shareToRoom(String roomId, String currentUserId, String authorName) async {
    if (_sentRoomIds.contains(roomId)) return;

    setState(() {
      _sentRoomIds.add(roomId);
    });

    try {
      await _dbService.sendMessage(
        roomId,
        currentUserId,
        'شارك منشوراً',
        sharedPostId: widget.post.id,
        sharedPostAuthorId: widget.post.authorId,
        sharedPostAuthorName: authorName,
        sharedPostContent: widget.post.content,
        sharedPostImageUrl: widget.post.imageUrl,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء مشاركة المنشور: $e')),
        );
      }
      setState(() {
        _sentRoomIds.remove(roomId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseUser = Provider.of<User?>(context);
    if (firebaseUser == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<UserModel?>(
      stream: _dbService.getUserStream(firebaseUser.uid),
      builder: (context, userSnap) {
        if (userSnap.connectionState == ConnectionState.waiting && !userSnap.hasData) {
          return Container(
            height: 350,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final currentUserModel = userSnap.data;
        if (currentUserModel == null) {
          return Container(
            height: 200,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: const Center(child: Text('حدث خطأ في تحميل البيانات')),
          );
        }

        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Pull Handle
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'مشاركة المنشور في الدردشة',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'البحث عن صديق أو مجموعة...',
                      hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Post Preview in Sheet
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (widget.post.imageUrl != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            widget.post.imageUrl!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.post.content,
                              maxLines: widget.post.imageUrl != null ? 2 : 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Chats List
              Expanded(
                child: StreamBuilder<List<ChatRoomModel>>(
                  stream: _dbService.getUserChatRooms(firebaseUser.uid),
                  builder: (context, roomsSnap) {
                    if (roomsSnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final rooms = roomsSnap.data ?? [];
                    if (rooms.isEmpty) {
                      return const Center(
                        child: Text(
                          'لا توجد محادثات نشطة حالياً',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    // We need a Future to resolve the author displayName of the post for sending
                    return FutureBuilder<UserModel?>(
                      future: _dbService.getUser(widget.post.authorId),
                      builder: (context, authorSnap) {
                        final authorName = authorSnap.data?.displayName ?? 'مستخدم';

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          itemCount: rooms.length,
                          itemBuilder: (context, index) {
                            final room = rooms[index];
                            return ChatRoomShareTile(
                              room: room,
                              currentUserModel: currentUserModel,
                              searchQuery: _searchQuery,
                              isSent: _sentRoomIds.contains(room.id),
                              onSend: () => _shareToRoom(room.id, firebaseUser.uid, authorName),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ChatRoomShareTile extends StatelessWidget {
  final ChatRoomModel room;
  final UserModel currentUserModel;
  final String searchQuery;
  final bool isSent;
  final VoidCallback onSend;

  const ChatRoomShareTile({
    super.key,
    required this.room,
    required this.currentUserModel,
    required this.searchQuery,
    required this.isSent,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final db = DatabaseService();

    if (room.isGroup) {
      // Group check
      final groupName = room.groupName ?? '';
      if (searchQuery.isNotEmpty && !groupName.toLowerCase().contains(searchQuery)) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              backgroundImage: room.groupIconUrl != null ? NetworkImage(room.groupIconUrl!) : null,
              child: room.groupIconUrl == null
                  ? const Icon(Icons.group, color: Color(0xFF6366F1))
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    groupName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'مجموعة دردشة',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            _buildSendButton(),
          ],
        ),
      );
    } else {
      // 1-to-1 Chat: check mutual follower constraint
      final otherUserId = room.users.firstWhere((id) => id != currentUserModel.uid, orElse: () => '');
      if (otherUserId.isEmpty) return const SizedBox.shrink();

      return StreamBuilder<UserModel?>(
        stream: db.getUserStream(otherUserId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();

          final otherUser = snapshot.data!;
          
          // Check search query
          final matchesSearch = otherUser.displayName.toLowerCase().contains(searchQuery) ||
              otherUser.username.toLowerCase().contains(searchQuery);
          if (searchQuery.isNotEmpty && !matchesSearch) {
            return const SizedBox.shrink();
          }

          // Check Mutual Follower Constraint: Current user follows other, and other follows current
          final bool isMutual = currentUserModel.following.contains(otherUser.uid) &&
              currentUserModel.followers.contains(otherUser.uid);

          if (!isMutual) {
            // Hide completely if not mutual follower
            return const SizedBox.shrink();
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage: NetworkImage(otherUser.avatarUrl),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        otherUser.displayName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '@${otherUser.username}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _buildSendButton(),
              ],
            ),
          );
        },
      );
    }
  }

  Widget _buildSendButton() {
    if (isSent) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF10B981)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check, size: 16, color: Color(0xFF10B981)),
            SizedBox(width: 4),
            Text(
              'تم الإرسال',
              style: TextStyle(
                color: Color(0xFF10B981),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return ElevatedButton(
      onPressed: onSend,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: const Text(
        'إرسال',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}
