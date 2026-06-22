import 'package:flutter/material.dart';

class ChatThemeUtils {
  static BoxDecoration getBackgroundDecoration(String theme) {
    switch (theme) {
      case 'love':
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFff9a9e), Color(0xFFfecfef)],
          ),
        );
      case 'snow':
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFe0c3fc), Color(0xFF8ec5fc)],
          ),
        );
      case 'summer':
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFf6d365), Color(0xFFfda085)],
          ),
        );
      case 'sunset':
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF512F), Color(0xFFDD2476)],
          ),
        );
      case 'forest':
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
          ),
        );
      case 'gold':
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2C220E), Color(0xFF120E05)],
          ),
        );
      case 'rain':
        return const BoxDecoration(
          color: Color(0xFF0F172A),
        );
      case 'space':
        return const BoxDecoration(
          color: Color(0xFF020617),
        );
      case 'neon':
        return const BoxDecoration(
          color: Color(0xFF070B19),
        );
      case 'fire':
        return const BoxDecoration(
          color: Color(0xFF0F0400),
        );
      case 'ocean':
        return const BoxDecoration(
          color: Color(0xFF070E1A),
        );
      case 'default':
      default:
        return const BoxDecoration(
          color: Color(0xFFF3F4F6), // Default gray background
        );
    }
  }

  static Color getMyMessageColor(String theme) {
    switch (theme) {
      case 'love':
        return const Color(0xFFff4b68); // Soft Red/Pink
      case 'snow':
        return const Color(0xFF4facfe); // Icy Blue
      case 'summer':
        return const Color(0xFFff9933); // Vibrant Orange
      case 'sunset':
        return const Color(0xFFDD2476); // Sunset Deep Pink
      case 'forest':
        return const Color(0xFF10B981); // Emerald Green
      case 'gold':
        return const Color(0xFFD4AF37); // Royal Gold Metallic
      case 'rain':
        return const Color(0xFF1E3A8A); // Deep Rain Blue
      case 'space':
        return const Color(0xFF1E1B4B); // Deep Space Indigo
      case 'neon':
        return const Color(0xFF0A0F1D); // Dark slate bubble to let neon border glow
      case 'fire':
        return const Color(0xFFEA580C); // Warm Fire Orange
      case 'ocean':
        return const Color(0xFF0284C7); // Ocean Deep Blue
      case 'default':
      default:
        return const Color(0xFF6366F1); // Default Indigo
    }
  }

  static Color getOtherMessageColor(String theme) {
    switch (theme) {
      case 'love':
      case 'snow':
      case 'summer':
        return Colors.white;
      case 'sunset':
      case 'forest':
      case 'gold':
      case 'fire':
      case 'ocean':
        return Colors.white.withOpacity(0.15); // Glassmorphism overlay for dark/gradient themes
      case 'rain':
        return Colors.white.withOpacity(0.9);
      case 'space':
        return Colors.white.withOpacity(0.9);
      case 'neon':
        return const Color(0xFF0A0F1D); // Dark slate bubble to let neon border glow
      case 'default':
      default:
        return Colors.white;
    }
  }

  static Color getTextColor(String theme, bool isMe) {
    if (isMe) {
      return Colors.white;
    } else {
      // If other person's bubble is light/white, use dark text for legibility
      if (theme == 'love' ||
          theme == 'snow' ||
          theme == 'summer' ||
          theme == 'rain' ||
          theme == 'space' ||
          theme == 'default') {
        return const Color(0xFF0F172A); // Elegant dark slate
      } else {
        return Colors.white; // For dark/glassmorphic bubbles (sunset, forest, gold, fire, ocean, neon)
      }
    }
  }
}

