import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../widgets/avatar_with_frame.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../widgets/verification_badge.dart';

class BuddyStoreScreen extends StatefulWidget {
  const BuddyStoreScreen({super.key});

  @override
  State<BuddyStoreScreen> createState() => _BuddyStoreScreenState();
}

class _BuddyStoreScreenState extends State<BuddyStoreScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isProcessing = false;

  // Catalog items
  final List<Map<String, dynamic>> _chatThemes = [
    // Static Themes (Paid)
    {'id': 'sunset', 'name': 'الغروب الساحر', 'type': 'static', 'emoji': '🌇', 'points': 200, 'desc': 'تدرج لوني دافئ للغروب الملهم للمحادثة', 'colors': [Color(0xFFFF512F), Color(0xFFDD2476)]},
    {'id': 'forest', 'name': 'الغابة الهادئة', 'type': 'static', 'emoji': '🌲', 'points': 200, 'desc': 'تدرج طبيعي مهدئ بألوان الغابات الزمردية', 'colors': [Color(0xFF11998E), Color(0xFF38EF7D)]},
    {'id': 'gold', 'name': 'الذهب الملكي', 'type': 'static', 'emoji': '🔱', 'points': 300, 'desc': 'تدرج ملكي ذهبي غامق يعكس الفخامة والوقار', 'colors': [Color(0xFF2C220E), Color(0xFF120E05)]},
    // Animated Themes (Paid)
    {'id': 'fire', 'name': 'اللهيب الحماسي', 'type': 'animated', 'emoji': '🔥', 'points': 400, 'desc': 'ثيم داكن دافئ مع جزيئات نار متصاعدة متطايرة', 'colors': [Color(0xFF180800), Color(0xFF000000)]},
    {'id': 'ocean', 'name': 'أمواج المحيط', 'type': 'animated', 'emoji': '🌊', 'points': 400, 'desc': 'ثيم بحري ساحر مع أمواج جارية هادئة متحركة', 'colors': [Color(0xFF0F172A), Color(0xFF070B19)]},
  ];

  final List<Map<String, dynamic>> _profileFrames = [
    {'id': 'neon_ring', 'name': 'حلقة النيون', 'emoji': '✨', 'points': 250, 'desc': 'إطار نيون مضيء بلون تركواز جذاب'},
    {'id': 'golden_aura', 'name': 'الهالة الذهبية', 'emoji': '🌟', 'points': 350, 'desc': 'إطار ذهبي ملكي يحيط بملفك'},
    {'id': 'fire_flame', 'name': 'لهيب النار', 'emoji': '🔥', 'points': 400, 'desc': 'إطار حارق متدرج بلون أحمر وبرتقالي'},
    {'id': 'golden_crown', 'name': 'التاج الملكي', 'emoji': '👑', 'points': 500, 'desc': 'تاج ذهبي فاخر يعلو صورتك الشخصية'},
    {'id': 'rainbow_magic', 'name': 'سحر قوس قزح', 'emoji': '🌈', 'points': 600, 'desc': 'إطار متحرك بجميع ألوان الطيف البهية'},
  ];

  final List<Map<String, dynamic>> _verifications = [
    {'id': 'blue_badge', 'name': 'العلامة الزرقاء الملكية', 'emoji': '💙', 'points': 1000, 'color': Colors.blue, 'desc': 'العلامة الرسمية الأعلى فئة لتأكيد هويتك'},
    {'id': 'purple_badge', 'name': 'العلامة البنفسجية الفاخرة', 'emoji': '💜', 'points': 700, 'color': Colors.purple, 'desc': 'العلامة البنفسجية الأنيقة والفريدة من نوعها'},
    {'id': 'green_badge', 'name': 'العلامة الخضراء المميزة', 'emoji': '💚', 'points': 500, 'color': Colors.green, 'desc': 'علامة التوثيق للحسابات النشطة والموثوقة'},
    {'id': 'gray_badge', 'name': 'العلامة الرمادية الكلاسيكية', 'emoji': '🩶', 'points': 250, 'color': Colors.grey, 'desc': 'علامة توثيق للمستخدمين المساهمين في المجتمع'},
    {'id': 'random_badge', 'name': 'التوثيق العشوائي الغامض ❓', 'emoji': '❓', 'points': 100, 'color': Colors.amber, 'desc': 'افتح علبة التوثيق الغامضة لتحصل على شارة عشوائية فخمة!'},
  ];

  List<Map<String, dynamic>> _stickers = [];
  bool _isLoadingStickers = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchStickers();
  }

  Future<void> _fetchStickers() async {
    setState(() => _isLoadingStickers = true);
    try {
      final response = await http.get(Uri.parse('https://raw.githubusercontent.com/badralzabi/stic/refs/heads/main/store_data.json'));
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _stickers = List<Map<String, dynamic>>.from(data['stickers']);
        });
      }
    } catch (e) {
      print('Error fetching stickers: $e');
    } finally {
      if (mounted) setState(() => _isLoadingStickers = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  Future<void> _purchaseTheme(UserModel user, String themeId, int cost, String name) async {
    if (user.buddyPoints < cost) {
      _showError('نقاط Buddy الخاصة بك غير كافية لشراء هذا الثيم!');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الشراء', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        content: Text('هل ترغب في شراء ثيم "$name" مقابل $cost نقطة Buddy؟', style: const TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('شراء', style: TextStyle(fontFamily: 'Cairo', color: Colors.indigo, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        if (!snapshot.exists) throw Exception('المستخدم غير موجود!');
        final data = snapshot.data()!;
        final currentPoints = data['buddyPoints'] is int ? data['buddyPoints'] as int : 0;
        if (currentPoints < cost) throw Exception('نقاطك غير كافية!');

        final unlocked = List<String>.from(data['unlockedThemes'] ?? ['default']);
        if (!unlocked.contains(themeId)) {
          unlocked.add(themeId);
        }

        transaction.update(userRef, {
          'buddyPoints': currentPoints - cost,
          'unlockedThemes': unlocked,
        });
      });

      _showSuccess('تم شراء ثيم "$name" بنجاح! 🎨');
    } catch (e) {
      _showError('حدث خطأ أثناء الشراء: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _purchaseFrame(UserModel user, String frameId, int cost, String name) async {
    if (user.buddyPoints < cost) {
      _showError('نقاط Buddy الخاصة بك غير كافية لشراء هذا الإطار!');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الشراء', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        content: Text('هل ترغب في شراء إطار "$name" مقابل $cost نقطة Buddy؟', style: const TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('شراء', style: TextStyle(fontFamily: 'Cairo', color: Colors.indigo, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        if (!snapshot.exists) throw Exception('المستخدم غير موجود!');
        final data = snapshot.data()!;
        final currentPoints = data['buddyPoints'] is int ? data['buddyPoints'] as int : 0;
        if (currentPoints < cost) throw Exception('نقاطك غير كافية!');

        final unlocked = List<String>.from(data['unlockedFrames'] ?? []);
        if (!unlocked.contains(frameId)) {
          unlocked.add(frameId);
        }

        transaction.update(userRef, {
          'buddyPoints': currentPoints - cost,
          'unlockedFrames': unlocked,
        });
      });

      _showSuccess('تم شراء إطار "$name" بنجاح! 👑');
    } catch (e) {
      _showError('حدث خطأ أثناء الشراء: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _purchaseVerification(UserModel user, String verifId, int cost, String name) async {
    if (user.buddyPoints < cost) {
      _showError('نقاط Buddy الخاصة بك غير كافية لشراء علامة التوثيق هذه!');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الشراء', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        content: Text('هل ترغب في شراء "$name" مقابل $cost نقطة Buddy؟', style: const TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('شراء', style: TextStyle(fontFamily: 'Cairo', color: Colors.indigo, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isProcessing = true;
    });

    String? newlyUnlockedBadgeId;

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        if (!snapshot.exists) throw Exception('المستخدم غير موجود!');
        final data = snapshot.data()!;
        final currentPoints = data['buddyPoints'] is int ? data['buddyPoints'] as int : 0;
        if (currentPoints < cost) throw Exception('نقاطك غير كافية!');

        final unlocked = List<String>.from(data['unlockedVerifications'] ?? []);
        
        if (verifId == 'random_badge') {
          if (unlocked.contains('random_badge_purchased')) {
            throw 'لقد قمت بشراء التوثيق العشوائي مسبقاً! مسموح لمرة واحدة فقط.';
          }
          final allPool = ['blue_badge', 'purple_badge', 'green_badge', 'gray_badge'];
          final pool = allPool.where((id) => !unlocked.contains(id)).toList();
          if (pool.isEmpty) {
            throw 'لقد قمت بفتح جميع علامات التوثيق المتاحة بالفعل! 🌟';
          }
          pool.shuffle();
          newlyUnlockedBadgeId = pool.first;
          unlocked.add(newlyUnlockedBadgeId!);
          unlocked.add('random_badge_purchased');
        } else {
          if (!unlocked.contains(verifId)) {
            unlocked.add(verifId);
          }
        }

        transaction.update(userRef, {
          'buddyPoints': currentPoints - cost,
          'unlockedVerifications': unlocked,
        });
      });

      if (verifId == 'random_badge' && newlyUnlockedBadgeId != null) {
        final badgeDetail = _verifications.firstWhere((element) => element['id'] == newlyUnlockedBadgeId, orElse: () => {'name': newlyUnlockedBadgeId, 'emoji': '🎉', 'color': Colors.blue});
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text(
              'العلبة العشوائية! 🎁',
              style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'لقد فتحت العلبة الغامضة وحصلت على:',
                  style: TextStyle(color: Colors.grey, fontFamily: 'Cairo', fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  '${badgeDetail['emoji']} ${badgeDetail['name']}',
                  style: TextStyle(color: badgeDetail['color'] as Color? ?? Colors.blue, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Icon(Icons.verified, color: badgeDetail['color'] as Color? ?? Colors.blue, size: 60),
              ],
            ),
            actions: [
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('رائع! 🎉', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        );
      } else {
        _showSuccess('تم شراء "$name" بنجاح! ✅');
      }
    } catch (e) {
      _showError('حدث خطأ أثناء الشراء: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _purchaseSticker(UserModel user, String stickerId, int cost, String name) async {
    if (user.buddyPoints < cost) {
      _showError('نقاط Buddy الخاصة بك غير كافية لشراء هذا الملصق!');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الشراء', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        content: Text('هل ترغب في شراء ملصق "$name" مقابل $cost نقطة Buddy؟\n\nيمكنك استخدامه في التعليقات.', style: const TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('شراء', style: TextStyle(fontFamily: 'Cairo', color: Colors.indigo, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() { _isProcessing = true; });

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final snapshot = await transaction.get(userDocRef);
        final currentPoints = snapshot.data()?['buddyPoints'] ?? 0;
        final currentStickers = List<String>.from(snapshot.data()?['unlockedStickers'] ?? []);

        if (currentPoints < cost) throw Exception('not_enough_points');

        currentStickers.add(stickerId);

        transaction.update(userDocRef, {
          'buddyPoints': currentPoints - cost,
          'unlockedStickers': currentStickers,
        });
      });

      _showSuccess('تم شراء الملصق بنجاح! يمكنك الآن استخدامه في التعليقات. 🎭');
    } catch (e) {
      if (e.toString().contains('not_enough_points')) {
        _showError('نقاط Buddy غير كافية لإتمام الشراء!');
      } else {
        _showError('حدث خطأ أثناء الشراء. حاول مرة أخرى.');
      }
    } finally {
      setState(() { _isProcessing = false; });
    }
  }

  Future<void> _toggleFrameEquipped(UserModel user, String frameId, bool isEquipped) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      await userRef.update({
        'equippedFrame': isEquipped ? FieldValue.delete() : frameId,
      });
      _showSuccess(isEquipped ? 'تم إلغاء تفعيل الإطار!' : 'تم تفعيل الإطار بنجاح! 👑');
    } catch (e) {
      _showError('حدث خطأ: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _toggleVerificationEquipped(UserModel user, String verifId, bool isEquipped) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      await userRef.update({
        'equippedVerification': isEquipped ? FieldValue.delete() : verifId,
        'isVerified': false, // Turn off legacy verification flag if toggled
      });
      _showSuccess(isEquipped ? 'تم إلغاء تفعيل العلامة!' : 'تم تفعيل علامة التوثيق بنجاح! ✅');
    } catch (e) {
      _showError('حدث خطأ: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('الرجاء تسجيل الدخول أولاً!')),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('متجر Buddy 🏪', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                  : [Colors.white, const Color(0xFFF1F5F9)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('خطأ في تحميل بيانات المستخدم!'));
          }

          final user = UserModel.fromMap(
            snapshot.data!.data() as Map<String, dynamic>,
            snapshot.data!.id,
          );

          // Get active verification display emoji
          String verifText = 'بدون توثيق حالياً';
          if (user.isVerified) {
            verifText = 'موقّع بالعلامة الزرقاء 💙';
          } else if (user.equippedVerification != null) {
            final equipped = _verifications.firstWhere((v) => v['id'] == user.equippedVerification, orElse: () => <String, dynamic>{});
            if (equipped.isNotEmpty) {
              verifText = '${equipped['name']} ${equipped['emoji']}';
            }
          }

          return Column(
            children: [
              // User Balance & Preview Section
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                  ),
                ),
                child: Row(
                  children: [
                    // Preview Avatar with Frame
                    AvatarWithFrame(
                      avatarUrl: user.avatarUrl,
                      radius: 35,
                      frameId: user.equippedFrame,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                user.displayName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Cairo'),
                              ),
                              VerificationBadge(user: user, size: 18),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            verifText,
                            style: TextStyle(
                              fontSize: 12,
                              color: user.isVerified
                                  ? Colors.blue
                                  : (user.equippedVerification == 'green_badge'
                                      ? Colors.green
                                      : (user.equippedVerification == 'gray_badge' ? Colors.grey : Colors.grey)),
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Points counter
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B5CF6).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🪙 ', style: TextStyle(fontSize: 16)),
                          Text(
                            '${user.buddyPoints}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Buddy',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // TabBar Selector
              TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF8B5CF6),
                labelColor: const Color(0xFF8B5CF6),
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: 'ثيمات المحادثة 🎨'),
                  Tab(text: 'إطارات الملف 👑'),
                  Tab(text: 'التوثيقات ✅'),
                  Tab(text: 'ملصقات 🎭'),
                ],
              ),

              // TabBar View
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildThemesTab(user),
                    _buildFramesTab(user),
                    _buildVerificationsTab(user),
                    _buildStickersTab(user),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildThemesTab(UserModel user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Categorize
    final staticThemes = _chatThemes.where((t) => t['type'] == 'static').toList();
    final animatedThemes = _chatThemes.where((t) => t['type'] == 'animated').toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('ثيمات ثابتة (Static Themes)', '🎨'),
        const SizedBox(height: 12),
        ...staticThemes.map((theme) => _buildThemeCard(user, theme, isDark)),
        const SizedBox(height: 24),
        _buildSectionHeader('ثيمات متحركة (Animated Themes)', '✨'),
        const SizedBox(height: 12),
        ...animatedThemes.map((theme) => _buildThemeCard(user, theme, isDark)),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String emoji) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }

  Widget _buildThemeCard(UserModel user, Map<String, dynamic> theme, bool isDark) {
    final isUnlocked = user.unlockedThemes.contains(theme['id']);
    final colors = theme['colors'] as List<Color>;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
        ),
      ),
      child: Row(
        children: [
          // Theme Preview Circle
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors[0].withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(theme['emoji'] as String, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 16),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  theme['name'] as String,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Cairo'),
                ),
                const SizedBox(height: 4),
                Text(
                  theme['desc'] as String,
                  style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Cairo'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Action button
          if (isUnlocked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'ممتلك ✔️',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Cairo'),
              ),
            )
          else
            ElevatedButton(
              onPressed: _isProcessing ? null : () => _purchaseTheme(user, theme['id'] as String, theme['points'] as int, theme['name'] as String),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                elevation: 0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🪙 ', style: TextStyle(fontSize: 12)),
                  Text(
                    '${theme['points']}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFramesTab(UserModel user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.78,
      ),
      itemCount: _profileFrames.length,
      itemBuilder: (context, index) {
        final frame = _profileFrames[index];
        final isUnlocked = user.unlockedFrames.contains(frame['id']);
        final isEquipped = user.equippedFrame == frame['id'];

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isEquipped
                  ? Colors.amber
                  : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
              width: isEquipped ? 2 : 1,
            ),
            boxShadow: [
              if (isEquipped)
                BoxShadow(
                  color: Colors.amber.withOpacity(0.15),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Frame Preview
              AvatarWithFrame(
                avatarUrl: user.avatarUrl,
                radius: 28,
                frameId: frame['id'] as String,
              ),
              const SizedBox(height: 8),
              // Name & Desc
              Text(
                frame['name'] as String,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Cairo'),
                textAlign: TextAlign.center,
              ),
              Text(
                frame['desc'] as String,
                style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Cairo'),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Button
              if (isUnlocked)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : () => _toggleFrameEquipped(user, frame['id'] as String, isEquipped),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isEquipped ? Colors.amber.shade700 : Colors.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 0,
                    ),
                    child: Text(
                      isEquipped ? 'إلغاء التفعيل' : 'تفعيل إطار 👑',
                      style: const TextStyle(fontSize: 11, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                    ),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : () => _purchaseFrame(user, frame['id'] as String, frame['points'] as int, frame['name'] as String),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🪙 ', style: TextStyle(fontSize: 11)),
                        Text(
                          '${frame['points']}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVerificationsTab(UserModel user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _verifications.length,
      itemBuilder: (context, index) {
        final verif = _verifications[index];
        final isRandomBadge = verif['id'] == 'random_badge';
        final isUnlocked = isRandomBadge 
            ? (user.unlockedVerifications.contains('random_badge_purchased') || user.unlockedVerifications.any((id) => ['blue_badge', 'purple_badge', 'green_badge', 'gray_badge'].contains(id))) 
            : user.unlockedVerifications.contains(verif['id']);
        final isEquipped = user.equippedVerification == verif['id'];
        final badgeColor = verif['color'] as Color;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
            ),
          ),
          child: Row(
            children: [
              // Badge Icon Preview
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: badgeColor.withOpacity(0.1),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.verified, color: badgeColor, size: 30),
              ),
              const SizedBox(width: 16),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      verif['name'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Cairo'),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      verif['desc'] as String,
                      style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Cairo'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Action Button
              if (isUnlocked)
                if (isRandomBadge)
                  ElevatedButton(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      elevation: 0,
                    ),
                    child: const Text('تم الشراء لمرة واحدة', style: TextStyle(fontSize: 10, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                  )
                else
                  ElevatedButton(
                    onPressed: _isProcessing ? null : () => _toggleVerificationEquipped(user, verif['id'] as String, isEquipped),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isEquipped ? Colors.amber.shade700 : Colors.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      elevation: 0,
                    ),
                    child: Text(
                      isEquipped ? 'إلغاء التفعيل' : 'تفعيل ✅',
                      style: const TextStyle(fontSize: 11, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                    ),
                  )
              else
                ElevatedButton(
                  onPressed: _isProcessing ? null : () => _purchaseVerification(user, verif['id'] as String, verif['points'] as int, verif['name'] as String),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🪙 ', style: TextStyle(fontSize: 12)),
                      Text(
                        '${verif['points']}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
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

  Widget _buildStickersTab(UserModel user) {
    if (_isLoadingStickers) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _stickers.length,
      itemBuilder: (context, index) {
        final sticker = _stickers[index];
        final bool isUnlocked = user.unlockedStickers.contains(sticker['id']);
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: isDark ? 0 : 4,
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          shadowColor: Colors.black.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.indigo.withOpacity(0.1), width: 1),
                  ),
                  child: Center(
                    child: Image.network(
                      'https://raw.githubusercontent.com/badralzabi/stic/refs/heads/main/GIF/${sticker['id']}',
                      width: 50,
                      height: 50,
                      errorBuilder: (context, error, stackTrace) => Text(sticker['emoji'], style: const TextStyle(fontSize: 32)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sticker['name'],
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sticker['desc'],
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.stars_rounded, color: Color(0xFFF59E0B), size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '${sticker['points']}',
                                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isUnlocked)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
                  )
                else
                  ElevatedButton(
                    onPressed: _isProcessing ? null : () => _purchaseSticker(user, sticker['id'], sticker['points'], sticker['name']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('شراء', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
