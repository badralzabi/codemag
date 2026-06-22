import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../services/db_service.dart';
import '../../models/user_model.dart';
import '../../models/chat_room_model.dart';
import 'chat_room_screen.dart';
import 'group_chat_screen.dart';
import 'create_group_screen.dart';
import '../profile/profile_screen.dart';
import '../../widgets/avatar_with_frame.dart';
import '../../widgets/verification_badge.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();
    final currentUser = Provider.of<User?>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('المحادثات', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(context: context, delegate: _UserSearchDelegate(db: db, currentUser: currentUser!));
            },
          ),
        ],
      ),
      body: StreamBuilder<List<ChatRoomModel>>(
        stream: db.getUserChatRooms(currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('حدث خطأ أثناء تحميل المحادثات', style: TextStyle(color: Colors.red)));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('لا توجد محادثات نشطة', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      showSearch(context: context, delegate: _UserSearchDelegate(db: db, currentUser: currentUser));
                    },
                    icon: const Icon(Icons.search),
                    label: const Text('ابحث عن أصدقاء'),
                  )
                ],
              ).animate().fadeIn(),
            );
          }

          final rooms = snapshot.data!;
          rooms.sort((a, b) {
            final aPinned = a.pinnedBy.contains(currentUser.uid);
            final bPinned = b.pinnedBy.contains(currentUser.uid);
            if (aPinned && !bPinned) return -1;
            if (!aPinned && bPinned) return 1;
            return b.lastMessageTime.compareTo(a.lastMessageTime);
          });
          
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: rooms.length,
            separatorBuilder: (context, index) => const Divider(height: 1, indent: 80, endIndent: 16),
            itemBuilder: (context, index) {
              final room = rooms[index];
              // Find the other user's ID
              final otherUserId = room.users.firstWhere(
                (id) => id != currentUser.uid, 
                orElse: () => currentUser.uid
              );
              
              // Mark messages as delivered when they appear in the user's chat list
              db.markMessagesAsDelivered(room.id, currentUser.uid);

              final isPinned = room.pinnedBy.contains(currentUser.uid);

              if (room.isGroup) {
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundImage: room.groupIconUrl != null ? NetworkImage(room.groupIconUrl!) : null,
                          backgroundColor: const Color(0xFFF1F5F9),
                          child: room.groupIconUrl == null ? const Icon(Icons.group, color: Color(0xFF6366F1)) : null,
                        ),
                      ),
                      if (isPinned)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: const Icon(Icons.push_pin, size: 16, color: Color(0xFF6366F1)),
                          ),
                        ),
                    ],
                  ),
                  title: Text(room.groupName ?? 'مجموعة', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Text(
                    room.lastMessage.isEmpty ? 'تم إنشاء المجموعة' : room.lastMessage, 
                    style: const TextStyle(color: Color(0xFF64748B)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    timeago.format(room.lastMessageTime, locale: 'ar'),
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => GroupChatScreen(room: room)));
                  },
                  onLongPress: () => _showChatOptions(context, room, db, currentUser.uid),
                ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideX(begin: 0.1, end: 0);
              }

              return FutureBuilder<UserModel?>(
                future: db.getUser(otherUserId),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(
                      leading: CircleAvatar(backgroundColor: Color(0xFFF1F5F9)),
                      title: SizedBox(height: 10, child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFFF1F5F9)))),
                      subtitle: SizedBox(height: 10, child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFFF1F5F9)))),
                    );
                  }

                  final otherUser = userSnapshot.data ?? UserModel(
                    uid: otherUserId,
                    email: '',
                    username: 'unknown',
                    displayName: 'مستخدم غير معروف',
                    avatarUrl: 'https://ui-avatars.com/api/?name=User&background=random',
                  );

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: AvatarWithFrame(
                            avatarUrl: otherUser.avatarUrl,
                            radius: 28,
                            frameId: otherUser.equippedFrame,
                          ),
                        ),
                        if (isPinned)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: const Icon(Icons.push_pin, size: 16, color: Color(0xFF6366F1)),
                            ),
                          ),
                      ],
                    ),
                    title: Row(
                      children: [
                        Text(otherUser.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        VerificationBadge(user: otherUser, size: 16),
                      ],
                    ),
                    subtitle: Text(
                      room.lastMessage.isEmpty ? 'بدء المحادثة...' : room.lastMessage, 
                      style: const TextStyle(color: Color(0xFF64748B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      timeago.format(room.lastMessageTime, locale: 'ar'),
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatRoomScreen(roomId: room.id, otherUser: otherUser),
                        ),
                      );
                    },
                    onLongPress: () => _showChatOptions(context, room, db, currentUser.uid),
                  ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideX(begin: 0.1, end: 0);
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateGroupScreen()));
        },
        backgroundColor: const Color(0xFF6366F1),
        child: const Icon(Icons.group_add, color: Colors.white),
      ),
    );
  }

  void _showChatOptions(BuildContext context, ChatRoomModel room, DatabaseService db, String currentUid) {
    final isPinned = room.pinnedBy.contains(currentUid);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(isPinned ? Icons.push_pin_outlined : Icons.push_pin, color: const Color(0xFF6366F1)),
                title: Text(isPinned ? 'إلغاء التثبيت' : 'تثبيت المحادثة'),
                onTap: () {
                  Navigator.pop(context);
                  db.togglePinChatRoom(room.id, currentUid, !isPinned);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('حذف المحادثة', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('حذف المحادثة'),
                      content: Text(room.isGroup ? 'هل أنت متأكد من مغادرة هذه المجموعة وحذفها من قائمتك؟' : 'هل أنت متأكد من حذف هذه المحادثة بالكامل؟'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            db.deleteChatRoom(room.id, currentUid);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحذف')));
                          },
                          child: const Text('حذف', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      }
    );
  }
}

