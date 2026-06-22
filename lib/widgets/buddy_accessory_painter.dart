import 'dart:math' as math;
import 'package:flutter/material.dart';

class BuddyAccessory {
  final String id;
  final String name;
  final String desc;
  final int price;
  final String emoji;
  final String anchorType; // 'hat', 'eye', 'neck', 'hand_left', 'hand_right', 'back'

  const BuddyAccessory({
    required this.id,
    required this.name,
    required this.desc,
    required this.price,
    required this.emoji,
    required this.anchorType,
  });

  static const List<BuddyAccessory> allAccessories = [
    BuddyAccessory(
      id: 'glasses',
      name: 'نظارات شمسية كول',
      desc: 'نظارات سوداء تمنح رفيقك هيبة!',
      price: 50,
      emoji: '😎',
      anchorType: 'eye',
    ),
    BuddyAccessory(
      id: 'bowtie',
      name: 'ربطة عنق فاخرة',
      desc: 'ربطة عنق بلون بنفسجي ملكي مبهج.',
      price: 80,
      emoji: '🎀',
      anchorType: 'neck',
    ),
    BuddyAccessory(
      id: 'party_hat',
      name: 'قبعة حفلات مبهجة',
      desc: 'قبعة ملونة لاحتفالات رفيقك المستمرة!',
      price: 120,
      emoji: '🥳',
      anchorType: 'hat',
    ),
    BuddyAccessory(
      id: 'scarf',
      name: 'وشاح شتوي دافئ',
      desc: 'وشاح أخضر دافئ مطرز بالخيوط الذهبية.',
      price: 150,
      emoji: '🧣',
      anchorType: 'neck',
    ),
    BuddyAccessory(
      id: 'crown',
      name: 'تاج ملكي ذهبي',
      desc: 'تاج مرصع بالجواهر يمنح رفيقك هيبة الملوك!',
      price: 250,
      emoji: '👑',
      anchorType: 'hat',
    ),
    BuddyAccessory(
      id: 'chef_hat',
      name: 'قبعة طاهي محترف',
      desc: 'لرفيق يحب الطبخ وإعداد الوصفات اللذيذة!',
      price: 180,
      emoji: '👨‍🍳',
      anchorType: 'hat',
    ),
    BuddyAccessory(
      id: 'mustache',
      name: 'شارب كلاسيكي',
      desc: 'شارب أنيق يضفي لمسة من الوقار والمرح!',
      price: 100,
      emoji: '👨',
      anchorType: 'eye',
    ),
    BuddyAccessory(
      id: 'heart_glasses',
      name: 'نظارات قلوب الحب',
      desc: 'نظارات حمراء تنشر الحب في كل شات!',
      price: 160,
      emoji: '💖',
      anchorType: 'eye',
    ),
    BuddyAccessory(
      id: 'halo',
      name: 'هالة ملاك مضيئة',
      desc: 'هالة طائرة تمنح رفيقك لمسة من البراءة!',
      price: 300,
      emoji: '😇',
      anchorType: 'hat',
    ),
    BuddyAccessory(
      id: 'cowboy_hat',
      name: 'قبعة رعاة البقر',
      desc: 'قبعة راعي البقر للمغامرات البرية!',
      price: 110,
      emoji: '🤠',
      anchorType: 'hat',
    ),
    BuddyAccessory(
      id: 'wizard_hat',
      name: 'قبعة الساحر',
      desc: 'قبعة السحر والغموض المرصعة بالنجوم!',
      price: 220,
      emoji: '🧙',
      anchorType: 'hat',
    ),
    BuddyAccessory(
      id: 'top_hat',
      name: 'قبعة السير الكلاسيكية',
      desc: 'قبعة سوداء فاخرة للمناسبات الرسمية!',
      price: 140,
      emoji: '🎩',
      anchorType: 'hat',
    ),
    BuddyAccessory(
      id: 'graduation_cap',
      name: 'قبعة التخرج',
      desc: 'قبعة تخرج للاحتفال بنجاح رفيقك الدائم!',
      price: 150,
      emoji: '🎓',
      anchorType: 'hat',
    ),
    BuddyAccessory(
      id: 'detective_hat',
      name: 'قبعة المحقق',
      desc: 'قبعة المحقق الشهير لفك غموض الرسائل!',
      price: 130,
      emoji: '🕵️',
      anchorType: 'hat',
    ),
    BuddyAccessory(
      id: 'santa_hat',
      name: 'قبعة بابا نويل',
      desc: 'قبعة سانتا الحمراء الدافئة لنشر البهجة!',
      price: 90,
      emoji: '🎅',
      anchorType: 'hat',
    ),
    BuddyAccessory(
      id: 'ninja_headband',
      name: 'عصابة رأس النينجا',
      desc: 'عصابة رأس حمراء لرفيق سريع الحركة!',
      price: 175,
      emoji: '🥷',
      anchorType: 'hat',
    ),
    BuddyAccessory(
      id: 'devil_horns',
      name: 'قرون الشيطان الحمراء',
      desc: 'قرون حمراء شقية لرفيق يحب المزاح!',
      price: 190,
      emoji: '😈',
      anchorType: 'hat',
    ),
    BuddyAccessory(
      id: 'space_helmet',
      name: 'خوذة الفضاء',
      desc: 'خوذة رائد الفضاء لاستكشاف مجرات الشات!',
      price: 350,
      emoji: '👩‍🚀',
      anchorType: 'hat',
    ),
    BuddyAccessory(
      id: 'police_cap',
      name: 'قبعة الشرطة',
      desc: 'قبعة لحفظ النظام والعدالة في المحادثة!',
      price: 125,
      emoji: '👮',
      anchorType: 'hat',
    ),
    BuddyAccessory(
      id: 'bunny_ears_band',
      name: 'طوق آذان الأرنب',
      desc: 'طوق آذان الأرنب اللطيفة لرفيق محبوب!',
      price: 85,
      emoji: '🐰',
      anchorType: 'hat',
    ),
    BuddyAccessory(
      id: 'bear_ears',
      name: 'طوق آذان الدب',
      desc: 'طوق دافئ وناعم بأذني دب لطيف!',
      price: 80,
      emoji: '🐻',
      anchorType: 'hat',
    ),
    BuddyAccessory(
      id: 'flower_crown',
      name: 'طوق الورد الربيعي',
      desc: 'إكليل من زهور الربيع الملونة والجميلة!',
      price: 210,
      emoji: '🌸',
      anchorType: 'hat',
    ),
    BuddyAccessory(
      id: 'headphones',
      name: 'سماعات رأس كول',
      desc: 'سماعات رأس عازلة للاستماع للموسيقى!',
      price: 260,
      emoji: '🎧',
      anchorType: 'hat',
    ),
    BuddyAccessory(
      id: 'propeller_hat',
      name: 'قبعة المروحة الطائرة',
      desc: 'قبعة مرحة بمروحة تدور في الأعلى!',
      price: 165,
      emoji: '🚁',
      anchorType: 'hat',
    ),
    BuddyAccessory(
      id: 'straw_hat',
      name: 'قبعة القش الصيفية',
      desc: 'قبعة شمسية خفيفة مناسبة لرحلات الصيف!',
      price: 70,
      emoji: '👒',
      anchorType: 'hat',
    ),
    BuddyAccessory(
      id: 'birthday_crown',
      name: 'تاج الحفلات البراق',
      desc: 'تاج ذهبي لامع للاحتفال بأعياد الميلاد!',
      price: 100,
      emoji: '🎉',
      anchorType: 'hat',
    ),
    BuddyAccessory(
      id: 'pixel_glasses',
      name: 'نظارات بكسل Thug',
      desc: 'نظارات البكسل السوداء الشهيرة للحظات القوية!',
      price: 180,
      emoji: '🕶️',
      anchorType: 'eye',
    ),
    BuddyAccessory(
      id: 'gold_glasses',
      name: 'نظارات ذهبية فاخرة',
      desc: 'نظارات طبية بإطار ذهبي كلاسيكي!',
      price: 300,
      emoji: '👓',
      anchorType: 'eye',
    ),
    BuddyAccessory(
      id: 'eye_patch',
      name: 'رقعة القراصنة',
      desc: 'رقعة عين سوداء لرفيق يبحر في الشات!',
      price: 110,
      emoji: '🏴‍☠️',
      anchorType: 'eye',
    ),
    BuddyAccessory(
      id: 'monocle',
      name: 'نظارة العين الواحدة',
      desc: 'نظارة مفردة فاخرة تعكس الذكاء والوقار!',
      price: 150,
      emoji: '🧐',
      anchorType: 'eye',
    ),
    BuddyAccessory(
      id: 'clown_nose',
      name: 'أنف المهرج الأحمر',
      desc: 'أنف مهرج مضحك لنشر الضحك والمرح!',
      price: 60,
      emoji: '🔴',
      anchorType: 'eye',
    ),
    BuddyAccessory(
      id: 'blush',
      name: 'خدود حمراء خجولة',
      desc: 'أحمر خدود لطيف يظهر خجل رفيقك!',
      price: 75,
      emoji: '😊',
      anchorType: 'eye',
    ),
    BuddyAccessory(
      id: 'star_glasses',
      name: 'نظارات النجوم البراقة',
      desc: 'نظارات صفراء على شكل نجوم للحفلات!',
      price: 170,
      emoji: '⭐',
      anchorType: 'eye',
    ),
    BuddyAccessory(
      id: 'gas_mask',
      name: 'قناع الوقاية المستقبلي',
      desc: 'قناع غاز مستقبلي لرفيق غامض وحذر!',
      price: 240,
      emoji: '😷',
      anchorType: 'eye',
    ),
    BuddyAccessory(
      id: 'sleep_mask',
      name: 'قناع النوم الهادئ',
      desc: 'قناع مريح يساعد رفيقك على النوم أثناء غيابك!',
      price: 65,
      emoji: '😴',
      anchorType: 'eye',
    ),
    BuddyAccessory(
      id: 'superhero_mask',
      name: 'قناع البطل الخارق',
      desc: 'قناع أزرق يحمي الهوية السرية لرفيقك الخارق!',
      price: 195,
      emoji: '🦸',
      anchorType: 'eye',
    ),
    BuddyAccessory(
      id: 'gold_chain',
      name: 'سلسلة الذهب الضخمة',
      desc: 'سلسلة ذهبية لامعة تمنح رفيقك إطلالة راب!',
      price: 400,
      emoji: '🪙',
      anchorType: 'neck',
    ),
    BuddyAccessory(
      id: 'bell_collar',
      name: 'طوق الجرس الذهبي',
      desc: 'طوق جلدي لطيف بجرس صغير يرن في الشات!',
      price: 95,
      emoji: '🔔',
      anchorType: 'neck',
    ),
    BuddyAccessory(
      id: 'necktie',
      name: 'ربطة عنق رسمية',
      desc: 'ربطة عنق زرقاء أنيقة للمظهر المهذب والجاد!',
      price: 115,
      emoji: '👔',
      anchorType: 'neck',
    ),
    BuddyAccessory(
      id: 'medal',
      name: 'الميدالية الذهبية',
      desc: 'ميدالية المركز الأول للرفيق الفائز دائماً!',
      price: 280,
      emoji: '🥇',
      anchorType: 'neck',
    ),
    BuddyAccessory(
      id: 'necklace',
      name: 'عقد اللؤلؤ الفاخر',
      desc: 'عقد لؤلؤ أبيض كلاسيكي يعكس الفخامة!',
      price: 230,
      emoji: '📿',
      anchorType: 'neck',
    ),
    BuddyAccessory(
      id: 'pacifier',
      name: 'لهاية الأطفال اللطيفة',
      desc: 'لهاية لرفيق يتصرف كالأطفال الصغار!',
      price: 50,
      emoji: '🍼',
      anchorType: 'neck',
    ),
    BuddyAccessory(
      id: 'camera_strap',
      name: 'كاميرا معلقة',
      desc: 'كاميرا احترافية معلقة جاهزة للتصوير!',
      price: 190,
      emoji: '📷',
      anchorType: 'neck',
    ),
    BuddyAccessory(
      id: 'magic_wand',
      name: 'العصا السحرية للنجوم',
      desc: 'عصا تطلق نجوم سحرية براقة وتأثيرات مذهلة!',
      price: 270,
      emoji: '🪄',
      anchorType: 'hand_right',
    ),
    BuddyAccessory(
      id: 'sword',
      name: 'سيف الفارس الشجاع',
      desc: 'سيف فضي لامع مستعد لحماية المحادثة!',
      price: 320,
      emoji: '⚔️',
      anchorType: 'hand_right',
    ),
    BuddyAccessory(
      id: 'shield',
      name: 'درع الحماية الحديدي',
      desc: 'درع قوي لصد أي كلمات مسيئة أو مزعجة!',
      price: 290,
      emoji: '🛡️',
      anchorType: 'hand_left',
    ),
    BuddyAccessory(
      id: 'balloon',
      name: 'البالون الطائر الأحمر',
      desc: 'بالون مليء بالهيليوم يطير بجانب رفيقك!',
      price: 80,
      emoji: '🎈',
      anchorType: 'hand_right',
    ),
    BuddyAccessory(
      id: 'umbrella',
      name: 'مظلة المطر الملونة',
      desc: 'مظلة تحمي رفيقك من تقلبات الجو!',
      price: 130,
      emoji: '☂️',
      anchorType: 'hand_right',
    ),
    BuddyAccessory(
      id: 'cookie',
      name: 'بسكوتة الشوكولاتة',
      desc: 'قطعة كوكيز مقرمشة ومحشوة بقطع الشوكولاتة!',
      price: 45,
      emoji: '🍪',
      anchorType: 'hand_right',
    ),
    BuddyAccessory(
      id: 'coffee_mug',
      name: 'كوب قهوة ساخن',
      desc: 'كوب قهوة برغوة كثيفة لبداية يوم نشيط!',
      price: 110,
      emoji: '☕',
      anchorType: 'hand_right',
    ),
    BuddyAccessory(
      id: 'microphone',
      name: 'ميكروفون الغناء',
      desc: 'ميكروفون لاسلكي لرفيق يحب الغناء والشهرة!',
      price: 200,
      emoji: '🎤',
      anchorType: 'hand_right',
    ),
    BuddyAccessory(
      id: 'lollipop',
      name: 'مصاصة الحلوى الملونة',
      desc: 'مصاصة حلوى دائرية بنكهة الفواكه اللذيذة!',
      price: 55,
      emoji: '🍭',
      anchorType: 'hand_right',
    ),
    BuddyAccessory(
      id: 'angel_wings',
      name: 'أجنحة الملاك البيضاء',
      desc: 'أجنحة ريش بيضاء ترفرف بنعومة وتوهج!',
      price: 500,
      emoji: '👼',
      anchorType: 'back',
    ),
    BuddyAccessory(
      id: 'demon_wings',
      name: 'أجنحة الخفاش المظلمة',
      desc: 'أجنحة تنين سوداء غامضة وقوية!',
      price: 480,
      emoji: '🦇',
      anchorType: 'back',
    ),
    BuddyAccessory(
      id: 'rocket_pack',
      name: 'حقيبة النفاثة الصاروخية',
      desc: 'صاروخ نفاث ينطلق بلهب ونار مذهلة في الخلف!',
      price: 600,
      emoji: '🚀',
      anchorType: 'back',
    ),
    BuddyAccessory(
      id: 'aura_sparks',
      name: 'هالة الشرر اللامع',
      desc: 'تأثير شرر ذهبي متطاير يحيط بالرفيق!',
      price: 380,
      emoji: '✨',
      anchorType: 'back',
    ),
    BuddyAccessory(
      id: 'cape',
      name: 'عباءة الأبطال الحمراء',
      desc: 'عباءة حمراء ترفرف خلف رفيقك أثناء وقوفه!',
      price: 250,
      emoji: '🦸‍♂️',
      anchorType: 'back',
    ),
  ];
}

