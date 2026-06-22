import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../services/db_service.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../models/comment_model.dart';
import 'package:flutter_parsed_text/flutter_parsed_text.dart';
import '../profile/profile_screen.dart';
import '../home/explore_screen.dart';
import '../home/share_post_sheet.dart';
import '../image_viewer_screen.dart';
import '../../widgets/verification_badge.dart';

class PostDetailScreen extends StatefulWidget {
  final PostModel post;
  final UserModel author;

  const PostDetailScreen({super.key, required this.post, required this.author});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentController = TextEditingController();
  final _dbService = DatabaseService();
  bool _isLoading = false;

  void _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final user = Provider.of<User?>(context, listen: false);
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      await _dbService.addComment(widget.post.id, user.uid, content, widget.author.uid);
      _commentController.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء إضافة التعليق')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('المنشور', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Original Post
          StreamBuilder<PostModel?>(
            stream: _dbService.getPostStream(widget.post.id),
            initialData: widget.post,
            builder: (context, postSnap) {
              final post = postSnap.data ?? widget.post;
              final currentUser = FirebaseAuth.instance.currentUser;
              final isLiked = currentUser != null ? post.likes.contains(currentUser.uid) : false;

              return Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: NetworkImage(widget.author.avatarUrl),
                          radius: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    widget.author.displayName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  VerificationBadge(user: widget.author, size: 16),
                                ],
                              ),
                              Text(
                                '@${widget.author.username} • ${timeago.format(post.createdAt)}',
                                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      post.content,
                      style: const TextStyle(fontSize: 18, color: Color(0xFF1E293B), height: 1.5),
                    ),
                    if (post.imageUrl != null) ...[
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ImageViewerScreen(
                                imageUrl: post.imageUrl!,
                                heroTag: 'post_detail_${post.id}_${post.imageUrl}',
                              ),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Hero(
                            tag: 'post_detail_${post.id}_${post.imageUrl}',
                            child: Image.network(
                              post.imageUrl!,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFF1F5F9)),
                    Row(
                      children: [
                        // Like Button
                        InkWell(
                          onTap: () {
                            if (currentUser != null) {
                              _dbService.toggleLike(post.id, currentUser.uid, isLiked, post.authorId);
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: Row(
                              children: [
                                Icon(
                                  isLiked ? Icons.favorite : Icons.favorite_border,
                                  color: isLiked ? Colors.red : const Color(0xFF64748B),
                                  size: 22,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${post.likes.length}',
                                  style: TextStyle(
                                    color: isLiked ? Colors.red : const Color(0xFF64748B),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Comments Icon/Count
                        const Icon(Icons.chat_bubble_outline, color: Color(0xFF64748B), size: 20),
                        const SizedBox(width: 6),
                        Text(
                          '${post.commentCount} تعليق',
                          style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.share_outlined, color: Color(0xFF64748B), size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => SharePostSheet(post: post),
                            );
                          },
                        ),
                      ],
                    )
                  ],
                ),
              );
            }
          ).animate().fadeIn(),

          const SizedBox(height: 8),
          
          // Comments list
          Expanded(
            child: StreamBuilder<List<CommentModel>>(
              stream: _dbService.getComments(widget.post.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('كن أول من يعلق!', style: TextStyle(color: Colors.grey)));
                }

                final comments = snapshot.data!;
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: comments.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return FutureBuilder<UserModel?>(
                      future: _dbService.getUser(comment.authorId),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState == ConnectionState.waiting) return const SizedBox();
                        
                        final commentAuthor = userSnapshot.data ?? UserModel(
                          uid: comment.authorId,
                          email: '',
                          username: 'unknown',
                          displayName: 'مستخدم غير معروف',
                          avatarUrl: 'https://ui-avatars.com/api/?name=User&background=random',
                        );
                        
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundImage: NetworkImage(commentAuthor.avatarUrl),
                              radius: 18,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                    bottomLeft: Radius.circular(20),
                                    bottomRight: Radius.circular(4),
                                  ),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Text(commentAuthor.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                            VerificationBadge(user: commentAuthor, size: 14),
                                          ],
                                        ),
                                        Text(timeago.format(comment.createdAt), style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    const SizedBox(height: 6),
                                    if (comment.content.isNotEmpty)
                                      ParsedText(
                                        text: comment.content,
                                        style: const TextStyle(fontSize: 14, color: Color(0xFF334155)),
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
                                              final username = url.substring(1);
                                              final db = DatabaseService();
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
                                    if (comment.stickerUrl != null) ...[
                                      if (comment.content.isNotEmpty) const SizedBox(height: 8),
                                      comment.stickerUrl!.startsWith('http')
                                          ? Image.network(comment.stickerUrl!, width: 80, height: 80)
                                          : Image.asset(comment.stickerUrl!, width: 80, height: 80),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideX(begin: 0.1, end: 0);
                      },
                    );
                  },
                );
              },
            ),
          ),
          
          // Add comment input
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
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'اكتب تعليقاً...',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: const Text('🎭', style: TextStyle(fontSize: 20)),
                          onPressed: () async {
                            final authUser = Provider.of<User?>(context, listen: false);
                            if (authUser != null) {
                              final currentUser = await _dbService.getUser(authUser.uid);
                              if (currentUser != null && mounted) {
                                _showStickersSheet(currentUser);
                              }
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF6366F1),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send, color: Colors.white),
                      onPressed: _isLoading ? null : _addComment,
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  void _showStickersSheet(UserModel currentUser) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StickersBottomSheet(
        currentUser: currentUser,
        onStickerSelected: (stickerId) {
          Navigator.pop(context);
          _sendStickerComment(stickerId);
        },
      ),
    );
  }

  Future<void> _sendStickerComment(String stickerId) async {
    final user = Provider.of<User?>(context, listen: false);
    if (user == null) return;
    setState(() => _isLoading = true);
    try {
      await _dbService.addComment(
        widget.post.id,
        user.uid,
        '',
        widget.author.uid,
        stickerUrl: 'https://raw.githubusercontent.com/badralzabi/stic/refs/heads/main/GIF/$stickerId',
      );
      await _dbService.addRecentSticker(user.uid, stickerId);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء إرسال الملصق')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class StickersBottomSheet extends StatefulWidget {
  final UserModel currentUser;
  final Function(String) onStickerSelected;

  const StickersBottomSheet({super.key, required this.currentUser, required this.onStickerSelected});

  @override
  State<StickersBottomSheet> createState() => _StickersBottomSheetState();
}

class _StickersBottomSheetState extends State<StickersBottomSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<String> _favoriteStickers;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _favoriteStickers = List.from(widget.currentUser.favoriteStickers);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleFavorite(String stickerId) async {
    final isFav = _favoriteStickers.contains(stickerId);
    setState(() {
      if (isFav) {
        _favoriteStickers.remove(stickerId);
      } else {
        _favoriteStickers.add(stickerId);
      }
    });
    await DatabaseService().toggleFavoriteSticker(widget.currentUser.uid, stickerId, !isFav);
  }

  Widget _buildGrid(List<String> stickers, String emptyMsg) {
    if (stickers.isEmpty) {
      return Center(child: Text(emptyMsg, style: const TextStyle(color: Colors.grey, fontFamily: 'Cairo')));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: stickers.length,
      itemBuilder: (context, index) {
        final stickerId = stickers[index];
        final isFav = _favoriteStickers.contains(stickerId);
        return GestureDetector(
          onTap: () => widget.onStickerSelected(stickerId),
          onLongPress: () => _toggleFavorite(stickerId),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.network('https://raw.githubusercontent.com/badralzabi/stic/refs/heads/main/GIF/$stickerId'),
                ),
              ),
              if (isFav)
                const Positioned(
                  top: -5,
                  right: -5,
                  child: Icon(Icons.star, color: Colors.amber, size: 20),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final recents = widget.currentUser.recentStickers.where((s) => widget.currentUser.unlockedStickers.contains(s)).toList();
    final favorites = _favoriteStickers.where((s) => widget.currentUser.unlockedStickers.contains(s)).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          const Text('اختر ملصقاً', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 4),
          const Text('اضغط مطولاً للإضافة للمفضلة ⭐️', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 8),
          TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF6366F1),
            labelColor: const Color(0xFF6366F1),
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: 'الكل 🎭'),
              Tab(text: 'الأخيرة 🕒'),
              Tab(text: 'المفضلة ⭐️'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGrid(widget.currentUser.unlockedStickers, 'لا تملك أي ملصقات'),
                _buildGrid(recents, 'لا توجد ملصقات مستخدمة مؤخراً'),
                _buildGrid(favorites, 'لا توجد ملصقات مفضلة'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
