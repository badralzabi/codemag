import 'package:shared_preferences/shared_preferences.dart';

class BuddyPreferences {
  static const String _kEnabledKey = 'buddy_enabled';
  static const String _kCharacterKey = 'buddy_character';
  static const String _kSoundKey = 'buddy_sound';

  // Available Characters
  static const List<Map<String, String>> characters = [
    {'emoji': '⭐', 'name': 'لـمـعـة (Luma)', 'id': 'sparky', 'svg': 'assets/Buddy/Spark.svg'},
    {'emoji': '🐱', 'name': 'قـطـقـوطـة (Mimi)', 'id': 'cat', 'svg': 'assets/Buddy/Cat.svg'},
    {'emoji': '🐰', 'name': 'أرنـوبـة (Bunny)', 'id': 'rabbit', 'svg': 'assets/Buddy/Rabbit.svg'},
  ];

  // Available Sounds
  static const List<Map<String, String>> sounds = [
    {'id': 'pop', 'name': 'فقاعة مبهجة 🎈'},
    {'id': 'chime', 'name': 'رنين سحري 🔔'},
    {'id': 'jump', 'name': 'قفزة كرتونية 🚀'},
  ];

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kEnabledKey) ?? true;
  }

  static Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabledKey, value);
  }

  static Future<String> getCharacter() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kCharacterKey) ?? '⭐';
  }

  static Future<void> setCharacter(String emoji) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCharacterKey, emoji);
  }

  static Future<String> getSound() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kSoundKey) ?? 'pop';
  }

  static Future<void> setSound(String soundId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSoundKey, soundId);
  }

  /// Get SVG asset path for the given character emoji
  static String getSvgPath(String emoji) {
    final char = characters.firstWhere(
      (c) => c['emoji'] == emoji,
      orElse: () => characters.first,
    );
    return char['svg'] ?? 'assets/Buddy/Spark.svg';
  }
}