class BuddyAccessoryPainter extends CustomPainter {
  final String? accessoryId;
  final String characterEmoji; // '⭐', '🐱', '🐰'

  BuddyAccessoryPainter({
    required this.accessoryId,
    required this.characterEmoji,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (accessoryId == null || accessoryId!.isEmpty) return;

    final double w = size.width;
    final double h = size.height;

    // Define relative scale and anchor positions for each character
    double scale = 1.0;
    Offset hatAnchor = Offset(w * 0.5, h * 0.15);
    Offset eyeAnchor = Offset(w * 0.5, h * 0.45);
    Offset neckAnchor = Offset(w * 0.5, h * 0.80);

    if (characterEmoji == '🐱') {
      scale = 0.95;
      hatAnchor = Offset(w * 0.5, h * 0.22);
      eyeAnchor = Offset(w * 0.5, h * 0.48);
      neckAnchor = Offset(w * 0.5, h * 0.82);
    } else if (characterEmoji == '🐰') {
      scale = 0.90;
      hatAnchor = Offset(w * 0.5, h * 0.35); // Lower head center due to long ears
      eyeAnchor = Offset(w * 0.5, h * 0.54);
      neckAnchor = Offset(w * 0.5, h * 0.85);
    } else {
      // Default to Spark '⭐'
      scale = 1.0;
      hatAnchor = Offset(w * 0.5, h * 0.18);
      eyeAnchor = Offset(w * 0.5, h * 0.45);
      neckAnchor = Offset(w * 0.5, h * 0.78);
    }

    canvas.save();
    
    final bool isCustomDrawn = const [
      'glasses', 'party_hat', 'bowtie', 'scarf', 'crown', 'chef_hat', 'mustache', 'heart_glasses'
    ].contains(accessoryId);

    if (isCustomDrawn) {
      // Perform custom vector drawing based on the accessory type
      switch (accessoryId) {
        case 'glasses':
          _drawGlasses(canvas, eyeAnchor, w * 0.45 * scale);
          break;
        case 'party_hat':
          _drawPartyHat(canvas, hatAnchor, w * 0.35 * scale);
          break;
        case 'bowtie':
          _drawBowtie(canvas, neckAnchor, w * 0.25 * scale);
          break;
        case 'scarf':
          _drawScarf(canvas, neckAnchor, w * 0.45 * scale);
          break;
        case 'crown':
          _drawCrown(canvas, hatAnchor, w * 0.35 * scale);
          break;
        case 'chef_hat':
          _drawChefHat(canvas, hatAnchor, w * 0.35 * scale);
          break;
        case 'mustache':
          _drawMustache(canvas, eyeAnchor, w * 0.45 * scale);
          break;
        case 'heart_glasses':
          _drawHeartGlasses(canvas, eyeAnchor, w * 0.45 * scale);
          break;
      }
    } else {
      // Use general emoji-based text rendering for other 50+ items
      _drawEmojiAccessory(canvas, w, h, scale, hatAnchor, eyeAnchor, neckAnchor);
    }

    canvas.restore();
  }

  void _drawGlasses(Canvas canvas, Offset anchor, double width) {
    final double lensRadius = width * 0.22;
    final double bridgeWidth = width * 0.16;

    // Paints
    final framePaint = Paint()
      ..color = const Color(0xFF1E293B) // Dark Slate frame
      ..style = PaintingStyle.fill;

    final lensPaint = Paint()
      ..color = const Color(0xFF0F172A).withOpacity(0.85) // Dark lenses
      ..style = PaintingStyle.fill;

    // Draw Left and Right Frame Outlines
    final Offset leftCenter = Offset(anchor.dx - (lensRadius + bridgeWidth / 2) * 0.8, anchor.dy);
    final Offset rightCenter = Offset(anchor.dx + (lensRadius + bridgeWidth / 2) * 0.8, anchor.dy);

    // Outer frame (slightly larger than lenses)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: leftCenter, width: lensRadius * 2.3, height: lensRadius * 2.1),
        Radius.circular(lensRadius * 0.6),
      ),
      framePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: rightCenter, width: lensRadius * 2.3, height: lensRadius * 2.1),
        Radius.circular(lensRadius * 0.6),
      ),
      framePaint,
    );

    // Inner lenses
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: leftCenter, width: lensRadius * 1.9, height: lensRadius * 1.7),
        Radius.circular(lensRadius * 0.5),
      ),
      lensPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: rightCenter, width: lensRadius * 1.9, height: lensRadius * 1.7),
        Radius.circular(lensRadius * 0.5),
      ),
      lensPaint,
    );

    // Draw Bridge
    final Path bridgePath = Path()
      ..moveTo(leftCenter.dx + lensRadius * 0.85, leftCenter.dy - lensRadius * 0.2)
      ..quadraticBezierTo(
        anchor.dx,
        anchor.dy - lensRadius * 0.5,
        rightCenter.dx - lensRadius * 0.85,
        rightCenter.dy - lensRadius * 0.2,
      )
      ..lineTo(rightCenter.dx - lensRadius * 0.85, rightCenter.dy + lensRadius * 0.1)
      ..quadraticBezierTo(
        anchor.dx,
        anchor.dy - lensRadius * 0.2,
        leftCenter.dx + lensRadius * 0.85,
        leftCenter.dy + lensRadius * 0.1,
      )
      ..close();
    canvas.drawPath(bridgePath, framePaint);

    // Temples (side arms of glasses)
    final templePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width * 0.08
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(leftCenter.dx - lensRadius * 1.1, leftCenter.dy),
      Offset(leftCenter.dx - lensRadius * 1.5, leftCenter.dy - lensRadius * 0.3),
      templePaint,
    );
    canvas.drawLine(
      Offset(rightCenter.dx + lensRadius * 1.1, rightCenter.dy),
      Offset(rightCenter.dx + lensRadius * 1.5, rightCenter.dy - lensRadius * 0.3),
      templePaint,
    );

    // Shine/Glare on Lenses
    final glarePaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Draw diagonal glare lines
    canvas.drawLine(
      Offset(leftCenter.dx - lensRadius * 0.4, leftCenter.dy - lensRadius * 0.4),
      Offset(leftCenter.dx + lensRadius * 0.2, leftCenter.dy + lensRadius * 0.4),
      glarePaint,
    );
    canvas.drawLine(
      Offset(rightCenter.dx - lensRadius * 0.4, rightCenter.dy - lensRadius * 0.4),
      Offset(rightCenter.dx + lensRadius * 0.2, rightCenter.dy + lensRadius * 0.4),
      glarePaint,
    );
  }

  void _drawPartyHat(Canvas canvas, Offset anchor, double width) {
    final double hatHeight = width * 1.3;

    // 1. Draw Cone Hat
    final Path conePath = Path()
      ..moveTo(anchor.dx - width * 0.5, anchor.dy)
      ..lineTo(anchor.dx, anchor.dy - hatHeight)
      ..lineTo(anchor.dx + width * 0.5, anchor.dy)
      ..close();

    final conePaint = Paint()
      ..color = const Color(0xFFFF6B6B) // Coral base
      ..style = PaintingStyle.fill;
    canvas.drawPath(conePath, conePaint);

    // Draw Stripes on Cone
    canvas.save();
    canvas.clipPath(conePath);

    final stripePaint = Paint()
      ..color = const Color(0xFFFFD93D) // Yellow stripes
      ..style = PaintingStyle.stroke
      ..strokeWidth = width * 0.12;

    for (double offset = -width; offset < width * 2; offset += width * 0.3) {
      canvas.drawLine(
        Offset(anchor.dx - width + offset, anchor.dy),
        Offset(anchor.dx + offset, anchor.dy - hatHeight),
        stripePaint,
      );
    }
    canvas.restore();

    // 2. Brim Fluff at bottom
    final brimPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final int fluffyCircles = 7;
    final double brimStep = width / (fluffyCircles - 1);
    final double brimRadius = width * 0.085;

    for (int i = 0; i < fluffyCircles; i++) {
      final double cx = anchor.dx - width * 0.5 + (i * brimStep);
      // Curve the brim slightly
      final double cy = anchor.dy + math.sin((i / (fluffyCircles - 1)) * math.pi) * (width * 0.06);
      canvas.drawCircle(Offset(cx, cy), brimRadius, brimPaint);
    }

    // 3. Fluffy Pom-pom on top
    final pomPomPaint = Paint()
      ..color = const Color(0xFFFF8AAE) // Pastel pink
      ..style = PaintingStyle.fill;
    
    final Offset topOffset = Offset(anchor.dx, anchor.dy - hatHeight);
    canvas.drawCircle(topOffset, width * 0.12, pomPomPaint);

    final pomPomDetailPaint = Paint()
      ..color = const Color(0xFFFFF0F5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(topOffset - Offset(width * 0.03, width * 0.03), width * 0.04, pomPomDetailPaint);
  }

  void _drawBowtie(Canvas canvas, Offset anchor, double width) {
    final double height = width * 0.5;

    final Path leftWing = Path()
      ..moveTo(anchor.dx, anchor.dy)
      ..lineTo(anchor.dx - width * 0.5, anchor.dy - height * 0.5)
      ..lineTo(anchor.dx - width * 0.4, anchor.dy)
      ..lineTo(anchor.dx - width * 0.5, anchor.dy + height * 0.5)
      ..close();

    final Path rightWing = Path()
      ..moveTo(anchor.dx, anchor.dy)
      ..lineTo(anchor.dx + width * 0.5, anchor.dy - height * 0.5)
      ..lineTo(anchor.dx + width * 0.4, anchor.dy)
      ..lineTo(anchor.dx + width * 0.5, anchor.dy + height * 0.5)
      ..close();

    final tiePaint = Paint()
      ..color = const Color(0xFF8B5CF6) // Royal Purple
      ..style = PaintingStyle.fill;

    // Draw wings
    canvas.drawPath(leftWing, tiePaint);
    canvas.drawPath(rightWing, tiePaint);

    // Draw outline
    final outlinePaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(leftWing, outlinePaint);
    canvas.drawPath(rightWing, outlinePaint);

    // Draw center knot
    final knotPaint = Paint()
      ..color = const Color(0xFFFFD93D) // Yellow gold knot
      ..style = PaintingStyle.fill;
    canvas.drawCircle(anchor, width * 0.14, knotPaint);
  }

  void _drawScarf(Canvas canvas, Offset anchor, double width) {
    final double thickness = width * 0.18;
    
    // Draw Scarf main wrap (oval curve)
    final Rect rect = Rect.fromCenter(center: anchor, width: width, height: thickness * 1.8);
    final Paint scarfPaint = Paint()
      ..color = const Color(0xFF10B981) // Emerald green scarf
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(thickness * 0.8)),
      scarfPaint,
    );

    // Draw stripes on wrap
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(rect, Radius.circular(thickness * 0.8)));
    
    final stripePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = width * 0.05;

    for (double offset = -width * 0.5; offset < width * 0.5; offset += width * 0.15) {
      canvas.drawLine(
        Offset(anchor.dx + offset, anchor.dy - thickness),
        Offset(anchor.dx + offset + width * 0.08, anchor.dy + thickness),
        stripePaint,
      );
    }
    canvas.restore();

    // Draw hanging tails
    final Path tail = Path()
      ..moveTo(anchor.dx + width * 0.15, anchor.dy)
      ..lineTo(anchor.dx + width * 0.35, anchor.dy + width * 0.35)
      ..lineTo(anchor.dx + width * 0.20, anchor.dy + width * 0.35)
      ..lineTo(anchor.dx + width * 0.05, anchor.dy)
      ..close();

    canvas.drawPath(tail, scarfPaint);

    // Tassels at the bottom of the tail
    final tasselPaint = Paint()
      ..color = const Color(0xFFFFD93D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (int i = 0; i < 5; i++) {
      final double tx = anchor.dx + width * 0.20 + (i * width * 0.03);
      canvas.drawLine(
        Offset(tx, anchor.dy + width * 0.35),
        Offset(tx, anchor.dy + width * 0.40),
        tasselPaint,
      );
    }
  }

  void _drawCrown(Canvas canvas, Offset anchor, double width) {
    final double crownHeight = width * 0.6;
    final double crownWidth = width * 0.9;
    
    // Golden paint
    final crownPaint = Paint()
      ..color = const Color(0xFFFBBF24) // Golden yellow
      ..style = PaintingStyle.fill;
      
    final darkGoldPaint = Paint()
      ..color = const Color(0xFFD97706) // Darker gold for details/shading
      ..style = PaintingStyle.fill;

    final redGemPaint = Paint()
      ..color = const Color(0xFFEF4444) // Ruby red gem
      ..style = PaintingStyle.fill;

    final blueGemPaint = Paint()
      ..color = const Color(0xFF3B82F6) // Sapphire blue gem
      ..style = PaintingStyle.fill;

    // Draw the crown shape with peaks
    final Path crownPath = Path()
      ..moveTo(anchor.dx - crownWidth * 0.5, anchor.dy)
      ..lineTo(anchor.dx - crownWidth * 0.5, anchor.dy - crownHeight * 0.4) // Left side
      ..lineTo(anchor.dx - crownWidth * 0.35, anchor.dy - crownHeight) // Left peak
      ..lineTo(anchor.dx - crownWidth * 0.15, anchor.dy - crownHeight * 0.3) // Left valley
      ..lineTo(anchor.dx, anchor.dy - crownHeight * 1.2) // Center peak (highest)
      ..lineTo(anchor.dx + crownWidth * 0.15, anchor.dy - crownHeight * 0.3) // Right valley
      ..lineTo(anchor.dx + crownWidth * 0.35, anchor.dy - crownHeight) // Right peak
      ..lineTo(anchor.dx + crownWidth * 0.5, anchor.dy - crownHeight * 0.4) // Right side
      ..lineTo(anchor.dx + crownWidth * 0.5, anchor.dy) // Bottom right
      ..close();

    // Draw crown base shadow/border at bottom
    canvas.drawPath(crownPath, crownPaint);

    // Draw crown bottom band
    final Rect bottomBand = Rect.fromLTRB(
      anchor.dx - crownWidth * 0.5,
      anchor.dy - crownHeight * 0.2,
      anchor.dx + crownWidth * 0.5,
      anchor.dy,
    );
    canvas.drawRect(bottomBand, darkGoldPaint);

    // Draw small circles/gems on the peaks
    canvas.drawCircle(Offset(anchor.dx - crownWidth * 0.35, anchor.dy - crownHeight), width * 0.08, darkGoldPaint);
    canvas.drawCircle(Offset(anchor.dx, anchor.dy - crownHeight * 1.2), width * 0.1, darkGoldPaint);
    canvas.drawCircle(Offset(anchor.dx + crownWidth * 0.35, anchor.dy - crownHeight), width * 0.08, darkGoldPaint);

    // Draw actual bright circles on top of gold circles
    canvas.drawCircle(Offset(anchor.dx - crownWidth * 0.35, anchor.dy - crownHeight), width * 0.05, redGemPaint);
    canvas.drawCircle(Offset(anchor.dx, anchor.dy - crownHeight * 1.2), width * 0.06, redGemPaint);
    canvas.drawCircle(Offset(anchor.dx + crownWidth * 0.35, anchor.dy - crownHeight), width * 0.05, redGemPaint);

    // Draw some gems on the bottom band
    canvas.drawCircle(Offset(anchor.dx - crownWidth * 0.25, anchor.dy - crownHeight * 0.1), width * 0.04, redGemPaint);
    canvas.drawCircle(Offset(anchor.dx, anchor.dy - crownHeight * 0.1), width * 0.045, blueGemPaint);
    canvas.drawCircle(Offset(anchor.dx + crownWidth * 0.25, anchor.dy - crownHeight * 0.1), width * 0.04, redGemPaint);
  }

  void _drawChefHat(Canvas canvas, Offset anchor, double width) {
    final double hatHeight = width * 1.0;
    final double hatWidth = width * 0.8;

    // Paints
    final whitePaint = Paint()
      ..color = const Color(0xFFF8FAFC) // Off-white
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = const Color(0xFFCBD5E1) // Soft grey shadow
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = const Color(0xFF64748B) // Slate outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Draw band at the bottom
    final Rect bandRect = Rect.fromCenter(
      center: Offset(anchor.dx, anchor.dy - hatHeight * 0.15),
      width: hatWidth * 0.8,
      height: hatHeight * 0.3,
    );
    final RRect bandRRect = RRect.fromRectAndRadius(bandRect, Radius.circular(4));

    // Draw the puffy top (three overlapping circles)
    final Offset centerCircle = Offset(anchor.dx, anchor.dy - hatHeight * 0.65);
    final double centerRadius = hatWidth * 0.45;

    final Offset leftCircle = Offset(anchor.dx - hatWidth * 0.32, anchor.dy - hatHeight * 0.5);
    final double leftRadius = hatWidth * 0.35;

    final Offset rightCircle = Offset(anchor.dx + hatWidth * 0.32, anchor.dy - hatHeight * 0.5);
    final double rightRadius = hatWidth * 0.35;

    // Drawing shadow first, slightly offset down and right
    final double shadowOffset = 3.0;
    canvas.save();
    canvas.translate(shadowOffset, shadowOffset);
    
    // Draw shadow path
    final Path shadowPath = Path()
      ..addOval(Rect.fromCircle(center: leftCircle, radius: leftRadius))
      ..addOval(Rect.fromCircle(center: rightCircle, radius: rightRadius))
      ..addOval(Rect.fromCircle(center: centerCircle, radius: centerRadius))
      ..addRRect(bandRRect);
    canvas.drawPath(shadowPath, shadowPaint);
    canvas.restore();

    // Now draw main white shapes
    canvas.drawOval(Rect.fromCircle(center: leftCircle, radius: leftRadius), whitePaint);
    canvas.drawOval(Rect.fromCircle(center: leftCircle, radius: leftRadius), outlinePaint);

    canvas.drawOval(Rect.fromCircle(center: rightCircle, radius: rightRadius), whitePaint);
    canvas.drawOval(Rect.fromCircle(center: rightCircle, radius: rightRadius), outlinePaint);

    canvas.drawOval(Rect.fromCircle(center: centerCircle, radius: centerRadius), whitePaint);
    canvas.drawOval(Rect.fromCircle(center: centerCircle, radius: centerRadius), outlinePaint);

    // Draw white band to cover overlapping lower parts
    canvas.drawRRect(bandRRect, whitePaint);
    canvas.drawRRect(bandRRect, outlinePaint);

    // Draw small detail creases in the hat
    final Paint creasePaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(anchor.dx - hatWidth * 0.15, anchor.dy - hatHeight * 0.3),
      Offset(anchor.dx - hatWidth * 0.1, anchor.dy - hatHeight * 0.55),
      creasePaint,
    );
    canvas.drawLine(
      Offset(anchor.dx + hatWidth * 0.15, anchor.dy - hatHeight * 0.3),
      Offset(anchor.dx + hatWidth * 0.1, anchor.dy - hatHeight * 0.55),
      creasePaint,
    );
  }

  void _drawMustache(Canvas canvas, Offset anchor, double width) {
    // We position the mustache slightly lower than eyeAnchor
    final Offset center = Offset(anchor.dx, anchor.dy + width * 0.25);
    final double mustWidth = width * 0.9;
    final double mustHeight = width * 0.3;

    final Paint mustachePaint = Paint()
      ..color = const Color(0xFF1E293B) // Dark charcoal mustache
      ..style = PaintingStyle.fill;

    // Left half path
    final Path leftPath = Path()
      ..moveTo(center.dx, center.dy - mustHeight * 0.2)
      ..quadraticBezierTo(
        center.dx - mustWidth * 0.25,
        center.dy - mustHeight * 0.7,
        center.dx - mustWidth * 0.45,
        center.dy - mustHeight * 0.8,
      )
      ..quadraticBezierTo(
        center.dx - mustWidth * 0.6,
        center.dy - mustHeight * 0.9,
        center.dx - mustWidth * 0.5,
        center.dy - mustHeight * 0.3,
      )
      ..quadraticBezierTo(
        center.dx - mustWidth * 0.4,
        center.dy + mustHeight * 0.3,
        center.dx - mustWidth * 0.2,
        center.dy + mustHeight * 0.1,
      )
      ..quadraticBezierTo(
        center.dx - mustWidth * 0.05,
        center.dy + mustHeight * 0.2,
        center.dx,
        center.dy,
      )
      ..close();

    // Right half path (symmetrical)
    final Path rightPath = Path()
      ..moveTo(center.dx, center.dy - mustHeight * 0.2)
      ..quadraticBezierTo(
        center.dx + mustWidth * 0.25,
        center.dy - mustHeight * 0.7,
        center.dx + mustWidth * 0.45,
        center.dy - mustHeight * 0.8,
      )
      ..quadraticBezierTo(
        center.dx + mustWidth * 0.6,
        center.dy - mustHeight * 0.9,
        center.dx + mustWidth * 0.5,
        center.dy - mustHeight * 0.3,
      )
      ..quadraticBezierTo(
        center.dx + mustWidth * 0.4,
        center.dy + mustHeight * 0.3,
        center.dx + mustWidth * 0.2,
        center.dy + mustHeight * 0.1,
      )
      ..quadraticBezierTo(
        center.dx + mustWidth * 0.05,
        center.dy + mustHeight * 0.2,
        center.dx,
        center.dy,
      )
      ..close();

    canvas.drawPath(leftPath, mustachePaint);
    canvas.drawPath(rightPath, mustachePaint);

    // Outline for definition
    final Paint outlinePaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(leftPath, outlinePaint);
    canvas.drawPath(rightPath, outlinePaint);
  }

  void _drawHeartGlasses(Canvas canvas, Offset anchor, double width) {
    final double heartSize = width * 0.4;
    final double bridgeWidth = width * 0.16;

    final framePaint = Paint()
      ..color = const Color(0xFFEF4444) // Vibrant Red frame
      ..style = PaintingStyle.fill;

    final lensPaint = Paint()
      ..color = const Color(0xFFEF4444).withOpacity(0.3) // Transparent red lenses
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Centers of hearts
    final Offset leftCenter = Offset(anchor.dx - (heartSize / 2 + bridgeWidth / 2) * 0.85, anchor.dy);
    final Offset rightCenter = Offset(anchor.dx + (heartSize / 2 + bridgeWidth / 2) * 0.85, anchor.dy);

    // Function to draw a heart path
    Path getHeartPath(Offset center, double size) {
      final Path path = Path();
      final double x = center.dx;
      final double y = center.dy - size * 0.15;
      
      // Starting from bottom point
      path.moveTo(x, y + size * 0.45);
      
      // Left side curves
      path.cubicTo(
        x - size * 0.6, y - size * 0.1,
        x - size * 0.5, y - size * 0.6,
        x, y - size * 0.35,
      );
      
      // Right side curves
      path.cubicTo(
        x + size * 0.5, y - size * 0.6,
        x + size * 0.6, y - size * 0.1,
        x, y + size * 0.45,
      );
      path.close();
      return path;
    }

    // Outer frames
    final Path leftHeartOuter = getHeartPath(leftCenter, heartSize * 1.15);
    final Path rightHeartOuter = getHeartPath(rightCenter, heartSize * 1.15);
    canvas.drawPath(leftHeartOuter, framePaint);
    canvas.drawPath(rightHeartOuter, framePaint);

    // Inner lenses
    final Path leftHeartInner = getHeartPath(leftCenter, heartSize * 0.85);
    final Path rightHeartInner = getHeartPath(rightCenter, heartSize * 0.85);
    canvas.drawPath(leftHeartInner, lensPaint);
    canvas.drawPath(rightHeartInner, lensPaint);
    canvas.drawPath(leftHeartInner, outlinePaint);
    canvas.drawPath(rightHeartInner, outlinePaint);

    // Draw bridge
    final bridgePaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width * 0.08
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(leftCenter.dx + heartSize * 0.3, leftCenter.dy),
      Offset(rightCenter.dx - heartSize * 0.3, rightCenter.dy),
      bridgePaint,
    );

    // Side arms
    final templePaint = Paint()
      ..color = const Color(0xFFDC2626)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width * 0.06
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(leftCenter.dx - heartSize * 0.5, leftCenter.dy),
      Offset(leftCenter.dx - heartSize * 0.9, leftCenter.dy - heartSize * 0.2),
      templePaint,
    );
    canvas.drawLine(
      Offset(rightCenter.dx + heartSize * 0.5, rightCenter.dy),
      Offset(rightCenter.dx + heartSize * 0.9, rightCenter.dy - heartSize * 0.2),
      templePaint,
    );

    // Flare on lenses
    final flarePaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(leftCenter.dx - heartSize * 0.2, leftCenter.dy - heartSize * 0.2),
      Offset(leftCenter.dx + heartSize * 0.1, leftCenter.dy + heartSize * 0.1),
      flarePaint,
    );
    canvas.drawLine(
      Offset(rightCenter.dx - heartSize * 0.2, rightCenter.dy - heartSize * 0.2),
      Offset(rightCenter.dx + heartSize * 0.1, rightCenter.dy + heartSize * 0.1),
      flarePaint,
    );
  }

  void _drawEmojiAccessory(
    Canvas canvas,
    double w,
    double h,
    double scale,
    Offset hatAnchor,
    Offset eyeAnchor,
    Offset neckAnchor,
  ) {
    // Find the accessory matching the ID
    final accessory = BuddyAccessory.allAccessories.firstWhere(
      (a) => a.id == accessoryId,
      orElse: () => const BuddyAccessory(id: '', name: '', desc: '', price: 0, emoji: '', anchorType: ''),
    );
    if (accessory.id.isEmpty) return;

    Offset drawPoint = eyeAnchor;
    double emojiSize = w * 0.35 * scale;
    double rotation = 0.0;

    switch (accessory.anchorType) {
      case 'hat':
        drawPoint = hatAnchor;
        emojiSize = w * 0.42 * scale;
        // Adjust vertically a bit up for hats to sit nicely on heads
        drawPoint = Offset(drawPoint.dx, drawPoint.dy - emojiSize * 0.15);
        break;
      case 'eye':
        drawPoint = eyeAnchor;
        emojiSize = w * 0.40 * scale;
        break;
      case 'neck':
        drawPoint = neckAnchor;
        emojiSize = w * 0.35 * scale;
        // Adjust slightly up to align with neck
        drawPoint = Offset(drawPoint.dx, drawPoint.dy - emojiSize * 0.1);
        break;
      case 'hand_right':
        drawPoint = Offset(w * 0.82, h * 0.65);
        if (characterEmoji == '🐱') {
          drawPoint = Offset(w * 0.78, h * 0.68);
        } else if (characterEmoji == '🐰') {
          drawPoint = Offset(w * 0.76, h * 0.70);
        }
        emojiSize = w * 0.32 * scale;
        break;
      case 'hand_left':
        drawPoint = Offset(w * 0.18, h * 0.65);
        if (characterEmoji == '🐱') {
          drawPoint = Offset(w * 0.22, h * 0.68);
        } else if (characterEmoji == '🐰') {
          drawPoint = Offset(w * 0.24, h * 0.70);
        }
        emojiSize = w * 0.32 * scale;
        break;
      case 'back':
        // Wings need to peek out from the sides
        final leftWingPoint = Offset(w * 0.15, h * 0.52);
        final rightWingPoint = Offset(w * 0.85, h * 0.52);
        emojiSize = w * 0.45 * scale;

        // Draw Left Wing (mirrored/rotated slightly outwards)
        _drawEmojiText(canvas, accessory.emoji, leftWingPoint, emojiSize, rotation: -0.2);
        // Draw Right Wing
        _drawEmojiText(canvas, accessory.emoji, rightWingPoint, emojiSize, rotation: 0.2);
        return;
    }

    _drawEmojiText(canvas, accessory.emoji, drawPoint, emojiSize, rotation: rotation);
  }

  void _drawEmojiText(Canvas canvas, String emoji, Offset center, double size, {double rotation = 0.0}) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    if (rotation != 0.0) {
      canvas.rotate(rotation);
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: emoji,
        style: TextStyle(
          fontSize: size,
          fontFamily: 'Segoe UI Emoji',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant BuddyAccessoryPainter oldDelegate) {
    return oldDelegate.accessoryId != accessoryId ||
        oldDelegate.characterEmoji != characterEmoji;
  }
}
