import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/db_service.dart';
import '../../services/cloudinary_service.dart';
import '../profile/buddy_store_screen.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final _contentController = TextEditingController();
  int _colorIndex = 0;
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

  final List<List<Color>> _gradients = [
    [const Color(0xFF6366F1), const Color(0xFF8B5CF6)], // Indigo to Purple
    [const Color(0xFFF43F5E), const Color(0xFFFB923C)], // Rose to Orange
    [const Color(0xFF10B981), const Color(0xFF3B82F6)], // Emerald to Blue
    [const Color(0xFF1E293B), const Color(0xFF0F172A)], // Dark Slate
    [const Color(0xFFD946EF), const Color(0xFF8B5CF6)], // Fuchsia to Purple
  ];

  void _postStory() async {
    final text = _contentController.text.trim();
    if (text.isEmpty && _pickedImage == null) return;

    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        String? imageUrl;
        if (_pickedImage != null) {
          imageUrl = await CloudinaryService.uploadImage(_pickedImage!);
        }

        final bool isFirstStory = await DatabaseService().createStory(uid, text, _colorIndex, imageUrl: imageUrl);
        if (mounted) {
          final navigator = Navigator.of(context);
          navigator.pop(); // Pop the creation screen first

          if (isFirstStory) {
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
                      'لقد قمت بنشر أول قصة لك بنجاح! 📸',
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
                content: Text('تم نشر القصة بنجاح! (+20 نقطة Buddy)', style: TextStyle(fontFamily: 'Cairo')),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.image, color: Colors.white),
            onPressed: _pickImage,
          ),
          IconButton(
            icon: const Icon(Icons.color_lens, color: Colors.white),
            onPressed: () {
              setState(() {
                _colorIndex = (_colorIndex + 1) % _gradients.length;
              });
            },
          ),
          TextButton(
            onPressed: _isLoading ? null : _postStory,
            child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('نشر', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: _pickedImage != null 
              ? DecorationImage(image: FileImage(File(_pickedImage!.path)), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken))
              : null,
          gradient: _pickedImage == null ? LinearGradient(
            colors: _gradients[_colorIndex],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ) : null,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: TextField(
              controller: _contentController,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              maxLines: null,
              maxLength: 150,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'اكتب قصتك...',
                hintStyle: TextStyle(color: Colors.white70),
                counterStyle: TextStyle(color: Colors.white70),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
