import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_parsed_text/flutter_parsed_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/db_service.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../models/story_model.dart';
import 'create_story_screen.dart';
import 'create_post_screen.dart';
import '../post/post_detail_screen.dart';
import '../image_viewer_screen.dart';
import 'notification_screen.dart';
import '../profile/profile_screen.dart';
import 'explore_screen.dart';
import 'share_post_sheet.dart';
import '../../widgets/verification_badge.dart';
import 'friends_map_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return uid == null
        ? const Center(child: CircularProgressIndicator())
        : StreamBuilder<UserModel?>(
            stream: db.getUserStream(uid),
            builder: (context, userSnap) {
              if (userSnap.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              final currentUserModel = userSnap.data;
              final followingList = currentUserModel?.following ?? [];

              return DefaultTabController(
                length: 2,
                child: Scaffold(
                  appBar: AppBar(
                    title: const Text('المنشورات', style: TextStyle(fontWeight: FontWeight.bold)),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.map_outlined),
                        onPressed: () {
                          if (currentUserModel != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FriendsMapScreen(currentUser: currentUserModel),
                              ),
                            );
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.notifications_none),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                    bottom: const TabBar(
                      tabs: [
                        Tab(text: 'استكشاف'),
                        Tab(text: 'أتابعهم'),
                      ],
                      indicatorColor: Color(0xFF6366F1),
                      labelColor: Color(0xFF6366F1),
                      unselectedLabelColor: Colors.grey,
                    ),
                  ),
                  body: TabBarView(
                    children: [
                      _buildPostsList(db.getPosts(), null, currentUserModel),
                      _buildPostsList(db.getPosts(), followingList, currentUserModel),
                    ],
                  ),
                  floatingActionButton: FloatingActionButton(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CreatePostScreen()),
                      );
                    },
                    child: const Icon(Icons.add),
                  ).animate().scale(delay: 500.ms, curve: Curves.easeOutBack),
                ),
              );
            },
          );
  }

  Widget _buildPostsList(Stream<List<PostModel>> stream, List<String>? followingList, UserModel? currentUserModel) {
    return StreamBuilder<List<PostModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('خطأ: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }
        
        List<PostModel> posts = snapshot.data ?? [];
        
        if (followingList != null) {
           final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
           posts = posts.where((p) => followingList.contains(p.authorId) || p.authorId == currentUserUid).toList();
        } else if (currentUserModel != null) {
           posts.sort((a, b) {
             final aFollowed = currentUserModel.following.contains(a.authorId) || a.authorId == currentUserModel.uid;
             final bFollowed = currentUserModel.following.contains(b.authorId) || b.authorId == currentUserModel.uid;
             if (aFollowed && !bFollowed) return -1;
             if (!aFollowed && bFollowed) return 1;
             return b.createdAt.compareTo(a.createdAt);
           });
        }

        if (posts.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (followingList == null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _buildStoryBar(currentUserModel),
                ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('لا توجد منشورات بعد', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ],
          ).animate().fadeIn();
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: posts.length + (followingList == null ? 1 : 0), // Show story bar only in Explore tab
          itemBuilder: (context, index) {
            if (followingList == null && index == 0) {
              return _buildStoryBar(currentUserModel);
            }
            final postIndex = followingList == null ? index - 1 : index;
            final post = posts[postIndex];
            return PostWidget(post: post, currentUserModel: currentUserModel)
                .animate()
                .fadeIn(delay: Duration(milliseconds: 100 * postIndex))
                .slideY(begin: 0.1, end: 0);
          },
        );
      },
    );
  }

  Widget _buildStoryBar(UserModel? currentUserModel) {
    if (currentUserModel == null) return const SizedBox.shrink();
    
    final allowedUserIds = [currentUserModel.uid, ...currentUserModel.following];
    
    return StreamBuilder<List<StoryModel>>(
      stream: DatabaseService().getStories(allowedUserIds: allowedUserIds),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 100);
        final stories = snapshot.data!;
        
        return Container(
          height: 110,
          margin: const EdgeInsets.only(bottom: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: stories.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildAddStoryCard(context, currentUserModel);
              }
              final story = stories[index - 1];
              return _buildStoryCard(context, story);
            },
          ),
        );
      },
    );
  }

  Widget _buildAddStoryCard(BuildContext context, UserModel user) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateStoryScreen()));
      },
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(left: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(user.avatarUrl),
                ),
                Positioned(
                  bottom: -4,
                  right: -4,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF6366F1),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(2),
                    child: const Icon(Icons.add, size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('إضافة قصة', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryCard(BuildContext context, StoryModel story) {
    final List<List<Color>> gradients = [
      [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
      [const Color(0xFFF43F5E), const Color(0xFFFB923C)],
      [const Color(0xFF10B981), const Color(0xFF3B82F6)],
      [const Color(0xFF1E293B), const Color(0xFF0F172A)],
      [const Color(0xFFD946EF), const Color(0xFF8B5CF6)],
    ];
    final colorList = gradients[story.colorIndex % gradients.length];

    return StreamBuilder<UserModel?>(
      stream: DatabaseService().getUserStream(story.authorId),
      builder: (context, snapshot) {
        final author = snapshot.data;
        return GestureDetector(
          onTap: () {
            _showStoryDialog(context, story, author);
          },
          child: Container(
            width: 80,
            margin: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              image: story.imageUrl != null 
                  ? DecorationImage(image: NetworkImage(story.imageUrl!), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken))
                  : null,
              gradient: story.imageUrl == null ? LinearGradient(colors: colorList, begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      story.content,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                if (author != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: CircleAvatar(
                        radius: 12,
                        backgroundImage: NetworkImage(author.avatarUrl),
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

  void _showStoryDialog(BuildContext context, StoryModel story, UserModel? author) {
    final List<List<Color>> gradients = [
      [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
      [const Color(0xFFF43F5E), const Color(0xFFFB923C)],
      [const Color(0xFF10B981), const Color(0xFF3B82F6)],
      [const Color(0xFF1E293B), const Color(0xFF0F172A)],
      [const Color(0xFFD946EF), const Color(0xFF8B5CF6)],
    ];
    final colorList = gradients[story.colorIndex % gradients.length];
    
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isMe = currentUid == story.authorId;
    if (currentUid != null && !isMe && !story.viewers.contains(currentUid)) {
      DatabaseService().viewStory(story.id, currentUid);
    }

    showDialog(
      context: context,
      builder: (context) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    image: story.imageUrl != null 
                        ? DecorationImage(image: NetworkImage(story.imageUrl!), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken))
                        : null,
                    gradient: story.imageUrl == null ? LinearGradient(colors: colorList, begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        story.content,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),
              if (author != null)
                Positioned(
                  top: 50,
                  right: 20,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(author.avatarUrl),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        author.displayName,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      VerificationBadge(user: author, size: 16),
                    ],
                  ),
                ),
              if (isMe)
                Positioned(
                  bottom: 30,
                  left: 20,
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () {
                          _showViewersList(context, story.viewers);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                          child: Row(
                            children: [
                              const Icon(Icons.remove_red_eye, color: Colors.white, size: 16),
                              const SizedBox(width: 8),
                              Text('${story.viewers.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: Icon(story.isHighlight ? Icons.push_pin : Icons.push_pin_outlined, color: story.isHighlight ? Colors.yellow : Colors.white),
                        onPressed: () async {
                          await DatabaseService().toggleStoryHighlight(story.id, !story.isHighlight);
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(story.isHighlight ? 'تم الإزالة من أبرز القصص' : 'تم الإضافة إلى أبرز القصص')));
                          Navigator.pop(context);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.white),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('تأكيد الحذف'),
                              content: const Text('هل أنت متأكد من رغبتك في حذف هذه القصة؟'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.pop(ctx);
                                    Navigator.pop(context); // close story dialog
                                    await DatabaseService().deleteStory(story.id);
                                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحذف')));
                                  },
                                  child: const Text('حذف', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    ],
                  ),
                ),
              if (!isMe)
                Positioned(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  left: 20,
                  right: 20,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: TextField(
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'رد على القصة...',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            ),
                            onSubmitted: (val) async {
                              if (val.trim().isNotEmpty && currentUid != null) {
                                final db = DatabaseService();
                                final roomId = await db.createOrGetChatRoom(currentUid, story.authorId);
                                await db.sendMessage(roomId, currentUid, val.trim(), storyImageUrl: story.imageUrl ?? 'gradient');
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال الرد في رسالة خاصة')));
                                  Navigator.pop(context);
                                }
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () async {
                           if (currentUid != null) {
                             final db = DatabaseService();
                             final roomId = await db.createOrGetChatRoom(currentUid, story.authorId);
                             await db.sendMessage(roomId, currentUid, '❤️', storyImageUrl: story.imageUrl ?? 'gradient');
                             if (context.mounted) {
                               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال التفاعل في الخاص')));
                               Navigator.pop(context);
                             }
                           }
                        },
                        child: const Text('❤️', style: TextStyle(fontSize: 28)),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () async {
                           if (currentUid != null) {
                             final db = DatabaseService();
                             final roomId = await db.createOrGetChatRoom(currentUid, story.authorId);
                             await db.sendMessage(roomId, currentUid, '🔥', storyImageUrl: story.imageUrl ?? 'gradient');
                             if (context.mounted) {
                               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال التفاعل في الخاص')));
                               Navigator.pop(context);
                             }
                           }
                        },
                        child: const Text('🔥', style: TextStyle(fontSize: 28)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showViewersList(BuildContext context, List<String> viewerIds) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        if (viewerIds.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(child: Text('لا توجد مشاهدات حتى الآن', style: TextStyle(fontSize: 16))),
          );
        }
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('المشاهدات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance.collection('users').where(FieldPath.documentId, whereIn: viewerIds.take(10).toList()).get(), // limiting to 10 for safety in whereIn
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox();
                    final users = snapshot.data!.docs.map((d) => UserModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();
                    return ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return ListTile(
                          leading: CircleAvatar(backgroundImage: NetworkImage(user.avatarUrl)),
                          title: Text(user.displayName),
                          subtitle: Text('@${user.username}'),
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

class PostWidget extends StatelessWidget {
  final PostModel post;
  final UserModel? currentUserModel;
  const PostWidget({super.key, required this.post, this.currentUserModel});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();

    return StreamBuilder<UserModel?>(
      stream: db.getUserStream(post.authorId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final author = snapshot.data ?? UserModel(
          uid: post.authorId,
          email: 'unknown@user.com',
          username: 'unknown',
          displayName: 'مستخدم غير معروف',
          avatarUrl: 'https://ui-avatars.com/api/?name=User&background=random',
        );

        if (currentUserModel != null && author.uid != currentUserModel!.uid && author.isPrivate && !currentUserModel!.following.contains(author.uid)) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PostDetailScreen(post: post, author: author),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(uid: author.uid)));
                          },
                          child: Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2), width: 2),
                                ),
                                child: CircleAvatar(
                                  backgroundImage: NetworkImage(author.avatarUrl),
                                  radius: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          author.displayName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        VerificationBadge(user: author, size: 16),
                                      ],
                                    ),
                                    Text(
                                      '@${author.username} • ${timeago.format(post.createdAt)}',
                                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (post.authorId != FirebaseAuth.instance.currentUser?.uid)
                        TextButton(
                          onPressed: () async {
                            final uid = FirebaseAuth.instance.currentUser?.uid;
                            if (uid != null) {
                              try {
                                final isFollowing = author.followers.contains(uid);
                                final isRequested = author.followRequests.contains(uid);
                                await db.toggleFollow(uid, author, isFollowing, isRequested);
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
                                }
                              }
                            }
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: author.followers.contains(FirebaseAuth.instance.currentUser?.uid) ? Colors.grey : const Color(0xFF6366F1),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(author.followers.contains(FirebaseAuth.instance.currentUser?.uid) ? 'يتابع' : 'متابعة', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      if (post.authorId == FirebaseAuth.instance.currentUser?.uid)
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_horiz, color: Color(0xFF94A3B8)),
                          onSelected: (value) async {
                            if (value == 'delete') {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('تأكيد الحذف'),
                                  content: const Text('هل أنت متأكد من رغبتك في حذف هذا المنشور؟ لا يمكن التراجع عن هذا الإجراء.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('إلغاء'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        Navigator.pop(ctx);
                                        await db.deletePost(post.id);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف المنشور بنجاح')));
                                        }
                                      },
                                      child: const Text('حذف', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                            } else if (value == 'edit') {
                              _showEditPostDialog(context, post, db);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, color: Color(0xFF6366F1)),
                                  SizedBox(width: 8),
                                  Text('تعديل المنشور', style: TextStyle(color: Color(0xFF6366F1))),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('حذف المنشور', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ParsedText(
                    text: post.content,
                    style: const TextStyle(fontSize: 16, height: 1.5, color: Color(0xFF1E293B)),
                    parse: [
                      MatchText(
                        type: ParsedType.CUSTOM,
                        pattern: r'\B#+([\w]+)\b',
                        style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold),
                        onTap: (url) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => ExploreScreen(initialQuery: url)));
                        },
                      ),
                      MatchText(
                        type: ParsedType.CUSTOM,
                        pattern: r'\B@+([\w]+)\b',
                        style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold),
                        onTap: (url) async {
                          final username = url.substring(1); // remove @
                          final user = await db.getUserByUsername(username);
                          if (user != null && context.mounted) {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(uid: user.uid)));
                          } else if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('المستخدم غير موجود')));
                          }
                        },
                      ),
                    ],
                  ),
                  if (post.imageUrl != null) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ImageViewerScreen(
                              imageUrl: post.imageUrl!,
                              heroTag: 'post_${post.id}_${post.imageUrl}',
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Hero(
                          tag: 'post_${post.id}_${post.imageUrl}',
                          child: Image.network(
                            post.imageUrl!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 200,
                                color: Colors.grey[200],
                                child: const Center(child: CircularProgressIndicator()),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                color: Colors.grey[200],
                                child: const Center(child: Icon(Icons.error, color: Colors.grey)),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    height: 1,
                    color: const Color(0xFFF1F5F9),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInteractionButton(
                        icon: post.likes.contains(FirebaseAuth.instance.currentUser?.uid) 
                            ? Icons.favorite 
                            : Icons.favorite_border,
                        label: '${post.likes.length} إعجاب',
                        color: post.likes.contains(FirebaseAuth.instance.currentUser?.uid)
                            ? Colors.red
                            : const Color(0xFF64748B),
                        onTap: () {
                          final currentUser = FirebaseAuth.instance.currentUser;
                          if (currentUser != null) {
                            final isLiked = post.likes.contains(currentUser.uid);
                            db.toggleLike(post.id, currentUser.uid, isLiked, post.authorId);
                          }
                        },
                      ),
                      _buildInteractionButton(
                        icon: Icons.chat_bubble_outline,
                        label: '${post.commentCount} تعليق',
                        color: const Color(0xFF64748B),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PostDetailScreen(post: post, author: author),
                            ),
                          );
                        },
                      ),
                      _buildInteractionButton(
                        icon: Icons.share_outlined,
                        label: 'مشاركة',
                        color: const Color(0xFF64748B),
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => SharePostSheet(post: post),
                          );
                        },
                      ),
                      if (currentUserModel != null)
                        _buildInteractionButton(
                          icon: currentUserModel!.savedPosts.contains(post.id) ? Icons.bookmark : Icons.bookmark_border,
                          label: '',
                          color: currentUserModel!.savedPosts.contains(post.id) ? const Color(0xFF6366F1) : const Color(0xFF64748B),
                          onTap: () {
                            db.toggleBookmark(currentUserModel!.uid, post.id, currentUserModel!.savedPosts.contains(post.id));
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInteractionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  void _showEditPostDialog(BuildContext context, PostModel post, DatabaseService db) {
    final TextEditingController controller = TextEditingController(text: post.content);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تعديل المنشور'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'اكتب ما تفكر فيه...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white),
              onPressed: () async {
                final newContent = controller.text.trim();
                if (newContent.isNotEmpty && newContent != post.content) {
                  await db.updatePost(post.id, newContent);
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }
}
