import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../models/user_model.dart';
import '../../services/db_service.dart';
import '../../services/buddy_preferences.dart';
import '../../services/buddy_audio_generator.dart';
import '../../widgets/buddy_accessory_painter.dart';
import '../../widgets/lucky_wheel_dialog.dart';
import 'buddy_wardrobe_sheet.dart';

class BuddySettingsScreen extends StatefulWidget {
  final UserModel currentUser;

  const BuddySettingsScreen({super.key, required this.currentUser});

  @override
  State<BuddySettingsScreen> createState() => _BuddySettingsScreenState();
}

class _BuddySettingsScreenState extends State<BuddySettingsScreen> {
  final DatabaseService _dbService = DatabaseService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _buddyEnabled = false;
  String _buddyCharacter = '🐱';
  String _buddySound = 'pop';

  // Points Transfer State
  final _searchController = TextEditingController();
  final _amountController = TextEditingController();
  String _searchQuery = '';
  UserModel? _selectedUser;
  bool _isTransferring = false;

  @override
  void initState() {
    super.initState();
    _loadBuddySettings();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _searchController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _loadBuddySettings() async {
    final enabled = await BuddyPreferences.isEnabled();
    final character = await BuddyPreferences.getCharacter();
    final sound = await BuddyPreferences.getSound();
    if (mounted) {
      setState(() {
        _buddyEnabled = enabled;
        _buddyCharacter = character;
        _buddySound = sound;
      });
    }
  }

  void _playPreview(String soundType) async {
    try {
      final path = await BuddyAudioGenerator.generateSound(soundType);
      if (path.isNotEmpty) {
        await _audioPlayer.play(DeviceFileSource(path));
      }
    } catch (e) {
      debugPrint('Error playing preview: $e');
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSellGiftDialog(BuildContext context, Map<String, dynamic> gift, String userId) {
    final emoji = gift['emoji'] ?? '🎁';
    final name = gift['name'] ?? '';
    final pointsValue = gift['points'] ?? 0;
    final giftId = gift['id'] ?? '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'استبدال الهدية 🪙',
          style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 50),
            ),
            const SizedBox(height: 12),
            Text(
              'هل ترغب في استبدال هدية "$name" ونقاطها؟',
              style: const TextStyle(color: Colors.grey, fontFamily: 'Cairo', fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'سوف تحصل على: +$pointsValue نقطة 🪙',
              style: const TextStyle(color: Color(0xFF10B981), fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _dbService.sellGift(userId, giftId, pointsValue);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم استبدال الهدية بـ $pointsValue نقطة بنجاح! 🪙', style: const TextStyle(fontFamily: 'Cairo')),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('خطأ أثناء الاستبدال: $e', style: const TextStyle(fontFamily: 'Cairo')),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('تأكيد الاستبدال 🪙', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF6366F1);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.currentUser.uid).snapshots(),
      builder: (context, userSnapshot) {
        final dbUser = userSnapshot.hasData && userSnapshot.data!.exists
            ? UserModel.fromMap(userSnapshot.data!.data() as Map<String, dynamic>, widget.currentUser.uid)
            : widget.currentUser;

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text(
              'ألعاب الرفيق وعجلة الحظ 🎮🎡',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Cairo'),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            children: [
              // 1. Point Balance & Lucky Wheel Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'رصيدك الحالي',
                          style: TextStyle(color: Colors.white70, fontSize: 14, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Text('🪙', style: TextStyle(fontSize: 14)),
                              SizedBox(width: 4),
                              Text(
                                'نقاط Buddy',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${dbUser.buddyPoints}',
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'نقطة',
                          style: TextStyle(fontSize: 14, color: Colors.white70, fontFamily: 'Cairo'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Lucky Wheel Button
                    InkWell(
                      onTap: () {
                        // Check eligibility
                        final lastSpin = dbUser.lastWheelSpin;
                        if (lastSpin != null) {
                          final difference = DateTime.now().difference(lastSpin);
                          if (difference.inHours < 2) {
                            final remainingMinutes = 120 - difference.inMinutes;
                            _showError(context, 'عجلة الحظ متاحة مرة كل ساعتين! يرجى الانتظار $remainingMinutes دقيقة.');
                            return;
                          }
                        }
                        LuckyWheelDialog.show(context, dbUser.uid);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('🎡', style: TextStyle(fontSize: 18)),
                            SizedBox(width: 8),
                            Text(
                              'أدر عجلة الحظ اليومية لربح النقاط!',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontFamily: 'Cairo', fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
              const SizedBox(height: 24),

              // 2. Interactive Buddy Settings Card
              Container(
                padding: const EdgeInsets.all(20),
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
                    Row(
                      children: [
                        Icon(Icons.face_retouching_natural, color: primaryColor, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'تخصيص الرفيق التفاعلي',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor, fontFamily: 'Cairo'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      title: const Text('تفعيل الرفيق في المحادثة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Cairo')),
                      subtitle: const Text('شخصية تفاعلية تظهر بأسفل المحادثة وتصدر أصواتاً عند لمسها', style: TextStyle(fontSize: 11, fontFamily: 'Cairo')),
                      value: _buddyEnabled,
                      activeColor: primaryColor,
                      onChanged: (val) async {
                        setState(() => _buddyEnabled = val);
                        await BuddyPreferences.setEnabled(val);
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (_buddyEnabled) ...[
                      const Divider(height: 24, thickness: 0.5),
                      const Text(
                        'مظهر الرفيق (شخصية الأفاتار):',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 90,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: BuddyPreferences.characters.length,
                          itemBuilder: (context, index) {
                            final char = BuddyPreferences.characters[index];
                            final isSelected = _buddyCharacter == char['emoji'];
                            return GestureDetector(
                              onTap: () async {
                                setState(() => _buddyCharacter = char['emoji']!);
                                await BuddyPreferences.setCharacter(char['emoji']!);
                              },
                              child: Container(
                                width: 85,
                                margin: const EdgeInsets.only(left: 12),
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? primaryColor.withOpacity(0.15) 
                                      : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected ? primaryColor : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    char['svg'] != null
                                        ? SizedBox(
                                            width: 32,
                                            height: 32,
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                SvgPicture.asset(
                                                  char['svg']!,
                                                  width: 32,
                                                  height: 32,
                                                )
                                                .animate(onPlay: (c) => c.repeat(reverse: true))
                                                  .slideY(begin: 0, end: -0.08, duration: 1400.ms, curve: Curves.easeInOut)
                                                .animate(onPlay: (c) => c.repeat(reverse: true))
                                                  .scaleXY(begin: 0.95, end: 1.05, duration: 1200.ms, curve: Curves.easeInOut)
                                                .animate(onPlay: (c) => c.repeat(reverse: true))
                                                  .rotate(begin: -0.02, end: 0.02, duration: 1600.ms, curve: Curves.easeInOut),
                                                if (dbUser.equippedAccessory != null && isSelected)
                                                  Positioned.fill(
                                                    child: CustomPaint(
                                                      painter: BuddyAccessoryPainter(
                                                        accessoryId: dbUser.equippedAccessory,
                                                        characterEmoji: char['emoji']!,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          )
                                        : Text(char['emoji']!, style: const TextStyle(fontSize: 28)),
                                    const SizedBox(height: 4),
                                    Text(
                                      char['name']!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected ? primaryColor : (isDark ? Colors.white70 : Colors.black54),
                                        fontFamily: 'Cairo',
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => BuddyWardrobeSheet.show(context, dbUser),
                        icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                        label: const Text('خزانة الرفيق والمتجر 🎭', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: BorderSide(color: primaryColor.withOpacity(0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                      const Divider(height: 24, thickness: 0.5),

                      // Sound selection
                      const Text(
                        'صوت التفاعل:',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                      ),
                      const SizedBox(height: 8),
                      ...BuddyPreferences.sounds.map((sound) {
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: RadioListTile<String>(
                                  title: Text(
                                    sound['name']!,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                                  ),
                                  value: sound['id']!,
                                  groupValue: _buddySound,
                                  activeColor: primaryColor,
                                  onChanged: (val) async {
                                    if (val != null) {
                                      setState(() => _buddySound = val);
                                      await BuddyPreferences.setSound(val);
                                      _playPreview(val);
                                    }
                                  },
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.play_circle_outline, color: primaryColor),
                                onPressed: () => _playPreview(sound['id']!),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.1, end: 0),
              const SizedBox(height: 24),

              // 3. Points Transfer Section
              _buildPointsTransferSection(dbUser, isDark, primaryColor),
              const SizedBox(height: 24),

              // 4. Gift Inventory / Collection Grid (معرض هداياي)
              Container(
                padding: const EdgeInsets.all(20),
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
                    Row(
                      children: [
                        const Text('🎁', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(
                          'مخزون هداياي الخاصة',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor, fontFamily: 'Cairo'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'الهدايا التي تلقيتها من أصدقائك في المحادثات. يمكنك تجميعها أو إعادة إرسالها لأصدقائك!',
                      style: TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Cairo', height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _dbService.getUserGiftsStream(dbUser.uid),
                      builder: (context, giftSnapshot) {
                        if (giftSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final gifts = giftSnapshot.data ?? [];
                        if (gifts.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            alignment: Alignment.center,
                            child: const Column(
                              children: [
                                Text('📦', style: TextStyle(fontSize: 40)),
                                SizedBox(height: 8),
                                Text(
                                  'المخزون فارغ حالياً!',
                                  style: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'تبادل الهدايا مع أصدقائك داخل الشات لتعبئة مخزونك.',
                                  style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.9,
                          ),
                          itemCount: gifts.length,
                          itemBuilder: (context, index) {
                            final gift = gifts[index];
                            final emoji = gift['emoji'] ?? '🎁';
                            final name = gift['name'] ?? '';
                            final count = gift['count'] ?? 1;

                            return InkWell(
                              onTap: () => _showSellGiftDialog(context, gift, dbUser.uid),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.amber.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(emoji, style: const TextStyle(fontSize: 32)),
                                          const SizedBox(height: 4),
                                          Text(
                                            name,
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.amber,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          'x$count',
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 250.ms).slideY(begin: 0.1, end: 0),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPointsTransferSection(UserModel currentUser, bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Icon(Icons.swap_horizontal_circle_outlined, color: primaryColor, size: 22),
              const SizedBox(width: 8),
              Text(
                'إرسال نقاط Buddy لصديق',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: primaryColor, fontFamily: 'Cairo'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_selectedUser == null) ...[
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ابحث عن اسم المستخدم (Username)...',
                hintStyle: const TextStyle(fontSize: 13, fontFamily: 'Cairo'),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: primaryColor, width: 1.5),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
            const SizedBox(height: 10),
            if (_searchQuery.isNotEmpty)
              StreamBuilder<List<UserModel>>(
                stream: _dbService.searchUsers(_searchQuery),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }
                  final users = snapshot.data ?? [];
                  final filteredUsers = users.where((u) => u.uid != currentUser.uid).toList();

                  if (filteredUsers.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'لم يتم العثور على مستخدمين بهذا الاسم',
                        style: TextStyle(color: Colors.grey, fontSize: 13, fontFamily: 'Cairo'),
                      ),
                    );
                  }

                  return Container(
                    constraints: const BoxConstraints(maxHeight: 150),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      itemCount: filteredUsers.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final targetUser = filteredUsers[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(targetUser.avatarUrl),
                            radius: 18,
                          ),
                          title: Text(
                            targetUser.displayName,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                          ),
                          subtitle: Text(
                            '@${targetUser.username}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          trailing: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedUser = targetUser;
                                _searchQuery = '';
                                _searchController.clear();
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              minimumSize: const Size(60, 32),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('تحديد', style: TextStyle(fontSize: 12, fontFamily: 'Cairo')),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: primaryColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: NetworkImage(_selectedUser!.avatarUrl),
                        radius: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedUser!.displayName,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                            ),
                            Text(
                              '@${_selectedUser!.username}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedUser = null;
                            _amountController.clear();
                          });
                        },
                        child: const Text(
                          'تغيير',
                          style: TextStyle(color: Colors.red, fontSize: 13, fontFamily: 'Cairo'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'أدخل عدد النقاط...',
                            hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                            prefixIcon: const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Text('🪙', style: TextStyle(fontSize: 18)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: primaryColor, width: 1.5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isTransferring
                              ? null
                              : () async {
                                  final text = _amountController.text.trim();
                                  final amount = int.tryParse(text);
                                  if (amount == null || amount <= 0) {
                                    _showError(context, 'يرجى إدخال كمية نقاط صالحة!');
                                    return;
                                  }
                                  if (amount > currentUser.buddyPoints) {
                                    _showError(context, 'نقاطك غير كافية! رصيدك الحالي هو ${currentUser.buddyPoints}');
                                    return;
                                  }

                                  setState(() {
                                    _isTransferring = true;
                                  });

                                  try {
                                    await _dbService.transferPoints(
                                      currentUser.uid,
                                      _selectedUser!.uid,
                                      amount,
                                    );

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('تم إرسال $amount نقطة بنجاح إلى ${_selectedUser!.displayName} 🎉', style: const TextStyle(fontFamily: 'Cairo')),
                                          backgroundColor: const Color(0xFF10B981),
                                        ),
                                      );
                                    }

                                    setState(() {
                                      _selectedUser = null;
                                      _amountController.clear();
                                    });
                                  } catch (e) {
                                    if (context.mounted) {
                                      _showError(context, e.toString());
                                    }
                                  } finally {
                                    setState(() {
                                      _isTransferring = false;
                                    });
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black87,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                          ),
                          child: _isTransferring
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black87),
                                )
                              : const Text(
                                  'إرسال',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Cairo'),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
