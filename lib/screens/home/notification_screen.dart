import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/db_service.dart';
import '../../models/notification_model.dart';
import '../../models/user_model.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final db = DatabaseService();
  final uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    // Mark as read when opening
    db.markNotificationsAsRead(uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: db.getNotifications(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('لا توجد إشعارات', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ).animate().fadeIn(),
            );
          }

          final notifs = snapshot.data!;
          return ListView.separated(
            itemCount: notifs.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notif = notifs[index];
              return FutureBuilder<UserModel?>(
                future: db.getUser(notif.senderId),
                builder: (context, userSnap) {
                  final sender = userSnap.data;
                  if (sender == null) return const SizedBox.shrink();

                  String text = '';
                  IconData icon = Icons.notifications;
                  Color iconColor = Colors.grey;

                  if (notif.type == 'like') {
                    text = 'قام بالإعجاب بمنشورك';
                    icon = Icons.favorite;
                    iconColor = Colors.red;
                  } else if (notif.type == 'comment') {
                    text = 'قام بالتعليق على منشورك';
                    icon = Icons.chat_bubble;
                    iconColor = Colors.blue;
                  } else if (notif.type == 'follow') {
                    text = 'بدأ بمتابعتك';
                    icon = Icons.person_add;
                    iconColor = Colors.green;
                  } else if (notif.type == 'follow_request') {
                    text = 'طلب متابعتك';
                    icon = Icons.person_add_alt_1;
                    iconColor = Colors.orange;
                  } else if (notif.type == 'points_transfer') {
                    final amount = notif.postId ?? '0';
                    text = 'أرسل لك $amount نقطة رفيق 🪙';
                    icon = Icons.monetization_on;
                    iconColor = Colors.amber;
                  }

                  final isDark = Theme.of(context).brightness == Brightness.dark;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    tileColor: notif.isRead 
                        ? null 
                        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                    leading: Stack(
                      children: [
                        CircleAvatar(backgroundImage: NetworkImage(sender.avatarUrl), radius: 24),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, size: 12, color: iconColor),
                          ),
                        ),
                      ],
                    ),
                    title: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 14,
                          fontFamily: 'Cairo',
                        ),
                        children: [
                          TextSpan(text: '${sender.displayName} ', style: const TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: text),
                        ],
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(timeago.format(notif.createdAt, locale: 'ar'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        if (notif.type == 'follow_request') ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: () async {
                                  try {
                                    await db.acceptFollowRequest(uid, notif.senderId, notificationId: notif.id);
                                  } catch (e) {
                                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
                                  }
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white, minimumSize: const Size(80, 36)),
                                child: const Text('موافق'),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: () async {
                                  try {
                                    await db.declineFollowRequest(uid, notif.senderId, notificationId: notif.id);
                                  } catch (e) {
                                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
                                  }
                                },
                                style: OutlinedButton.styleFrom(foregroundColor: Colors.grey, minimumSize: const Size(80, 36)),
                                child: const Text('رفض'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideX();
                },
              );
            },
          );
        },
      ),
    );
  }
}
