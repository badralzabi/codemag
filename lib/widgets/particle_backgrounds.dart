import 'dart:math' as math;
import 'package:flutter/material.dart';

// ==========================================
// 1. RAIN BACKGROUND
// ==========================================

class RainBackground extends StatefulWidget {
  const RainBackground({super.key});

  @override
  State<RainBackground> createState() => _RainBackgroundState();
}

class _RainBackgroundState extends State<RainBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_Raindrop> _raindrops = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    // Initialize raindrops
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final size = MediaQuery.of(context).size;
        for (int i = 0; i < 60; i++) {
          _raindrops.add(_Raindrop(
            x: _random.nextDouble() * size.width,
            y: _random.nextDouble() * size.height,
            speed: 5.0 + _random.nextDouble() * 7.0,
            length: 15.0 + _random.nextDouble() * 15.0,
            opacity: 0.1 + _random.nextDouble() * 0.25,
          ));
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor1 = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final Color bgColor2 = isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (_raindrops.isEmpty) return const SizedBox.shrink();
        final size = MediaQuery.of(context).size;

        // Update raindrop positions
        for (var drop in _raindrops) {
          drop.y += drop.speed;
          if (drop.y > size.height) {
            drop.y = -drop.length;
            drop.x = _random.nextDouble() * size.width;
          }
        }

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [bgColor1, bgColor2],
            ),
          ),
          child: CustomPaint(
            size: Size.infinite,
            painter: _RainPainter(_raindrops, isDark),
          ),
        );
      },
    );
  }
}

class _Raindrop {
  double x;
  double y;
  double speed;
  double length;
  double opacity;

  _Raindrop({
    required this.x,
    required this.y,
    required this.speed,
    required this.length,
    required this.opacity,
  });
}

class _RainPainter extends CustomPainter {
  final List<_Raindrop> raindrops;
  final bool isDark;

  _RainPainter(this.raindrops, this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (var drop in raindrops) {
      paint.color = (isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB))
          .withOpacity(drop.opacity);
      paint.strokeWidth = drop.speed * 0.15;

      canvas.drawLine(
        Offset(drop.x, drop.y),
        Offset(drop.x - (drop.speed * 0.1), drop.y + drop.length),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ==========================================
// 2. STARRY BACKGROUND
// ==========================================

class StarryBackground extends StatefulWidget {
  const StarryBackground({super.key});

  @override
  State<StarryBackground> createState() => _StarryBackgroundState();
}

class _StarryBackgroundState extends State<StarryBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_Star> _stars = [];
  final List<_ShootingStar> _shootingStars = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final size = MediaQuery.of(context).size;
        for (int i = 0; i < 50; i++) {
          _stars.add(_Star(
            x: _random.nextDouble() * size.width,
            y: _random.nextDouble() * size.height,
            size: 1.0 + _random.nextDouble() * 2.0,
            twinkleSpeed: 0.02 + _random.nextDouble() * 0.05,
          ));
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _triggerShootingStar(Size size) {
    if (_random.nextDouble() < 0.005 && _shootingStars.length < 2) {
      _shootingStars.add(_ShootingStar(
        x: _random.nextDouble() * size.width * 0.8,
        y: _random.nextDouble() * size.height * 0.4,
        dx: 4.0 + _random.nextDouble() * 6.0,
        dy: 4.0 + _random.nextDouble() * 6.0,
        length: 60.0 + _random.nextDouble() * 60.0,
        opacity: 0.8,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor1 = isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0);
    final Color bgColor2 = isDark ? const Color(0xFF020617) : const Color(0xFFCBD5E1);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (_stars.isEmpty) return const SizedBox.shrink();
        final size = MediaQuery.of(context).size;

        // Update stars
        for (var star in _stars) {
          star.opacity += star.direction * star.twinkleSpeed;
          if (star.opacity >= 0.9) {
            star.direction = -1;
          } else if (star.opacity <= 0.1) {
            star.direction = 1;
          }
        }

        // Spawn/Update shooting stars
        _triggerShootingStar(size);
        for (int i = _shootingStars.length - 1; i >= 0; i--) {
          final comet = _shootingStars[i];
          comet.x += comet.dx;
          comet.y += comet.dy;
          comet.opacity -= 0.02;
          if (comet.opacity <= 0 || comet.x > size.width || comet.y > size.height) {
            _shootingStars.removeAt(i);
          }
        }

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [bgColor1, bgColor2],
            ),
          ),
          child: CustomPaint(
            size: Size.infinite,
            painter: _StarryPainter(_stars, _shootingStars, isDark),
          ),
        );
      },
    );
  }
}

