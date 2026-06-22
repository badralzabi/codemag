import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/db_service.dart';

class LuckyWheelDialog extends StatefulWidget {
  final String userId;

  const LuckyWheelDialog({super.key, required this.userId});

  static void show(BuildContext context, String userId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => LuckyWheelDialog(userId: userId),
    );
  }

  @override
  State<LuckyWheelDialog> createState() => _LuckyWheelDialogState();
}

class _LuckyWheelDialogState extends State<LuckyWheelDialog> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  late Animation<double> _animation;
  final DatabaseService _dbService = DatabaseService();

  bool _isSpinning = false;
  bool _hasSpun = false;
  int _winningIndex = -1;
  double _wheelRotation = 0.0;

  // Curated premium HSL-tailored color palette
  final List<Map<String, dynamic>> _slices = [
    {
      'label': 'حظ أوفر ❌',
      'points': 0,
      'color': const Color(0xFF334155), // Sleek slate gray
      'textColor': Colors.white70,
    },
    {
      'label': '5 🪙',
      'points': 5,
      'color': const Color(0xFF6366F1), // Royal Indigo
      'textColor': Colors.white,
    },
    {
      'label': '10 🪙',
      'points': 10,
      'color': const Color(0xFF3B82F6), // Electric Blue
      'textColor': Colors.white,
    },
    {
      'label': '20 🪙',
      'points': 20,
      'color': const Color(0xFF10B981), // Emerald Neon
      'textColor': Colors.white,
    },
    {
      'label': '50 🪙',
      'points': 50,
      'color': const Color(0xFF8B5CF6), // Deep Violet
      'textColor': Colors.white,
    },
    {
      'label': '100 🪙',
      'points': 100,
      'color': const Color(0xFFEC4899), // Hot Pink
      'textColor': Colors.white,
    },
    {
      'label': '500 🪙',
      'points': 500,
      'color': const Color(0xFF06B6D4), // Cyan Neon
      'textColor': Colors.white,
    },
    {
      'label': '1000 🪙',
      'points': 1000,
      'color': const Color(0xFFF59E0B), // Glowing Gold
      'textColor': Colors.white,
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _animation.addListener(() {
      setState(() {
        _wheelRotation = _animation.value;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _spinWheel() async {
    if (_isSpinning) return;

    // Determine slice outcome based on weighted probabilities
    final rand = Random().nextDouble();
    int targetIndex = 0;

    if (rand < 0.30) {
      targetIndex = 0; // Try Again (30%)
    } else if (rand < 0.55) {
      targetIndex = 1; // 5 points (25%)
    } else if (rand < 0.75) {
      targetIndex = 2; // 10 points (20%)
    } else if (rand < 0.87) {
      targetIndex = 3; // 20 points (12%)
    } else if (rand < 0.95) {
      targetIndex = 4; // 50 points (8%)
    } else if (rand < 0.995) {
      targetIndex = 5; // 100 points (4.5%)
    } else if (rand < 0.999) {
      targetIndex = 6; // 500 points (0.4%)
    } else {
      targetIndex = 7; // 1000 points (0.1%)
    }

    setState(() {
      _isSpinning = true;
      _winningIndex = targetIndex;
    });

    const sliceAngle = 2 * pi / 8;
    const fullSpins = 6;
    
    // Target angle points the selected slice to the indicator at the top (-pi/2)
    final targetAngle = (fullSpins * 2 * pi) + (1.5 * pi - (targetIndex * sliceAngle + sliceAngle / 2));

    _animation = Tween<double>(
      begin: 0.0,
      end: targetAngle,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuart,
    ));

    _controller.reset();
    await _controller.forward();

    final winner = _slices[targetIndex];
    final points = winner['points'] as int;

    try {
      await _dbService.awardWheelPoints(widget.userId, points);
    } catch (e) {
      debugPrint('Error updating wheel points: $e');
    }

    if (mounted) {
      setState(() {
        _isSpinning = false;
        _hasSpun = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final winner = _winningIndex != -1 ? _slices[_winningIndex] : null;
    final pointsWon = winner != null ? winner['points'] as int : 0;

    // Calculate physical pin wiggle animation based on wheel rotation
    const sliceAngle = 2 * pi / 8;
    final relativePos = _wheelRotation % sliceAngle;
    double pinRotation = 0.0;
    
    // Push the pin in direction of spin as a peg/divider passes, then snap back
    if (relativePos < 0.12) {
      pinRotation = -(0.12 - relativePos) * 1.5; 
    } else if (relativePos > sliceAngle - 0.12) {
      pinRotation = (relativePos - (sliceAngle - 0.12)) * 1.5;
    }

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xCC0F172A) : const Color(0xCCFFFFFF),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? const Color(0xFF6366F1) : Colors.amber).withOpacity(0.15),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFFEC4899), Color(0xFFF59E0B)],
                  ).createShader(bounds),
                  child: const Text(
                    'عجلة الحظ اليومية 🎡',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'أدر العجلة الآن واحصل على فرصة لربح نقاط إضافية تصل إلى 1000 نقطة!',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Cairo',
                    color: isDark ? Colors.white70 : Colors.black54,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Wheel Stack Container
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer glowing shadow ring
                    Container(
                      width: 252,
                      height: 252,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(_isSpinning ? 0.35 : 0.15),
                            blurRadius: _isSpinning ? 24 : 12,
                            spreadRadius: _isSpinning ? 4 : 1,
                          ),
                        ],
                      ),
                    ),
                    
                    // The wheel itself
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Transform.rotate(
                        angle: _wheelRotation,
                        child: Container(
                          width: 240,
                          height: 240,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF1E293B), width: 6),
                          ),
                          child: CustomPaint(
                            painter: WheelPainter(
                              slices: _slices, 
                              rotationValue: _wheelRotation,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Center spin button (pulsates when idle)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.96, end: 1.04).animate(
                          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
                        ),
                        child: GestureDetector(
                          onTap: _isSpinning || _hasSpun ? null : _spinWheel,
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              gradient: _isSpinning || _hasSpun
                                  ? LinearGradient(
                                      colors: [Colors.grey.shade700, Colors.grey.shade800],
                                    )
                                  : const LinearGradient(
                                      colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _isSpinning || _hasSpun ? Colors.grey.shade600 : Colors.white,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (_isSpinning || _hasSpun ? Colors.black : const Color(0xFF6366F1))
                                      .withOpacity(0.4),
                                  blurRadius: 12,
                                  spreadRadius: _isSpinning || _hasSpun ? 0 : 2,
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'أدر ⚡',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.4),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Indicator Pin at top (Wiggles dynamically)
                    Positioned(
                      top: 0,
                      child: Transform.rotate(
                        angle: pinRotation,
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: 20,
                          height: 32,
                          child: CustomPaint(
                            painter: PinPainter(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                
                // Result Panel
                if (_hasSpun) ...[
                  if (pointsWon > 0) ...[
                    Text(
                      '🎉 مبروك! 🎉',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                        fontFamily: 'Cairo',
                      ),
                    ).animate().scale(duration: 400.ms, curve: Curves.bounceOut),
                    const SizedBox(height: 4),
                    Text(
                      'ربحت $pointsWon نقطة بنجاح!',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                        fontFamily: 'Cairo',
                      ),
                    ).animate().fadeIn(delay: 150.ms),
                  ] else ...[
                    Text(
                      'حظ أوفر المرة القادمة! 😔',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF87171),
                        fontFamily: 'Cairo',
                      ),
                    ).animate().shake(duration: 500.ms),
                  ],
                  const SizedBox(height: 20),
                  
                  // Premium Gradient Close Button
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Container(
                        height: 48,
                        alignment: Alignment.center,
                        child: const Text(
                          'إغلاق',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Text(
                    _isSpinning ? 'جاري تدوير العجلة... 🤞' : 'اضغط على زر المنتصف لبدء التدوير!',
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'Cairo',
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WheelPainter extends CustomPainter {
  final List<Map<String, dynamic>> slices;
  final double rotationValue;

  WheelPainter({required this.slices, required this.rotationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    const sliceAngle = 2 * pi / 8;

    for (int i = 0; i < 8; i++) {
      // Create radial depth shader for each slice
      final baseColor = slices[i]['color'] as Color;
      final slicePaint = Paint()
        ..shader = RadialGradient(
          colors: [
            baseColor.withOpacity(0.75),
            baseColor,
          ],
          stops: const [0.35, 1.0],
        ).createShader(rect)
        ..style = PaintingStyle.fill;

      // Draw segment
      canvas.drawArc(rect, i * sliceAngle, sliceAngle, true, slicePaint);

      // Draw shiny dividing line
      final linePaint = Paint()
        ..color = Colors.white.withOpacity(0.15)
        ..strokeWidth = 2.0;
      final x = center.dx + radius * cos(i * sliceAngle);
      final y = center.dy + radius * sin(i * sliceAngle);
      canvas.drawLine(center, Offset(x, y), linePaint);

      // Draw text/emoji labels
      final textSpan = TextSpan(
        text: slices[i]['label'],
        style: TextStyle(
          color: slices[i]['textColor'] ?? Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          fontFamily: 'Cairo',
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.rtl,
      );
      textPainter.layout();

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(i * sliceAngle + sliceAngle / 2);
      
      // Paint labels midway to the edge
      textPainter.paint(
        canvas,
        Offset(radius * 0.48, -textPainter.height / 2),
      );
      canvas.restore();
    }

    // Draw 3D glossy gradient glass-dome overlay
    final overlayPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.2),
          Colors.transparent,
          Colors.black.withOpacity(0.4),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, overlayPaint);

    // Draw center dark core (behaves as structural base for center button)
    final corePaint = Paint()
      ..color = const Color(0xFF0F172A).withOpacity(0.85)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 38, corePaint);

    final coreBorderPaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, 38, coreBorderPaint);

    // Draw metallic gold outer ring accent
    final goldAccent = Paint()
      ..color = const Color(0xFFF59E0B).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius - 4, goldAccent);

    // Draw blinking LED lights around the rim (animated via rotationValue)
    const numLights = 24;
    for (int i = 0; i < numLights; i++) {
      final angle = i * (2 * pi / numLights);
      final bulbX = center.dx + (radius - 4) * cos(angle);
      final bulbY = center.dy + (radius - 4) * sin(angle);
      
      // Blinking pattern driven by rotation value
      final isLit = ((i + (rotationValue * 8).toInt()) % 3) == 0;
      
      final bulbColor = isLit ? const Color(0xFFFBBF24) : const Color(0xFF78350F);
      
      if (isLit) {
        // Draw soft bulb glow
        canvas.drawCircle(
          Offset(bulbX, bulbY), 
          4.5, 
          Paint()
            ..color = const Color(0xFFFBBF24).withOpacity(0.6)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
        );
      }
      canvas.drawCircle(
        Offset(bulbX, bulbY), 
        2.5, 
        Paint()..color = bulbColor..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant WheelPainter oldDelegate) => 
      oldDelegate.rotationValue != rotationValue;
}

class PinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Shadow Path
    final shadowPath = Path();
    shadowPath.moveTo(size.width / 2 - 2, 2);
    shadowPath.lineTo(size.width, size.height * 0.8);
    shadowPath.lineTo(size.width / 2, size.height);
    shadowPath.lineTo(0, size.height * 0.8);
    shadowPath.close();
    
    canvas.drawPath(
      shadowPath, 
      Paint()
        ..color = Colors.black.withOpacity(0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Main pointer body
    final path = Path();
    path.moveTo(size.width / 2, 0); 
    path.lineTo(size.width, size.height * 0.8); 
    path.lineTo(size.width / 2, size.height); 
    path.lineTo(0, size.height * 0.8); 
    path.close();

    // Golden metallic gradient
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFBBF24), Color(0xFFF59E0B), Color(0xFFD97706)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);

    // Inner glowing core
    final innerPath = Path();
    innerPath.moveTo(size.width / 2, 4);
    innerPath.lineTo(size.width - 3, size.height * 0.75);
    innerPath.lineTo(size.width / 2, size.height - 4);
    innerPath.lineTo(3, size.height * 0.75);
    innerPath.close();

    final innerPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFEF4444), Color(0xFFF43F5E)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(innerPath, innerPaint);

    // Metallic pivot cap at top
    canvas.drawCircle(
      Offset(size.width / 2, 5),
      4.5,
      Paint()
        ..shader = const LinearGradient(
          colors: [Colors.white, Colors.grey],
        ).createShader(Rect.fromLTWH(size.width / 2 - 4.5, 0, 9, 9))
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
