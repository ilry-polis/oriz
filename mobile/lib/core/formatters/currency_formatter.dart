import 'package:flutter/services.dart';

/// Brazilian currency formatter: R$ 1.200,00
/// Stores value in cents internally.
class BrazilianCurrencyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    if (digits.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final cents = int.tryParse(digits) ?? 0;
    final formatted = formatCents(cents);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  /// Formats cents to "1.200,00" (no R$ prefix — handled by InputDecoration).
  static String formatCents(int cents) {
    final reais = cents ~/ 100;
    final centavos = cents % 100;
    final reaisStr = _addThousandSeparator(reais);
    return '$reaisStr,${centavos.toString().padLeft(2, '0')}';
  }

  static String _addThousandSeparator(int value) {
    final str = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  /// Extracts cents from formatted string "1.200,00" -> 120000
  static int parseCents(String formatted) {
    final digits = formatted.replaceAll(RegExp(r'\D'), '');
    return int.tryParse(digits) ?? 0;
  }
}
