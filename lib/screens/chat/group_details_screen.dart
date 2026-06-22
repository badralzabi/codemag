import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/db_service.dart';
import '../../models/chat_room_model.dart';
import '../../models/user_model.dart';
import '../../services/cloudinary_service.dart';
import '../../widgets/verification_badge.dart';

class GroupDetailsScreen extends StatefulWidget {
  final String roomId;

  const GroupDetailsScreen({super.key, required this.roomId});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  final DatabaseService _db = DatabaseService();
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isUploading = false;

  Future<void> _changeGroupName(BuildContext context, ChatRoomModel room) async {
    final controller = TextEditingController(text: room.groupName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تغيير اسم المجموعة'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'اسم المجموعة الجديد',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                Navigator.pop(ctx);
                await _db.updateGroupDetails(room.id, newName, null);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم تغيير اسم المجموعة بنجاح')),
                  );
                }
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _changeGroupIcon(BuildContext context, ChatRoomModel room) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile == null) return;

    setState(() => _isUploading = true);
    try {
      final url = await CloudinaryService.uploadImage(pickedFile);
      if (url != null) {
        await _db.updateGroupDetails(room.id, room.groupName ?? 'مجموعة', url);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث صورة المجموعة')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في رفع الصورة: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showMemberOptions(BuildContext context, ChatRoomModel room, UserModel member) {
    final bool isCreator = room.creatorId == member.uid;
    final bool isAdmin = room.admins.contains(member.uid);
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isAdmin)
                ListTile(
                  leading: const Icon(Icons.security, color: Color(0xFF6366F1)),
                  title: const Text('تعيين كمسؤول (Admin)'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _db.promoteToAdmin(room.id, member.uid);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('تم تعيين ${member.displayName} كمسؤول')),
                      );
                    }
                  },
                ),
              if (!isCreator)
                ListTile(
                  leading: const Icon(Icons.person_remove, color: Colors.red),
                  title: const Text('طرد من المجموعة', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _db.kickGroupMember(room.id, member.uid);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('تم طرد ${member.displayName} من المجموعة')),
                      );
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ChatRoomModel>(
      stream: _db.getChatRoomStream(widget.roomId),
      builder: (context, roomSnap) {
        if (roomSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!roomSnap.hasData) {
          return const Scaffold(body: Center(child: Text('المجموعة غير موجودة')));
        }

        final room = roomSnap.data!;
        final bool isMeAdmin = room.admins.contains(_currentUid);

        return Scaffold(
          appBar: AppBar(
            title: const Text('تفاصيل المجموعة', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 24),
                // Group Icon
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: const Color(0xFFF1F5F9),
                        backgroundImage: room.groupIconUrl != null ? NetworkImage(room.groupIconUrl!) : null,
                        child: room.groupIconUrl == null 
                            ? const Icon(Icons.group, size: 60, color: Color(0xFF6366F1)) 
                            : null,
                      ),
                      if (_isUploading)
                        Positioned.fill(
                          child: Container(
                            decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                            child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                          ),
                        ),
                      if (isMeAdmin)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            backgroundColor: const Color(0xFF6366F1),
                            radius: 18,
                            child: IconButton(
                              icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                              onPressed: () => _changeGroupIcon(context, room),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Group Name
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      room.groupName ?? 'مجموعة',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    if (isMeAdmin) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.edit_note, color: Color(0xFF6366F1)),
                        onPressed: () => _changeGroupName(context, room),
                      ),
                    ],
                  ],
                ),
                Text(
                  '${room.users.length} عضو',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const Divider(height: 32, thickness: 1, indent: 24, endIndent: 24),
                // Members List
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'أعضاء المجموعة',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                  ),
                ),
                FutureBuilder<List<UserModel?>>(
                  future: Future.wait(room.users.map((uid) => _db.getUser(uid))),
                  builder: (context, usersSnap) {
                    if (!usersSnap.hasData) {
                      return const Center(child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ));
                    }

                    final members = usersSnap.data!.whereType<UserModel>().toList();
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: members.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, indent: 80, endIndent: 24),
                      itemBuilder: (context, index) {
                        final member = members[index];
                        final bool isCreator = room.creatorId == member.uid;
                        final bool isAdmin = room.admins.contains(member.uid);
                        
                        String roleText = 'عضو';
                        Color roleColor = Colors.grey;
                        if (isCreator) {
                          roleText = 'المؤسس';
                          roleColor = Colors.amber.shade700;
                        } else if (isAdmin) {
                          roleText = 'مسؤول';
                          roleColor = const Color(0xFF6366F1);
                        }

                        // Can managing actions be performed on this member?
                        // Admin can manage anyone who is not themselves and not the creator.
                        final bool canManage = isMeAdmin && member.uid != _currentUid && !isCreator;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(member.avatarUrl),
                            radius: 22,
                          ),
                          title: Row(
                            children: [
                              Text(member.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              VerificationBadge(user: member, size: 16),
                            ],
                          ),
                          subtitle: Text('@${member.username}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: roleColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  roleText,
                                  style: TextStyle(color: roleColor, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                              if (canManage) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.more_vert),
                                  onPressed: () => _showMemberOptions(context, room, member),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }
}
