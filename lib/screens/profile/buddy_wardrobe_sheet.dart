import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/user_model.dart';
import '../../services/db_service.dart';
import '../../widgets/buddy_accessory_painter.dart';

class BuddyWardrobeSheet extends StatefulWidget {
  final UserModel currentUser;

  const BuddyWardrobeSheet({super.key, required this.currentUser});

  static void show(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => BuddyWardrobeSheet(currentUser: user),
    );
  }

  @override
  State<BuddyWardrobeSheet> createState() => _BuddyWardrobeSheetState();
}

class _BuddyWardrobeSheetState extends State<BuddyWardrobeSheet> {
  final DatabaseService _dbService = DatabaseService();

  // Search and transfer states
  String _selectedCategory = 'all'; // 'all', 'hat', 'eye', 'neck', 'hand', 'back'

  final List<Map<String, String>> _categories = [
    {'id': 'all', 'name': 'الكل 👑'},
    {'id': 'hat', 'name': 'القبعات 🎩'},
    {'id': 'eye', 'name': 'النظارات 🕶️'},
    {'id': 'neck', 'name': 'الأوشحة 🧣'},
    {'id': 'hand', 'name': 'المعدات ⚔️'},
    {'id': 'back', 'name': 'الأجنحة 👼'},
  ];



  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF6366F1);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.currentUser.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final user = UserModel.fromMap(userData, widget.currentUser.uid);

        // Filter accessories based on active category tab
        final filteredAccessories = BuddyAccessory.allAccessories.where((item) {
          if (_selectedCategory == 'all') return true;
          if (_selectedCategory == 'hand') return item.anchorType.startsWith('hand');
          return item.anchorType == _selectedCategory;
        }).toList();

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A).withOpacity(0.8) : Colors.white.withOpacity(0.85),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Bottom sheet handle bar
                      Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white30 : Colors.black26,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Title and Points Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'خزانة الرفيق والمتجر 🎭',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFBBF24).withOpacity(0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  '🪙',
                                  style: TextStyle(fontSize: 18),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${user.buddyPoints} نقطة',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ],
                            ),
                          ).animate().scale(duration: 350.ms, curve: Curves.easeOutBack),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'احصل على النقاط عبر التفاعل والمراسلة (+5) ونشر القصص (+20)!',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white54 : Colors.black54,
                            fontFamily: 'Cairo',
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Category Tabs
                      _buildCategoryTabs(isDark, primaryColor),
                      const SizedBox(height: 16),

                      // Wardrobe Grid List
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.82,
                        ),
                        itemCount: filteredAccessories.length,
                        itemBuilder: (context, index) {
                          final item = filteredAccessories[index];
                          final isUnlocked = user.unlockedAccessories.contains(item.id);
                          final isEquipped = user.equippedAccessory == item.id;

                          return _buildShopItemCard(
                            context: context,
                            item: item,
                            isUnlocked: isUnlocked,
                            isEquipped: isEquipped,
                            userPoints: user.buddyPoints,
                            uid: user.uid,
                            isDark: isDark,
                            primaryColor: primaryColor,
                          ).animate(delay: (index * 30).ms).fadeIn(duration: 250.ms).slideY(begin: 0.08, end: 0);
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryTabs(bool isDark, Color primaryColor) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final catId = cat['id']!;
          final catName = cat['name']!;
          final isSelected = _selectedCategory == catId;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = catId;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [primaryColor, primaryColor.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: !isSelected
                    ? (isDark ? const Color(0xFF1E293B).withOpacity(0.5) : const Color(0xFFF1F5F9).withOpacity(0.5))
                    : null,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected
                      ? primaryColor.withOpacity(0.3)
                      : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  catName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShopItemCard({
    required BuildContext context,
    required BuddyAccessory item,
    required bool isUnlocked,
    required bool isEquipped,
    required int userPoints,
    required String uid,
    required bool isDark,
    required Color primaryColor,
  }) {
    Widget cardContent = Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withOpacity(0.6) : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isEquipped
              ? primaryColor
              : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04)),
          width: isEquipped ? 2 : 1,
        ),
        boxShadow: [
          if (isEquipped)
            BoxShadow(
              color: primaryColor.withOpacity(0.25),
              blurRadius: 12,
              spreadRadius: 1,
            )
          else
            BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Column(
        children: [
          // 1. Accessory Preview Orb
          Expanded(
            child: Stack(
              children: [
                Center(
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: isDark
                            ? [primaryColor.withOpacity(0.16), Colors.transparent]
                            : [primaryColor.withOpacity(0.08), Colors.transparent],
                      ),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          '⭐',
                          style: TextStyle(
                            fontSize: 38,
                            color: isDark 
                                ? Colors.amber.withOpacity(0.22) 
                                : Colors.amber.withOpacity(0.35),
                          ),
                        ),
                        SizedBox(
                          width: 66,
                          height: 66,
                          child: CustomPaint(
                            painter: BuddyAccessoryPainter(
                              accessoryId: item.id,
                              characterEmoji: '⭐',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black26 : Colors.black12,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      item.emoji,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Info Block
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  item.desc,
                  style: TextStyle(
                    fontSize: 8.5,
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontFamily: 'Cairo',
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // 3. Action Button
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: SizedBox(
              width: double.infinity,
              height: 30,
              child: _buildButton(
                context: context,
                isUnlocked: isUnlocked,
                isEquipped: isEquipped,
                price: item.price,
                userPoints: userPoints,
                uid: uid,
                itemId: item.id,
                primaryColor: primaryColor,
                isDark: isDark,
              ),
            ),
          ),
        ],
      ),
    );

    if (isEquipped) {
      return cardContent
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .scale(end: const Offset(1.02, 1.02), duration: 1200.ms, curve: Curves.easeInOut);
    }
    return cardContent;
  }

  Widget _buildButton({
    required BuildContext context,
    required bool isUnlocked,
    required bool isEquipped,
    required int price,
    required int userPoints,
    required String uid,
    required String itemId,
    required Color primaryColor,
    required bool isDark,
  }) {
    if (isUnlocked) {
      if (isEquipped) {
        return OutlinedButton(
          onPressed: () async {
            try {
              await _dbService.equipAccessory(uid, null);
            } catch (e) {
              _showError(context, e.toString());
            }
          },
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.red, width: 1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: EdgeInsets.zero,
          ),
          child: const Text(
            'نزع الملحق',
            style: TextStyle(color: Colors.red, fontSize: 10.5, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
          ),
        );
      } else {
        return ElevatedButton(
          onPressed: () async {
            try {
              await _dbService.equipAccessory(uid, itemId);
            } catch (e) {
              _showError(context, e.toString());
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: EdgeInsets.zero,
          ),
          child: const Text(
            'ارتداء',
            style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
          ),
        );
      }
    } else {
      final bool canAfford = userPoints >= price;
      return ElevatedButton(
        onPressed: canAfford
            ? () async {
                try {
                  await _dbService.buyAccessory(uid, itemId, price);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('مبروك! تم شراء الملحق بنجاح 🎉', style: TextStyle(fontFamily: 'Cairo')),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                } catch (e) {
                  _showError(context, e.toString());
                }
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          disabledBackgroundColor: isDark ? Colors.white10 : Colors.black12,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'شراء بـ $price',
              style: TextStyle(
                color: canAfford ? Colors.black87 : Colors.grey,
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(width: 2),
            Text(
              '🪙',
              style: TextStyle(fontSize: 10, color: canAfford ? null : Colors.grey),
            ),
          ],
        ),
      );
    }
  }

  void _showError(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('خطأ: $error', style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: Colors.red,
      ),
    );
  }
}