class _Star {
  double x;
  double y;
  double size;
  double opacity = 0.5;
  int direction = 1;
  double twinkleSpeed;

  _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.twinkleSpeed,
  });
}

class _ShootingStar {
  double x;
  double y;
  double dx;
  double dy;
  double length;
  double opacity;

  _ShootingStar({
    required this.x,
    required this.y,
    required this.dx,
    required this.dy,
    required this.length,
    required this.opacity,
  });
}

class _StarryPainter extends CustomPainter {
  final List<_Star> stars;
  final List<_ShootingStar> shootingStars;
  final bool isDark;

  _StarryPainter(this.stars, this.shootingStars, this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final starPaint = Paint()..style = PaintingStyle.fill;
    final starColor = isDark ? Colors.white : const Color(0xFF475569);

    // Draw normal stars
    for (var star in stars) {
      starPaint.color = starColor.withOpacity(star.opacity);
      canvas.drawCircle(Offset(star.x, star.y), star.size, starPaint);
    }

    // Draw shooting stars
    for (var comet in shootingStars) {
      if (comet.opacity <= 0) continue;
      final cometPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment(comet.dx > 0 ? -1.0 : 1.0, -1.0),
          end: const Alignment(0, 0),
          colors: [
            (isDark ? Colors.white : const Color(0xFF6366F1)).withOpacity(0.0),
            (isDark ? const Color(0xFF38BDF8) : const Color(0xFF4F46E5)).withOpacity(comet.opacity),
          ],
        ).createShader(Rect.fromLTWH(comet.x - comet.length, comet.y - comet.length, comet.length * 2, comet.length * 2))
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      cometPaint.strokeWidth = 2.5;

      canvas.drawLine(
        Offset(comet.x, comet.y),
        Offset(comet.x - comet.length * 0.7, comet.y - comet.length * 0.7),
        cometPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ==========================================
// 3. NEON GLOW BACKGROUND
// ==========================================

class NeonGlowBackground extends StatefulWidget {
  const NeonGlowBackground({super.key});

  @override
  State<NeonGlowBackground> createState() => _NeonGlowBackgroundState();
}

class _NeonGlowBackgroundState extends State<NeonGlowBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _time = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )
      ..addListener(() {
        setState(() {
          _time = _controller.value * 2 * math.pi;
        });
      })
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF070B19), // Ultra deep space black-blue
      child: CustomPaint(
        size: Size.infinite,
        painter: _NeonPainter(_time),
      ),
    );
  }
}

class _NeonPainter extends CustomPainter {
  final double time;

  _NeonPainter(this.time);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Orb 1: Neon Pink moving slowly in a circular path
    final Offset orb1 = Offset(
      w * 0.3 + math.sin(time) * (w * 0.15),
      h * 0.4 + math.cos(time) * (h * 0.12),
    );
    _drawGlowingOrb(canvas, orb1, w * 0.45, const Color(0xFFFF007F).withOpacity(0.18));

    // Orb 2: Neon Cyan moving in a figure-eight path
    final Offset orb2 = Offset(
      w * 0.7 + math.sin(time * 2) * (w * 0.12),
      h * 0.6 + math.cos(time) * (h * 0.15),
    );
    _drawGlowingOrb(canvas, orb2, w * 0.50, const Color(0xFF00F0FF).withOpacity(0.15));

