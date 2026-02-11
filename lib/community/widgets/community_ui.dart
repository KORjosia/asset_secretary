//lib/community/widgets/community_ui.dart

import 'package:flutter/material.dart';

class CommunityUI {
  static const bgTop = Color(0xFF0A1730);
  static const bgBottom = Color(0xFF070F1F);
  static const accent = Color(0xFF0AA3E3);

  static BoxDecoration pageBg() => const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bgTop, bgBottom],
        ),
      );

  static BoxDecoration cardDeco() => BoxDecoration(
        color: const Color(0x0FFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x22FFFFFF)),
      );

  static TextStyle title() => const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14);
  static TextStyle sub() => const TextStyle(color: Color(0x99FFFFFF), fontSize: 11, height: 1.3);
}