class _UserSearchDelegate extends SearchDelegate<UserModel?> {
  final DatabaseService db;
  final User currentUser;

  _UserSearchDelegate({required this.db, required this.currentUser});

  @override
  String get searchFieldLabel => 'ابحث بالاسم...';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    if (query.trim().isEmpty) {
      return const Center(child: Text('اكتب اسم المستخدم للبحث', style: TextStyle(color: Colors.grey)));
    }

    return StreamBuilder<List<UserModel>>(
      stream: db.getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('لا يوجد مستخدمون', style: TextStyle(color: Colors.grey)));
        }

        final users = snapshot.data!.where((u) {
          if (u.uid == currentUser.uid) return false;
          final searchLower = query.toLowerCase();
          return u.displayName.toLowerCase().contains(searchLower) || 
                 u.username.toLowerCase().contains(searchLower);
        }).toList();

        if (users.isEmpty) {
          return const Center(child: Text('لا توجد نتائج مطابقة', style: TextStyle(color: Colors.grey)));
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: users.length,
          separatorBuilder: (context, index) => const Divider(height: 1, indent: 80, endIndent: 16),
          itemBuilder: (context, index) {
            final user = users[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundImage: NetworkImage(user.avatarUrl),
                radius: 24,
              ),
              title: Row(
                children: [
                  Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  VerificationBadge(user: user, size: 16),
                ],
              ),
              subtitle: Text('@${user.username}'),
              trailing: const Icon(Icons.chat_bubble_outline, color: Color(0xFF6366F1)),
              onTap: () async {
                final isFollowing = user.followers.contains(currentUser.uid);
                if (user.isPrivate && !isFollowing) {
                  // Close the search delegate
                  close(context, user);
                  // Navigate to Profile
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileScreen(uid: user.uid),
                    ),
                  );
                } else {
                  final roomId = await db.createOrGetChatRoom(currentUser.uid, user.uid);
                  if (context.mounted) {
                    // Close the search delegate
                    close(context, user);
                    // Navigate to chat
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatRoomScreen(roomId: roomId, otherUser: user),
                      ),
                    );
                  }
                }
              },
            );
          },
        );
      },
    );
  }
}
