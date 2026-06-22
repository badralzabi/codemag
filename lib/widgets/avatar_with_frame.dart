import 'package:flutter/material.dart';

class AvatarWithFrame extends StatelessWidget {
  final String? avatarUrl;
  final double radius;
  final String? frameId;
  final VoidCallback? onTap;

  const AvatarWithFrame({
    super.key,
    required this.avatarUrl,
    this.radius = 40,
    this.frameId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey.shade200,
      backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
          ? NetworkImage(avatarUrl!)
          : null,
      child: avatarUrl == null || avatarUrl!.isEmpty
          ? Icon(Icons.person, size: radius, color: Colors.grey)
          : null,
    );

    if (onTap != null) {
      avatar = GestureDetector(onTap: onTap, child: avatar);
    }

    if (frameId == null || frameId == 'none' || frameId!.isEmpty) {
      return avatar;
    }

    // Determine frame styles based on frameId
    Widget frameWidget;
    switch (frameId) {
      case 'neon_ring':
        frameWidget = Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF00F0FF), width: 3),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00F0FF).withOpacity(0.6),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: avatar,
        );
        break;
      case 'golden_crown':
        frameWidget = Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFBBF24), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFBBF24).withOpacity(0.4),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: avatar,
            ),
            Positioned(
              top: -radius * 0.45,
              child: Text(
                '👑',
                style: TextStyle(fontSize: radius * 0.7),
              ),
            ),
          ],
        );
        break;
      case 'golden_aura':
        frameWidget = Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFF59E0B), width: 3),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withOpacity(0.6),
                blurRadius: 12,
                spreadRadius: 3,
              ),
            ],
          ),
          child: avatar,
        );
        break;
      case 'fire_flame':
        frameWidget = Container(
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: [Colors.red, Colors.orange, Colors.red],
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black, // Inner gap for dark premium styling
            ),
            child: avatar,
          ),
        );
        break;
      case 'rainbow_magic':
        frameWidget = Container(
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: [Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.blue, Colors.purple, Colors.red],
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black,
            ),
            child: avatar,
          ),
        );
        break;
      default:
        frameWidget = avatar;
    }

    return frameWidget;
  }
}
