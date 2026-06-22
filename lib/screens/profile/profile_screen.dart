import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/db_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../models/post_model.dart';
import '../../models/story_model.dart';
import '../home/home_screen.dart';
import 'settings_screen.dart';
import '../chat/chat_room_screen.dart';
import '../../widgets/avatar_with_frame.dart';
import '../../widgets/verification_badge.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;

  const ProfileScreen({super.key, required this.uid});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedTab = 0; // 0 for Posts, 1 for Saved

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();
    final auth = AuthService();
    final isMe = widget.uid == auth.currentUser?.uid;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: StreamBuilder<UserModel?>(
        stream: db.getUserStream(widget.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('المستخدم غير موجود'));
          }

          final user = snapshot.data!;
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                elevation: 0,
                iconTheme: IconThemeData(color: isDark ? Colors.white : const Color(0xFF1E293B)),
                title: const SizedBox.shrink(), // Removed username from top!
                centerTitle: true,
                actions: isMe
                    ? [
                        IconButton(
                          icon: Icon(Icons.settings, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => SettingsScreen(currentUser: user)),
                            );
                          },
                        )
                      ]
                    : [
                        StreamBuilder<UserModel?>(
                          stream: db.getUserStream(auth.currentUser!.uid),
                          builder: (context, currentSnap) {
                            final currentUser = currentSnap.data;
                            final isBlocked = currentUser?.blockedUsers.contains(user.uid) ?? false;
                            
                            return PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                              onSelected: (val) async {
                                if (val == 'block') {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('تأكيد الحظر', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                                      content: Text('هل أنت متأكد من حظر @${user.username}؟ سيتم إلغاء المتابعة المتبادلة بينكما ولن يتمكن من مراسلتك.', style: const TextStyle(fontFamily: 'Cairo')),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
                                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حظر', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    try {
                                      await db.blockUser(auth.currentUser!.uid, user.uid);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('تم حظر ${user.displayName} بنجاح', style: const TextStyle(fontFamily: 'Cairo')),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
                                    }
                                  }
                                } else if (val == 'unblock') {
                                  try {
                                    await db.unblockUser(auth.currentUser!.uid, user.uid);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('تم إلغاء حظر ${user.displayName}', style: const TextStyle(fontFamily: 'Cairo')),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
                                  }
                                }
                              },
                              itemBuilder: (context) => [
                                if (!isBlocked)
                                  const PopupMenuItem(
                                    value: 'block',
                                    child: Text('حظر المستخدم', style: TextStyle(color: Colors.red, fontFamily: 'Cairo')),
                                  )
                                else
                                  const PopupMenuItem(
                                    value: 'unblock',
                                    child: Text('إلغاء الحظر', style: TextStyle(color: Colors.green, fontFamily: 'Cairo')),
                                  ),
                              ],
                            );
                          }
                        ),
                      ],
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    (user.equippedFrame != null && user.equippedFrame != 'none' && user.equippedFrame!.isNotEmpty)
                        ? AvatarWithFrame(
                            avatarUrl: user.avatarUrl,
                            radius: 54,
                            frameId: user.equippedFrame,
                          )
                        : Container(
                            padding: const EdgeInsets.all(3.5),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF818CF8)]),
                              shape: BoxShape.circle,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(2.5),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                shape: BoxShape.circle,
                              ),
                              child: CircleAvatar(
                                backgroundImage: NetworkImage(user.avatarUrl),
                                radius: 54,
                              ),
                            ),
                          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                    const SizedBox(height: 16),
                    
                    // Display Name
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          user.displayName,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                        VerificationBadge(user: user, size: 24),
                      ],
                    ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.15, end: 0),
                    
                    // Username under name
                    Text(
                      '@${user.username}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.15, end: 0),
                    
                    // Bio
                    if (user.bio.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          user.bio,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                        ),
                      ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.15, end: 0),
                    ],
                    const SizedBox(height: 20),
                    
                    // Highlights
                    StreamBuilder<List<StoryModel>>(
                      stream: db.getHighlights(widget.uid),
                      builder: (context, highlightSnap) {
                        if (!highlightSnap.hasData || highlightSnap.data!.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        final highlights = highlightSnap.data!;
                        return Container(
                          height: 100,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: highlights.length,
                            itemBuilder: (context, index) {
                              final highlight = highlights[index];
                              return Container(
                                margin: const EdgeInsets.only(left: 14),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(2.5),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: const Color(0xFF6366F1), width: 1.5),
                                      ),
                                      child: CircleAvatar(
                                        radius: 28,
                                        backgroundImage: highlight.imageUrl != null ? NetworkImage(highlight.imageUrl!) : null,
                                        backgroundColor: highlight.imageUrl == null ? Colors.primaries[highlight.colorIndex % Colors.primaries.length] : null,
                                        child: highlight.imageUrl == null ? Text(highlight.content.isNotEmpty ? highlight.content[0] : '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)) : null,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'أبرز القصص',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white60 : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ).animate().fadeIn(delay: 250.ms);
                      }
                    ),
                    
                    // Stats Card
                    StreamBuilder<UserModel?>(
                      stream: db.getUserStream(auth.currentUser!.uid),
                      builder: (context, currentSnap) {
                        final currentUser = currentSnap.data;
                        final bool hasBlockedMe = user.blockedUsers.contains(auth.currentUser!.uid);
                        final bool isBlockedByMe = currentUser?.blockedUsers.contains(user.uid) ?? false;
                        final bool isRelationBlocked = hasBlockedMe || isBlockedByMe;
                        final bool isPrivateAndNotFollowing = !isMe && user.isPrivate && !user.followers.contains(auth.currentUser!.uid);

                        return StreamBuilder<List<PostModel>>(
                          stream: db.getUserPosts(widget.uid),
                          builder: (context, postSnap) {
                            final postCount = postSnap.hasData ? postSnap.data!.length.toString() : '...';
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(isDark ? 0.25 : 0.03),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                                border: Border.all(
                                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildStatColumn('المنشورات', postCount, isDark),
                                  Container(
                                    width: 1.5,
                                    height: 32,
                                    color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                                  ),
                                  _buildStatColumn(
                                    'المتابِعين',
                                    isRelationBlocked ? '0' : user.followers.length.toString(),
                                    isDark,
                                    onTap: (isRelationBlocked || isPrivateAndNotFollowing)
                                        ? null 
                                        : () => _showFollowsSheet(context, user, 0, isMe),
                                  ),
                                  Container(
                                    width: 1.5,
                                    height: 32,
                                    color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                                  ),
                                  _buildStatColumn(
                                    'يتابع',
                                    isRelationBlocked ? '0' : user.following.length.toString(),
                                    isDark,
                                    onTap: (isRelationBlocked || isPrivateAndNotFollowing)
                                        ? null 
                                        : () => _showFollowsSheet(context, user, 1, isMe),
                                  ),
                                ],
                              ),
                            );
                          }
                        );
                      }
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.15, end: 0),
                    
                    const SizedBox(height: 24),
                    
                    // Action Buttons for other users
                    if (!isMe)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: StreamBuilder<UserModel?>(
                          stream: db.getUserStream(auth.currentUser!.uid),
                          builder: (context, currentSnap) {
                            final currentUser = currentSnap.data;
                            final bool hasBlockedMe = user.blockedUsers.contains(auth.currentUser!.uid);
                            final bool isBlockedByMe = currentUser?.blockedUsers.contains(user.uid) ?? false;

                            if (hasBlockedMe) {
                              return Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red.withOpacity(0.1),
                                        foregroundColor: Colors.red,
                                        minimumSize: const Size(double.infinity, 50),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        elevation: 0,
                                        side: BorderSide(color: Colors.red.withOpacity(0.3)),
                                      ),
                                      onPressed: null,
                                      child: const Text(
                                        'هذا الشخص قام بحضرك',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }

                            if (isBlockedByMe) {
                              return Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(double.infinity, 50),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        elevation: 0,
                                      ),
                                      icon: const Icon(Icons.lock_open),
                                      label: const Text(
                                        'إلغاء الحظر',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                                      ),
                                      onPressed: () async {
                                        try {
                                          await db.unblockUser(auth.currentUser!.uid, user.uid);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('تم إلغاء حظر ${user.displayName}', style: const TextStyle(fontFamily: 'Cairo')),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(
                                  child: Builder(
                                    builder: (context) {
                                      bool isFollowing = user.followers.contains(auth.currentUser!.uid);
                                      bool isRequested = user.followRequests.contains(auth.currentUser!.uid);
                                      String btnText = isFollowing ? 'يتابع' : (isRequested ? 'تم الطلب' : 'متابعة');
                                      IconData btnIcon = isFollowing ? Icons.check : (isRequested ? Icons.access_time : Icons.person_add_alt_1);
                                      
                                      return ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: (isFollowing || isRequested) 
                                              ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)) 
                                              : const Color(0xFF6366F1),
                                          foregroundColor: (isFollowing || isRequested) 
                                              ? (isDark ? Colors.white70 : const Color(0xFF1E293B)) 
                                              : Colors.white,
                                          minimumSize: const Size(double.infinity, 50),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          elevation: 0,
                                          side: (isFollowing || isRequested)
                                              ? BorderSide(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0))
                                              : BorderSide.none,
                                        ),
                                        icon: Icon(btnIcon),
                                        label: Text(btnText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                        onPressed: () async {
                                          try {
                                            await db.toggleFollow(auth.currentUser!.uid, user, isFollowing, isRequested);
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
                                            }
                                          }
                                        },
                                      );
                                    }
                                  ),
                                ),
                                if (!user.isPrivate || user.followers.contains(auth.currentUser!.uid)) ...[
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                                        foregroundColor: const Color(0xFF6366F1),
                                        minimumSize: const Size(double.infinity, 50),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          side: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                                        ),
                                        elevation: 0,
                                      ),
                                      icon: const Icon(Icons.chat_bubble_outline),
                                      label: const Text('مراسلة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      onPressed: () async {
                                        final roomId = await db.createOrGetChatRoom(auth.currentUser!.uid, user.uid);
                                        if (context.mounted) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ChatRoomScreen(roomId: roomId, otherUser: user),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ],
                            );
                          }
                        ),
                      ).animate().scale(delay: 350.ms, curve: Curves.easeOutBack),
                    
                    const SizedBox(height: 24),
                    
                    // Capsule Tab Selector
                    if (isMe) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedTab = 0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _selectedTab == 0 ? const Color(0xFF6366F1) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: _selectedTab == 0 ? [
                                        BoxShadow(
                                          color: const Color(0xFF6366F1).withOpacity(0.3),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        )
                                      ] : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'المنشورات',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: _selectedTab == 0 ? Colors.white : (isDark ? Colors.white60 : Colors.black54),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedTab = 1),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _selectedTab == 1 ? const Color(0xFF6366F1) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: _selectedTab == 1 ? [
                                        BoxShadow(
                                          color: const Color(0xFF6366F1).withOpacity(0.3),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        )
                                      ] : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'المحفوظات',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: _selectedTab == 1 ? Colors.white : (isDark ? Colors.white60 : Colors.black54),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'المنشورات',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: StreamBuilder<List<PostModel>>(
                        stream: _selectedTab == 0 ? db.getUserPosts(widget.uid) : db.getPosts(),
                        builder: (context, postSnapshot) {
                          if (postSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (postSnapshot.hasError) {
                            return const Center(child: Text('خطأ في التحميل', style: TextStyle(color: Colors.red)));
                          }
                          
                          List<PostModel> posts = postSnapshot.data ?? [];
                          if (_selectedTab == 1 && isMe) {
                            posts = posts.where((p) => user.savedPosts.contains(p.id)).toList();
                          }

                          if (!isMe && user.isPrivate && !user.followers.contains(auth.currentUser!.uid)) {
                            return Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.lock_outline, size: 64, color: isDark ? Colors.white30 : Colors.grey),
                                    const SizedBox(height: 16),
                                    const Text('هذا الحساب خاص', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    Text('قم بمتابعته لرؤية صوره ومنشوراته', style: TextStyle(color: isDark ? Colors.white54 : Colors.grey)),
                                  ],
                                ),
                              ),
                            );
                          }

                          if (posts.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Center(
                                child: Text(
                                  _selectedTab == 0 ? 'لا توجد منشورات بعد' : 'لا توجد منشورات محفوظة',
                                  style: TextStyle(color: isDark ? Colors.white30 : Colors.grey, fontSize: 16),
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            itemCount: posts.length,
                            itemBuilder: (context, index) {
                              return PostWidget(post: posts[index], currentUserModel: user)
                                  .animate()
                                  .fadeIn(delay: Duration(milliseconds: 100 * index))
                                  .slideY(begin: 0.1, end: 0);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showFollowsSheet(BuildContext context, UserModel user, int initialTab, bool isMe) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DefaultTabController(
          length: 2,
          initialIndex: initialTab,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                TabBar(
                  labelColor: const Color(0xFF6366F1),
                  unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
                  indicatorColor: const Color(0xFF6366F1),
                  labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                  tabs: [
                    Tab(text: 'المتابِعون (${user.followers.length})'),
                    Tab(text: 'يتابع (${user.following.length})'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildFollowsList(user.followers, isMe, true, user.uid),
                      _buildFollowsList(user.following, isMe, false, user.uid),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFollowsList(List<String> uids, bool isMyProfile, bool isFollowersTab, String currentUserId) {
    final db = DatabaseService();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (uids.isEmpty) {
      return Center(
        child: Text(
          isFollowersTab ? 'لا يوجد متابعون حالياً' : 'لا يتابع أحداً حالياً',
          style: const TextStyle(fontFamily: 'Cairo', color: Colors.grey),
        ),
      );
    }

    return FutureBuilder<List<UserModel>>(
      future: db.getBlockedUsers(uids),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final users = snapshot.data ?? [];
        if (users.isEmpty) {
          return const Center(
            child: Text(
              'تعذر تحميل القائمة',
              style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final targetUser = users[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              leading: CircleAvatar(
                backgroundImage: NetworkImage(targetUser.avatarUrl),
                radius: 22,
              ),
              title: Text(
                targetUser.displayName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              subtitle: Text(
                '@${targetUser.username}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              trailing: isMyProfile
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: isFollowersTab
                          ? [
                              TextButton(
                                onPressed: () async {
                                  try {
                                    await db.removeFollower(currentUserId, targetUser.uid);
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('تم إزالة المتابع ${targetUser.displayName}', style: const TextStyle(fontFamily: 'Cairo')),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('خطأ: $e')),
                                    );
                                  }
                                },
                                child: const Text('حذف', style: TextStyle(color: Colors.red, fontFamily: 'Cairo')),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade800,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('تأكيد الحظر', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                                      content: Text('هل أنت متأكد من حظر @${targetUser.username}؟ سيتم إلغاء المتابعة المتبادلة بينكما.', style: const TextStyle(fontFamily: 'Cairo')),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
                                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حظر', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    try {
                                      await db.blockUser(currentUserId, targetUser.uid);
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('تم حظر ${targetUser.displayName} بنجاح', style: const TextStyle(fontFamily: 'Cairo')),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('خطأ: $e')),
                                      );
                                    }
                                  }
                                },
                                child: const Text('حظر', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 12)),
                              ),
                            ]
                          : [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                  foregroundColor: isDark ? Colors.white70 : const Color(0xFF1E293B),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 0,
                                ),
                                onPressed: () async {
                                  try {
                                    await db.toggleFollow(currentUserId, targetUser, true, false);
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('تم إلغاء المتابعة لـ ${targetUser.displayName}', style: const TextStyle(fontFamily: 'Cairo')),
                                        backgroundColor: Colors.indigo,
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('خطأ: $e')),
                                    );
                                  }
                                },
                                child: const Text('إلغاء المتابعة', style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                              ),
                            ],
                    )
                  : null,
            );
          },
        );
      },
    );
  }

  Widget _buildStatColumn(String label, String count, bool isDark, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
