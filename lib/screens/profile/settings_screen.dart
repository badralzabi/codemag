import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/auth_service.dart';
import '../../providers/theme_provider.dart';
import '../../models/user_model.dart';
import '../auth_wrapper.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../services/cloudinary_service.dart';
import 'buddy_settings_screen.dart';
import 'buddy_store_screen.dart';
import '../../services/db_service.dart';

class SettingsScreen extends StatefulWidget {
  final UserModel currentUser;

  const SettingsScreen({super.key, required this.currentUser});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _auth = AuthService();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  bool _isLoading = false;

  late bool _isPrivate;
  late bool _isVerified;
  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;
  String? _newAvatarUrl;



  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentUser.displayName);
    _bioController = TextEditingController(text: widget.currentUser.bio);
    _isPrivate = widget.currentUser.isPrivate;
    _isVerified = widget.currentUser.isVerified;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      if (_pickedImage != null) {
        _newAvatarUrl = await CloudinaryService.uploadImage(_pickedImage!);
        if (_newAvatarUrl == null) {
          throw Exception('فشل في رفع الصورة، يرجى المحاولة مرة أخرى.');
        }
      }

      await FirebaseFirestore.instance.collection('users').doc(widget.currentUser.uid).update({
        'displayName': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'isPrivate': _isPrivate,
        'isVerified': _isVerified,
        if (_newAvatarUrl != null) 'avatarUrl': _newAvatarUrl,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ التعديلات بنجاح'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    setState(() => _isLoading = false);
  }





  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final primaryColor = const Color(0xFF6366F1);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('الإعدادات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          // 1. Edit Profile Header & Picture Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'تعديل الملف الشخصي',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
                  textAlign: TextAlign.start,
                ),
                const SizedBox(height: 20),
                Center(
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: primaryColor, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 54,
                          backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          backgroundImage: _pickedImageBytes != null
                              ? MemoryImage(_pickedImageBytes!)
                              : NetworkImage(_newAvatarUrl ?? widget.currentUser.avatarUrl) as ImageProvider,
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () async {
                            final picker = ImagePicker();
                            final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                            if (pickedFile != null) {
                              final bytes = await pickedFile.readAsBytes();
                              setState(() {
                                _pickedImage = pickedFile;
                                _pickedImageBytes = bytes;
                              });
                            }
                          },
                          child: CircleAvatar(
                            backgroundColor: primaryColor,
                            radius: 18,
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.currentUser.avatarUrl.contains('cloudinary') || _pickedImageBytes != null) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _pickedImage = null;
                        _pickedImageBytes = null;
                        _newAvatarUrl = 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(widget.currentUser.displayName)}&background=random';
                      });
                    },
                    icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                    label: const Text('حذف الصورة', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
                ],
                const SizedBox(height: 24),
                // Display Name field
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'الاسم',
                    prefixIcon: const Icon(Icons.person_outline),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: primaryColor, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),
                // Bio field
                TextField(
                  controller: _bioController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'نبذة عنك',
                    prefixIcon: const Icon(Icons.info_outline),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: primaryColor, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('حفظ التعديلات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 20),

          // 2. Privacy & Verification Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'الخصوصية والتوثيق',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor),
                  ),
                ),
                SwitchListTile.adaptive(
                  title: const Text('حساب خاص (Private)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: const Text('لن يرى منشوراتك إلا من توافق عليه', style: TextStyle(fontSize: 12)),
                  secondary: const Icon(Icons.lock_outline, color: Color(0xFF64748B)),
                  value: _isPrivate,
                  activeColor: primaryColor,
                  onChanged: (val) async {
                    final oldVal = _isPrivate;
                    setState(() => _isPrivate = val);
                    try {
                      await FirebaseFirestore.instance.collection('users').doc(widget.currentUser.uid).update({'isPrivate': val});
                    } catch (e) {
                      setState(() => _isPrivate = oldVal);
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في حفظ الخصوصية: $e')));
                    }
                  },
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                const Divider(height: 1, thickness: 1),
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(widget.currentUser.uid).snapshots(),
                  builder: (context, userSnapshot) {
                    List<String> unlockedVerifs = [];
                    bool hasActiveVerification = false;
                    String? activeVerif;
                    if (userSnapshot.hasData && userSnapshot.data!.exists) {
                      final data = userSnapshot.data!.data() as Map<String, dynamic>?;
                      if (data != null) {
                        unlockedVerifs = List<String>.from(data['unlockedVerifications'] ?? []);
                        final isVer = data['isVerified'] == true;
                        activeVerif = data['equippedVerification'] as String?;
                        hasActiveVerification = isVer || activeVerif != null;
                      }
                    }

                    return SwitchListTile.adaptive(
                      title: const Row(
                        children: [
                          Text('ظهور شارة التوثيق', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                      subtitle: const Text('تفعيل أو تعطيل ظهور شارة التوثيق المفعلة بجانب اسمك', style: TextStyle(fontSize: 12)),
                      secondary: Icon(
                        Icons.verified,
                        color: hasActiveVerification ? Colors.blue : Colors.grey,
                      ),
                      value: hasActiveVerification,
                      activeColor: primaryColor,
                      onChanged: (val) async {
                        try {
                          if (!val) {
                            // Turn OFF verification completely
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(widget.currentUser.uid)
                                .update({
                              'isVerified': false,
                              'equippedVerification': FieldValue.delete(),
                            });
                            setState(() {
                              _isVerified = false;
                            });
                          } else {
                            // Turn ON: equip the first unlocked verification if available
                            if (unlockedVerifs.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'يجب شراء وتفعيل شارة توثيق من المتجر أولاً! 🏪',
                                    style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                                  ),
                                  backgroundColor: Colors.amber,
                                ),
                              );
                              return;
                            }
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(widget.currentUser.uid)
                                .update({
                              'equippedVerification': unlockedVerifs.first,
                            });
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('خطأ في حفظ التوثيق: $e')),
                            );
                          }
                        }
                      },
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    );
                  },
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms, delay: 100.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 20),

          // 3. Theme Preferences Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'المظهر والمظهر العام',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor),
                  ),
                ),
                SwitchListTile.adaptive(
                  title: const Text('الوضع الداكن (Dark Mode)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: const Text('تفعيل السمة الداكنة لإراحة عينيك', style: TextStyle(fontSize: 12)),
                  secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: const Color(0xFF64748B)),
                  value: isDark,
                  activeColor: primaryColor,
                  onChanged: (val) {
                    themeProvider.toggleTheme();
                  },
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms, delay: 200.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 20),

          // 3.5. Interactive Buddy Navigation Card
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              leading: Icon(Icons.videogame_asset, color: primaryColor, size: 28),
              title: const Text(
                'ألعاب الرفيق وعجلة الحظ 🎮🎡',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Cairo'),
              ),
              subtitle: const Text(
                'تخصيص رفيقك التفاعلي، ألعاب النقاط، ومخزون الهدايا الخاص بك',
                style: TextStyle(fontSize: 12, fontFamily: 'Cairo', color: Colors.grey),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BuddySettingsScreen(currentUser: widget.currentUser),
                  ),
                );
              },
            ),
          ).animate().fadeIn(duration: 300.ms, delay: 250.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 20),

          // 3.75. Buddy Store Navigation Card
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              leading: Icon(Icons.storefront_rounded, color: Colors.amber.shade700, size: 28),
              title: const Text(
                'متجر Buddy 🏪',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Cairo'),
              ),
              subtitle: const Text(
                'شراء ثيمات المحادثة الرائعة وإطارات الملف الشخصي الحصرية',
                style: TextStyle(fontSize: 12, fontFamily: 'Cairo', color: Colors.grey),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BuddyStoreScreen(),
                  ),
                );
              },
            ),
          ).animate().fadeIn(duration: 300.ms, delay: 275.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 20),

          const SizedBox(height: 20),

          // 3.8. Blocked Users Card
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              leading: Icon(Icons.block_rounded, color: Colors.red.shade400, size: 28),
              title: const Text(
                'المستخدمون المحظورون 🚫',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Cairo'),
              ),
              subtitle: const Text(
                'إدارة وحذف الحظر عن المستخدمين المحظورين',
                style: TextStyle(fontSize: 12, fontFamily: 'Cairo', color: Colors.grey),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlockedUsersScreen(currentUserUid: widget.currentUser.uid),
                  ),
                );
              },
            ),
          ).animate().fadeIn(duration: 300.ms, delay: 280.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 20),

          // 4. Logout Button Card
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
              leading: const Icon(Icons.logout_rounded, color: Colors.red, size: 24),
              title: const Text(
                'تسجيل الخروج',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              onTap: () async {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('تسجيل الخروج'),
                    content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _auth.signOut();
                          if (context.mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const AuthWrapper()),
                              (route) => false,
                            );
                          }
                        },
                        child: const Text('خروج', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ).animate().fadeIn(duration: 300.ms, delay: 300.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class BlockedUsersScreen extends StatefulWidget {
  final String currentUserUid;
  const BlockedUsersScreen({super.key, required this.currentUserUid});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final _dbService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('المستخدمون المحظورون 🚫', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(widget.currentUserUid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('حدث خطأ في تحميل البيانات'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final List<String> blockedUids = data != null ? List<String>.from(data['blockedUsers'] ?? []) : [];

          if (blockedUids.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.block, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('قائمة الحظر فارغة', style: TextStyle(fontFamily: 'Cairo', fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }

          return FutureBuilder<List<UserModel>>(
            future: _dbService.getBlockedUsers(blockedUids),
            builder: (context, futureSnap) {
              if (futureSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final blockedUsers = futureSnap.data ?? [];
              if (blockedUsers.isEmpty) {
                return const Center(child: Text('فشل في تحميل قائمة المحظورين', style: TextStyle(fontFamily: 'Cairo')));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: blockedUsers.length,
                itemBuilder: (context, index) {
                  final blockedUser = blockedUsers[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(blockedUser.avatarUrl),
                        radius: 24,
                      ),
                      title: Text(
                        blockedUser.displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      subtitle: Text(
                        '@${blockedUser.username}',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          try {
                            await _dbService.unblockUser(widget.currentUserUid, blockedUser.uid);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('تم إلغاء حظر ${blockedUser.displayName} بنجاح', style: const TextStyle(fontFamily: 'Cairo')),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('خطأ: $e')),
                            );
                          }
                        },
                        child: const Text(
                          'إلغاء الحظر',
                          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
