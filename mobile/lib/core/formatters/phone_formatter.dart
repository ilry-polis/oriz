import 'package:flutter/services.dart';

/// Brazilian phone formatter that auto-detects mobile vs landline.
/// Mobile: (11) 99999-9999  |  Landline: (11) 9999-9999
class BrazilianPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    if (digits.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final buffer = StringBuffer();
    int i = 0;

    // (XX)
    if (digits.length > i) {
      buffer.write('(');
      buffer.write(digits.substring(i, i + (digits.length - i).clamp(0, 2)));
      i += 2;
    }
    if (digits.length > i) {
      buffer.write(') ');
    }

    // Detect mobile (9 digits after DDD) vs landline (8 digits)
    final remaining = digits.length - i;
    final isMobile = remaining > 8 || (digits.length > 2 && digits[2] == '9');

    if (isMobile) {
      // 99999-9999
      if (digits.length > i) {
        buffer.write(digits.substring(i, i + (digits.length - i).clamp(0, 5)));
        i += 5;
      }
    } else {
      // 9999-9999
      if (digits.length > i) {
        buffer.write(digits.substring(i, i + (digits.length - i).clamp(0, 4)));
        i += 4;
      }
    }

    if (digits.length > i) {
      buffer.write('-');
      buffer.write(digits.substring(i, i + (digits.length - i).clamp(0, 4)));
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  /// Formats digits into Brazilian phone mask: (11) 99999-9999
  static String format(String digits) {
    final d = digits.replaceAll(RegExp(r'\D'), '');
    final formatter = BrazilianPhoneFormatter();
    final result = formatter.formatEditUpdate(
      TextEditingValue.empty,
      TextEditingValue(text: d),
    );
    return result.text;
  }
}

/// Extracts digits only from formatted phone for E.164 storage.
String phoneToE164(String formatted) {
  final digits = formatted.replaceAll(RegExp(r'\D'), '');
  if (digits.length >= 10) return '+55$digits';
  return digits;
}
