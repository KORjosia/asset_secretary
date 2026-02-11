import 'package:flutter/material.dart';

class CommunityUI {
  static const bgTop = Color(0xFF071A2C);
  static const bgBottom = Color(0xFF040B16);

  static const accent = Color(0xFF0AA3E3);
  static const accent2 = Color(0xFF22C1F6);

  static const textDim = Color(0x99FFFFFF);
  static const border = Color(0x22FFFFFF);
  static const card = Color(0x0FFFFFFF);
  static const tile = Color(0x121A2A);

  static BoxDecoration background() => const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bgTop, bgBottom],
        ),
      );

  static BoxDecoration cardDeco({bool filled = true}) => BoxDecoration(
        color: filled ? card : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      );

  static BoxDecoration tileDeco() => BoxDecoration(
        color: tile,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      );

  static PreferredSizeWidget appBar({
    required String title,
    List<Widget> actions = const [],
    Widget? leading,
  }) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: Colors.white,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      centerTitle: false,
      leading: leading,
      actions: actions,
    );
  }
}

/// 예시 이미지 같은 ‘필터 칩’
class FilterChipPill extends StatelessWidget {
  const FilterChipPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? CommunityUI.accent : const Color(0x121A2A);
    final bd = selected ? const Color(0x00000000) : CommunityUI.border;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: bd),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

/// 상단 큰 배너 카드 (예시의 “전체 보고서 보기” 같은 버튼 포함 가능)
class HeroBannerCard extends StatelessWidget {
  const HeroBannerCard({
    super.key,
    required this.tag,
    required this.title,
    required this.desc,
    this.onPrimaryTap,
    this.primaryLabel = '자세히 보기',
  });

  final String tag;
  final String title;
  final String desc;
  final VoidCallback? onPrimaryTap;
  final String primaryLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [CommunityUI.accent2, CommunityUI.accent],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(blurRadius: 24, offset: Offset(0, 10), color: Color(0x220AA3E3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TagPill(text: tag, filled: true),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(height: 8),
          Text(desc, style: const TextStyle(color: Color(0xE6FFFFFF), fontSize: 12, height: 1.35)),
          const SizedBox(height: 14),
          if (onPrimaryTap != null)
            SizedBox(
              height: 40,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF071A2C),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: onPrimaryTap,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.show_chart_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text(primaryLabel, style: const TextStyle(fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.text, this.filled = false});
  final String text;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: filled ? Colors.white : const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: filled ? const Color(0x00000000) : CommunityUI.border),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: filled ? const Color(0xFF071A2C) : Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 11,
        ),
      ),
    );
  }
}
