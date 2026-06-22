import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/db_service.dart';
import '../../services/cloudinary_service.dart';
import '../profile/buddy_store_screen.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _contentController = TextEditingController();
  final _dbService = DatabaseService();
  bool _isLoading = false;
  XFile? _pickedImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _pickedImage = pickedFile;
      });
    }
  }

  void _submit() async {
    final content = _contentController.text.trim();
    if (content.isEmpty && _pickedImage == null) return;

    setState(() => _isLoading = true);
    final user = Provider.of<User?>(context, listen: false);

    try {
      String? imageUrl;
      if (_pickedImage != null) {
        imageUrl = await CloudinaryService.uploadImage(_pickedImage!);
      }

      final bool isFirstPost = await _dbService.createPost(user!.uid, content, imageUrl: imageUrl);
      if (mounted) {
        final navigator = Navigator.of(context);
        navigator.pop(); // Pop the creation screen first

        if (isFirstPost) {
          // Congratulate user for their first post with premium modal/alert
          showDialog(
            context: navigator.context,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text(
                'تهانينا! 🎉',
                style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'لقد قمت بنشر أول منشور لك بنجاح! 🚀',
                    style: TextStyle(color: Colors.grey, fontFamily: 'Cairo', fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'تمت إضافة +50 نقطة Buddy لحسابك مكافأة تشجيعية لك!',
                    style: TextStyle(color: Color(0xFF6366F1), fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      navigator.push(
                        MaterialPageRoute(builder: (_) => const BuddyStoreScreen()),
                      );
                    },
                    child: const Text('انتقل للمتجر 🛒', style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(navigator.context).showSnackBar(
            const SnackBar(
              content: Text('تم نشر فكرتك بنجاح! (+10 نقاط Buddy)', style: TextStyle(fontFamily: 'Cairo')),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('نشر فكرة جديدة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              onPressed: _isLoading ? null : _submit,
              child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                : const Text('نشر', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _contentController,
                  maxLines: null,
                  autofocus: true,
                  style: const TextStyle(fontSize: 20, color: Color(0xFF1E293B), height: 1.5),
                  decoration: const InputDecoration(
                    hintText: 'ماذا يدور في ذهنك اليوم؟',
                    hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 24, fontWeight: FontWeight.w300),
                    border: InputBorder.none,
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms),
              if (_pickedImage != null)
                Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(
                          image: FileImage(File(_pickedImage!.path)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 24,
                      right: 8,
                      child: InkWell(
                        onTap: () => setState(() => _pickedImage = null),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ).animate().scale(duration: 300.ms),
              const Divider(color: Color(0xFFF1F5F9)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.image_outlined, color: Color(0xFF6366F1)),
                    onPressed: _pickImage,
                  ),
                  IconButton(
                    icon: const Icon(Icons.location_on_outlined, color: Color(0xFF6366F1)),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.emoji_emotions_outlined, color: Color(0xFF6366F1)),
                    onPressed: () {},
                  ),
                ],
              ).animate().slideY(begin: 1, end: 0, duration: 300.ms),
            ],
          ),
        ),
      ),
    );
  }
}
