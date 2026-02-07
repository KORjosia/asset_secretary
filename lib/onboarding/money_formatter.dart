//asset_secretary\lib\onboarding\money_formatter.dart
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ThousandsFormatter extends TextInputFormatter {
  ThousandsFormatter({this.max = 999999999999});
  final int max;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
    }

    final value = int.tryParse(digits) ?? 0;
    final clamped = value > max ? max : value;

    final formatted = NumberFormat.decimalPattern('ko_KR').format(clamped);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

int parseMoney(String s) {
  final digits = s.replaceAll(',', '').trim();
  if (digits.isEmpty) return 0;
  return int.tryParse(digits) ?? 0;
}
