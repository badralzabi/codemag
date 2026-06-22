import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class ARGiftScreen extends StatelessWidget {
  final String giftName;
  final String glbUrl;

  const ARGiftScreen({
    super.key,
    required this.giftName,
    required this.glbUrl,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text(
          'هدية: $giftName 🎁',
          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      body: Stack(
        children: [
          // 3D Model Viewer with AR enabled
          Positioned.fill(
            child: ModelViewer(
              backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
              src: glbUrl,
              alt: "A 3D model of an AR gift",
              ar: true,
              arModes: const ['scene-viewer', 'webxr', 'quick-look'],
              autoRotate: true,
              disableZoom: false,
              cameraControls: true,
            ),
          ),
          
          // Instruction Overlay
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.view_in_ar, color: Colors.white, size: 32),
                  SizedBox(height: 8),
                  Text(
                    'تفاعل مع الهدية بلمسها، واضغط على زر الواقع المعزز (AR) في الزاوية لرؤيتها في غرفتك!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
