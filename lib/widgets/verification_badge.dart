import 'package:flutter/material.dart';
import '../models/user_model.dart';

class VerificationBadge extends StatelessWidget {
  final UserModel user;
  final double size;

  const VerificationBadge({
    super.key,
    required this.user,
    this.size = 18,
  });

  @override
  Widget build(BuildContext context) {
    if (user.equippedVerification == 'blue_badge' || user.isVerified) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Icon(Icons.verified, color: Colors.blue, size: size),
      );
    } else if (user.equippedVerification == 'purple_badge') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Icon(Icons.verified, color: Colors.purple, size: size),
      );
    } else if (user.equippedVerification == 'green_badge') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Icon(Icons.verified, color: Colors.green, size: size),
      );
    } else if (user.equippedVerification == 'gray_badge') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Icon(Icons.verified, color: Colors.grey, size: size),
      );
    }
    return const SizedBox.shrink();
  }
}