    // Orb 3: Soft violet deep glow shifting
    final Offset orb3 = Offset(
      w * 0.5 + math.cos(time * 0.5) * (w * 0.20),
      h * 0.2 + math.sin(time * 0.7) * (h * 0.10),
    );
    _drawGlowingOrb(canvas, orb3, w * 0.60, const Color(0xFF8B5CF6).withOpacity(0.12));
  }

  void _drawGlowingOrb(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withOpacity(0.0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _NeonPainter oldDelegate) => oldDelegate.time != time;
}

// ==========================================
// 4. FIRE BACKGROUND
// ==========================================

class FireBackground extends StatefulWidget {
  const FireBackground({super.key});

  @override
  State<FireBackground> createState() => _FireBackgroundState();
}

class _FireBackgroundState extends State<FireBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_Ember> _embers = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final size = MediaQuery.of(context).size;
        for (int i = 0; i < 40; i++) {
          _embers.add(_Ember(
            x: _random.nextDouble() * size.width,
            y: _random.nextDouble() * size.height,
            speed: 1.0 + _random.nextDouble() * 2.0,
            radius: 2.0 + _random.nextDouble() * 4.0,
            opacity: 0.2 + _random.nextDouble() * 0.6,
          ));
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (_embers.isEmpty) return const SizedBox.shrink();
        final size = MediaQuery.of(context).size;

        for (var ember in _embers) {
          ember.y -= ember.speed; // rise up
          ember.x += math.sin(ember.y / 20.0) * 0.5; // sway slightly
          if (ember.y < -ember.radius * 2) {
            ember.y = size.height + ember.radius * 2;
            ember.x = _random.nextDouble() * size.width;
          }
        }

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF180800), Color(0xFF000000)],
            ),
          ),
          child: CustomPaint(
            size: Size.infinite,
            painter: _FirePainter(_embers),
          ),
        );
      },
    );
  }
}

class _Ember {
  double x;
  double y;
  double speed;
  double radius;
  double opacity;

  _Ember({
    required this.x,
    required this.y,
    required this.speed,
    required this.radius,
    required this.opacity,
  });
}

class _FirePainter extends CustomPainter {
  final List<_Ember> embers;
  _FirePainter(this.embers);

  @override
  void paint(Canvas canvas, Size size) {
    for (var ember in embers) {
      final paint = Paint()
        ..color = const Color(0xFFFF5722).withOpacity(ember.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(ember.x, ember.y), ember.radius, paint);
      
      // core glow
      final corePaint = Paint()
        ..color = const Color(0xFFFFEB3B).withOpacity(ember.opacity * 0.8)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(ember.x, ember.y), ember.radius * 0.5, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ==========================================
// 5. OCEAN BACKGROUND
// ==========================================

class OceanBackground extends StatefulWidget {
  const OceanBackground({super.key});

  @override
  State<OceanBackground> createState() => _OceanBackgroundState();
}

class _OceanBackgroundState extends State<OceanBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _time = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )
      ..addListener(() {
        setState(() {
          _time = _controller.value * 2 * math.pi;
        });
      })
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0F172A), Color(0xFF070B19)],
        ),
      ),
      child: CustomPaint(
        size: Size.infinite,
        painter: _OceanPainter(_time),
      ),
    );
  }
}

class _OceanPainter extends CustomPainter {
  final double time;
  _OceanPainter(this.time);

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;

    // Draw 3 layers of waves
    _drawWave(canvas, size, time, h * 0.80, const Color(0x3300C6FF), 25, 0.005);
    _drawWave(canvas, size, time + 2, h * 0.85, const Color(0x440072FF), 20, 0.006);
    _drawWave(canvas, size, time + 4, h * 0.90, const Color(0x550A1128), 15, 0.007);
  }

  void _drawWave(Canvas canvas, Size size, double waveTime, double baseHeight, Color color, double amplitude, double frequency) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, baseHeight);

    for (double x = 0; x <= size.width; x++) {
      final y = baseHeight + math.sin(x * frequency + waveTime) * amplitude;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _OceanPainter oldDelegate) => oldDelegate.time != time;
}
