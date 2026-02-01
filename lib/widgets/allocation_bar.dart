// 위치: lib/widgets/allocation_bar.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../providers/portfolio_providers.dart';

final _currency = NumberFormat.currency(locale: 'ko_KR', symbol: '₩');

class AllocationBar extends StatelessWidget {
  final List<AllocationSlice> slices;
  final int extraInflowWon;

  const AllocationBar({
    super.key,
    required this.slices,
    required this.extraInflowWon,
  });

  @override
  Widget build(BuildContext context) {
    if (slices.isEmpty) {
      return Container(
        height: 44,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text('월 수익 입력 후, 계좌별 입금 분배가 표시됩니다.'),
      );
    }

    final totalPercent = slices.fold<double>(0, (s, x) => s + x.percentOfIncome).clamp(0, 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 막대
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 14,
            child: Row(
              children: [
                for (final s in slices.where((x) => x.percentOfIncome > 0))
                  Flexible(
                    flex: (s.percentOfIncome * 1000).round().clamp(1, 1000000),
                    child: Container(color: s.color),
                  ),
                if (totalPercent < 1)
                  Flexible(
                    flex: ((1 - totalPercent) * 1000).round().clamp(1, 1000000),
                    child: Container(color: Colors.grey.shade200),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        // 뱃지/범례
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (extraInflowWon > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Text('추가입금 +${_currency.format(extraInflowWon)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            for (final s in slices)
              _LegendChip(
                color: s.color,
                label: s.label,
                value: _currency.format(s.amountWon),
                emphasized: s.isRemainder,
              ),
          ],
        ),
      ],
    );
  }
}

class _LegendChip extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final bool emphasized;

  const _LegendChip({
    required this.color,
    required this.label,
    required this.value,
    required this.emphasized,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: emphasized ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(width: 6),
          Text(value, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}
