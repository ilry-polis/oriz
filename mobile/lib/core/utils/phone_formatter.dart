import 'package:flutter/services.dart';

/// Formats Brazilian phone numbers as (XX) XXXX-XXXX or (XX) XXXXX-XXXX.
/// Accepts only digits, auto-applies mask as user types.
class BrazilPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Limit to 11 digits (DDD + celular)
    final trimmed = digits.length > 11 ? digits.substring(0, 11) : digits;

    final buffer = StringBuffer();
    for (var i = 0; i < trimmed.length; i++) {
      if (i == 0) buffer.write('(');
      if (i == 2) buffer.write(') ');
      // Celular (11 digits): traço após o 7º dígito (posição 7)
      // Fixo (10 digits): traço após o 6º dígito (posição 6)
      if (trimmed.length <= 10 && i == 6) buffer.write('-');
      if (trimmed.length == 11 && i == 7) buffer.write('-');
      buffer.write(trimmed[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Strips mask from formatted phone, returns digits only.
String stripPhoneMask(String formatted) {
  return formatted.replaceAll(RegExp(r'\D'), '');
}
