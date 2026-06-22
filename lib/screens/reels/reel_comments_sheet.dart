import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/comment_model.dart';
import '../../models/user_model.dart';
import '../../services/db_service.dart';
import '../../widgets/verification_badge.dart';

class ReelCommentsSheet extends StatefulWidget {
  final String reelId;

  const ReelCommentsSheet({super.key, required this.reelId});

  @override
  State<ReelCommentsSheet> createState() => _ReelCommentsSheetState();
}

class _ReelCommentsSheetState extends State<ReelCommentsSheet> {
  final _commentController = TextEditingController();
  final _db = DatabaseService();
  final _uid = FirebaseAuth.instance.currentUser?.uid;
  String? _editingCommentId;

  void _submitComment() async {
    if (_commentController.text.trim().isEmpty || _uid == null) return;
    final text = _commentController.text.trim();
    _commentController.clear();

    if (_editingCommentId != null) {
      await _db.editReelComment(widget.reelId, _editingCommentId!, text);
      setState(() {
        _editingCommentId = null;
      });
    } else {
      await _db.addReelComment(widget.reelId, _uid!, text);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 10),
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const Text('التعليقات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const Divider(),
          
          Expanded(
            child: StreamBuilder<List<CommentModel>>(
              stream: _db.getReelCommentsStream(widget.reelId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final comments = snapshot.data!;
                if (comments.isEmpty) return const Center(child: Text('لا توجد تعليقات بعد. كن أول من يعلق!'));

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final isMyComment = comment.authorId == _uid;

                    return StreamBuilder<UserModel?>(
                      stream: _db.getUserStream(comment.authorId),
                      builder: (context, userSnapshot) {
                        final author = userSnapshot.data;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: author != null ? NetworkImage(author.avatarUrl) : null,
                            child: author == null ? const Icon(Icons.person) : null,
                          ),
                          title: Row(
                            children: [
                              Text(author?.displayName ?? 'مستخدم', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              if (author != null) VerificationBadge(user: author, size: 14),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(comment.content, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                              const SizedBox(height: 4),
                              Text(timeago.format(comment.createdAt, locale: 'ar'), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                          trailing: isMyComment
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blue),
                                      onPressed: () {
                                        setState(() {
                                          _editingCommentId = comment.id;
                                          _commentController.text = comment.content;
                                        });
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                      onPressed: () {
                                        _db.deleteReelComment(widget.reelId, comment.id);
                                        if (_editingCommentId == comment.id) {
                                          setState(() {
                                            _editingCommentId = null;
                                            _commentController.clear();
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                )
                              : null,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),

          // Comment Input Field
          SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 8,
                left: 16,
                right: 16,
                top: 8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: _editingCommentId != null ? 'تعديل التعليق...' : 'إضافة تعليق...',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                    ),
                  ),
                  if (_editingCommentId != null)
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          _editingCommentId = null;
                          _commentController.clear();
                        });
                      },
                    ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF6366F1),
                    child: IconButton(
                      icon: Icon(_editingCommentId != null ? Icons.check : Icons.send, color: Colors.white, size: 20),
                      onPressed: _submitComment,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
