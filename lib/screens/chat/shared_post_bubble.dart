import 'package:flutter/material.dart';
import '../../models/message_model.dart';
import '../../services/db_service.dart';
import '../post/post_detail_screen.dart';

class SharedPostBubble extends StatefulWidget {
  final MessageModel message;
  final bool isMe;

  const SharedPostBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  State<SharedPostBubble> createState() => _SharedPostBubbleState();
}

class _SharedPostBubbleState extends State<SharedPostBubble> {
  bool _isLoading = false;

  void _onTap(BuildContext context) async {
    final postId = widget.message.sharedPostId;
    final authorId = widget.message.sharedPostAuthorId;
    if (postId == null || authorId == null || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      final db = DatabaseService();
      final post = await db.getPost(postId);
      final author = await db.getUser(authorId);

      if (post != null && author != null) {
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PostDetailScreen(post: post, author: author),
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('عذراً، هذا المنشور لم يعد متوفراً.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء تحميل المنشور: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColor = widget.isMe
        ? Colors.white.withOpacity(0.15)
        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9));

    final textColor = widget.isMe
        ? Colors.white
        : (isDark ? Colors.white : Colors.black87);

    final subTextColor = widget.isMe
        ? Colors.white70
        : (isDark ? Colors.white60 : Colors.black54);

    return GestureDetector(
      onTap: () => _onTap(context),
      child: Container(
        width: 240,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: themeColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.isMe
                ? Colors.white.withOpacity(0.2)
                : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: widget.isMe
                                ? Colors.white.withOpacity(0.2)
                                : const Color(0xFF6366F1).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.share,
                            size: 16,
                            color: widget.isMe ? Colors.white : const Color(0xFF6366F1),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.message.sharedPostAuthorName ?? 'مستخدم',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: textColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'منشور مشترك',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: subTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Post Image if any
                  if (widget.message.sharedPostImageUrl != null)
                    Image.network(
                      widget.message.sharedPostImageUrl!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                    ),

                  // Post Content
                  if (widget.message.sharedPostContent != null &&
                      widget.message.sharedPostContent!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        widget.message.sharedPostContent!,
                        style: TextStyle(
                          fontSize: 13,
                          color: textColor,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                  // Bottom action row
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    color: widget.isMe
                        ? Colors.white.withOpacity(0.08)
                        : (isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'عرض المنشور',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: widget.isMe ? Colors.white : const Color(0xFF6366F1),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 10,
                          color: widget.isMe ? Colors.white : const Color(0xFF6366F1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black26,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
