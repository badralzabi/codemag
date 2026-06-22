import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/db_service.dart';
import '../../models/user_model.dart';
import 'group_chat_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _db = DatabaseService();
  final List<String> _selectedUserIds = [];
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return const Scaffold();

    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء مجموعة جديدة', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _isLoading || _selectedUserIds.isEmpty || _nameController.text.trim().isEmpty 
                ? null 
                : () async {
              setState(() => _isLoading = true);
              try {
                final allUsers = [currentUid, ..._selectedUserIds];
                final roomId = await _db.createGroupChat(allUsers, _nameController.text.trim());
                if (mounted) {
                  Navigator.pop(context); // Go back to chat list
                  // Could navigate to the new room, but we don't have the ChatRoomModel fetched yet.
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إنشاء المجموعة بنجاح')));
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
              }
              setState(() => _isLoading = false);
            },
            child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('إنشاء', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _nameController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'اسم المجموعة',
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.group),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('اختر الأعضاء:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
            ),
          ),
          Expanded(
            child: FutureBuilder<UserModel?>(
              future: _db.getUser(currentUid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final currentUser = snapshot.data!;
                final friends = currentUser.followers.toSet().intersection(currentUser.following.toSet()).toList();
                
                if (friends.isEmpty) {
                  return const Center(child: Text('لا يوجد أصدقاء لإضافتهم'));
                }

                return ListView.builder(
                  itemCount: friends.length,
                  itemBuilder: (context, index) {
                    final friendId = friends[index];
                    return FutureBuilder<UserModel?>(
                      future: _db.getUser(friendId),
                      builder: (context, friendSnap) {
                        if (!friendSnap.hasData) return const ListTile(title: Text('جاري التحميل...'));
                        final friend = friendSnap.data!;
                        final isSelected = _selectedUserIds.contains(friend.uid);

                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedUserIds.add(friend.uid);
                              } else {
                                _selectedUserIds.remove(friend.uid);
                              }
                            });
                          },
                          secondary: CircleAvatar(backgroundImage: NetworkImage(friend.avatarUrl)),
                          title: Text(friend.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('@${friend.username}', style: const TextStyle(color: Colors.grey)),
                          activeColor: const Color(0xFF6366F1),
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
  }
}
