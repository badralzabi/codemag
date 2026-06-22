import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/db_service.dart';

class GiftStoreSheet extends StatefulWidget {
  final String senderId;
  final String recipientId;
  final String roomId;
  final String recipientName;

  const GiftStoreSheet({
    super.key,
    required this.senderId,
    required this.recipientId,
    required this.roomId,
    required this.recipientName,
  });

  static void show(BuildContext context, {
    required String senderId,
    required String recipientId,
    required String roomId,
    required String recipientName,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => GiftStoreSheet(
        senderId: senderId,
        recipientId: recipientId,
        roomId: roomId,
        recipientName: recipientName,
      ),
    );
  }

  @override
  State<GiftStoreSheet> createState() => _GiftStoreSheetState();
}

class _GiftStoreSheetState extends State<GiftStoreSheet> with SingleTickerProviderStateMixin {
  final DatabaseService _dbService = DatabaseService();
  late TabController _tabController;
  bool _isProcessing = false;

  final List<Map<String, dynamic>> _giftCatalog = [
    {'id': 'love_rose', 'name': 'وردة الحب', 'emoji': '🌹', 'points': 50},
    {'id': 'luxury_chocolate', 'name': 'شوكولاتة فاخرة', 'emoji': '🍫', 'points': 100},
    {'id': 'celebration_balloon', 'name': 'بالون الاحتفال', 'emoji': '🎈', 'points': 150},
    {'id': 'cute_teddy', 'name': 'تيدي بير لطيف', 'emoji': '🧸', 'points': 250},
    {'id': 'warm_coffee', 'name': 'كوب قهوة دافئ', 'emoji': '☕', 'points': 80},
    {'id': 'golden_ring', 'name': 'خاتم ذهبي', 'emoji': '💍', 'points': 500},
    {'id': 'kings_crown', 'name': 'تاج الملك', 'emoji': '👑', 'points': 1000},
    {'id': 'sports_car', 'name': 'سيارة رياضية', 'emoji': '🏎️', 'points': 2500},
    {'id': 'space_rocket', 'name': 'صاروخ فضائي', 'emoji': '🚀', 'points': 5000},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

  Future<void> _handleBuyGift(Map<String, dynamic> gift, int userPoints) async {
    final cost = gift['points'] as int;
    if (userPoints < cost) {
      _showError('نقاطك غير كافية لشراء هذه الهدية!');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الشراء والإرسال', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        content: Text(
          'هل ترغب في شراء وإرسال ${gift['emoji']} ${gift['name']} إلى ${widget.recipientName} مقابل $cost نقطة؟',
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('شراء وإرسال', style: TextStyle(fontFamily: 'Cairo', color: Colors.amber, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await _dbService.buyAndSendGift(
        widget.senderId,
        widget.recipientId,
        widget.roomId,
        gift['id'] as String,
        gift['name'] as String,
        gift['emoji'] as String,
        cost,
      );
      _showSuccess('تم إرسال الهدية بنجاح! 🎁✈️');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _handleSendOwnedGift(Map<String, dynamic> gift) async {
    final count = gift['count'] as int;
    if (count <= 0) {
      _showError('ليس لديك نسخ كافية من هذه الهدية لإرسالها!');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد إرسال هدية مخزنة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        content: Text(
          'هل ترغب في إرسال الهدية المخزنة ${gift['emoji']} ${gift['name']} إلى ${widget.recipientName}؟ (سيتم خصم 1 من مخزونك)',
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('إرسال', style: TextStyle(fontFamily: 'Cairo', color: Colors.green, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await _dbService.sendOwnedGift(
        widget.senderId,
        widget.recipientId,
        widget.roomId,
        gift['id'] as String,
        gift['name'] as String,
        gift['emoji'] as String,
      );
      _showSuccess('تم إرسال الهدية المخزنة بنجاح! 🎁✈️');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: size.height * 0.75,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xCC0F172A) : const Color(0xE6FFFFFF),
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                  width: 1.5,
                ),
              ),
            ),
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(widget.senderId).snapshots(),
              builder: (context, userSnapshot) {
                int userPoints = 0;
                if (userSnapshot.hasData && userSnapshot.data!.exists) {
                  final data = userSnapshot.data!.data() as Map<String, dynamic>?;
                  if (data != null && data['buddyPoints'] is int) {
                    userPoints = data['buddyPoints'] as int;
                  }
                }

                return Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Drag indicator
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(top: 12, bottom: 8),
                            width: 48,
                            height: 5,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white30 : Colors.black26,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),

                        // Title and Points Badge
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'متجر الهدايا 🎁',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                  Text(
                                    'إرسال الهدايا إلى ${widget.recipientName}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ],
                              ),
                              // Points balance badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amber.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const Text('🪙', style: TextStyle(fontSize: 16)),
                                    const SizedBox(width: 6),
                                    Text(
                                      '$userPoints نقطة',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                        fontFamily: 'Cairo',
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Custom Tab Bar
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            labelColor: isDark ? Colors.white : Colors.black87,
                            unselectedLabelColor: Colors.grey,
                            indicatorSize: TabBarIndicatorSize.tab,
                            indicator: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.03),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 13),
                            tabs: const [
                              Tab(text: 'شراء الهدايا 🛒'),
                              Tab(text: 'هداياي المخزنة 📦'),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Tab View Content
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // Tab 1: Shop Catalog
                              GridView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 0.82,
                                ),
                                itemCount: _giftCatalog.length,
                                itemBuilder: (context, index) {
                                  final gift = _giftCatalog[index];
                                  final cost = gift['points'] as int;

                                  return GestureDetector(
                                    onTap: _isProcessing ? null : () => _handleBuyGift(gift, userPoints),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            gift['emoji'] as String,
                                            style: const TextStyle(fontSize: 32),
                                          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                                           .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 2.seconds, curve: Curves.easeInOut),
                                          const SizedBox(height: 8),
                                          Text(
                                            gift['name'] as String,
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Text('🪙', style: TextStyle(fontSize: 10)),
                                                const SizedBox(width: 3),
                                                Text(
                                                  '$cost',
                                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),

                              // Tab 2: Owned Inventory
                              StreamBuilder<List<Map<String, dynamic>>>(
                                stream: _dbService.getUserGiftsStream(widget.senderId),
                                builder: (context, giftsSnapshot) {
                                  if (giftsSnapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  }
                                  final ownedGifts = giftsSnapshot.data ?? [];
                                  if (ownedGifts.isEmpty) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Text('📦', style: TextStyle(fontSize: 48)),
                                          const SizedBox(height: 12),
                                          const Text(
                                            'لا تملك أي هدايا في مخزونك بعد!',
                                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Colors.grey),
                                          ),
                                          const SizedBox(height: 6),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 32),
                                            child: Text(
                                              'عندما يرسل لك شخص ما هدية، ستضاف إلى مخزونك الخاص هنا بحيث يمكنك إعادة إهدائها مجاناً!',
                                              style: TextStyle(fontSize: 11, color: Colors.grey[500], fontFamily: 'Cairo', height: 1.4),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  return GridView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      childAspectRatio: 0.82,
                                    ),
                                    itemCount: ownedGifts.length,
                                    itemBuilder: (context, index) {
                                      final gift = ownedGifts[index];
                                      final count = gift['count'] as int;

                                      return GestureDetector(
                                        onTap: _isProcessing ? null : () => _handleSendOwnedGift(gift),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                            borderRadius: BorderRadius.circular(24),
                                            border: Border.all(
                                              color: Colors.green.withOpacity(0.2),
                                              width: 1.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Stack(
                                            children: [
                                              Center(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      gift['emoji'] as String,
                                                      style: const TextStyle(fontSize: 32),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      gift['name'] as String,
                                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      textAlign: TextAlign.center,
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: Colors.green.withOpacity(0.15),
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: const Text(
                                                        'إرسال مجاني',
                                                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green, fontFamily: 'Cairo'),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Positioned(
                                                top: 10,
                                                right: 10,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green,
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Text(
                                                    'x$count',
                                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
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
                        ),
                      ],
                    ),

                    // Loading overlay
                    if (_isProcessing)
                      Container(
                        color: Colors.black.withOpacity(0.3),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.amber),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
