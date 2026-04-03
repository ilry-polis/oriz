import 'package:flutter_test/flutter_test.dart';
import 'package:oriz/features/auth/utils/validators.dart';

void main() {
  group('validateEmail', () {
    test('returns error for empty email', () {
      expect(validateEmail(''), 'Informe seu email');
    });

    test('returns error for invalid format', () {
      expect(validateEmail('not-an-email'), 'Email invalido');
      expect(validateEmail('missing@dot'), 'Email invalido');
    });

    test('returns null for valid email', () {
      expect(validateEmail('user@example.com'), isNull);
      expect(validateEmail('a@b.co'), isNull);
    });
  });

  group('validatePassword', () {
    test('returns error for empty password', () {
      expect(validatePassword(''), 'Informe sua senha');
    });

    test('returns error for short password', () {
      expect(validatePassword('1234567'), 'Minimo 8 caracteres');
    });

    test('returns null for valid password', () {
      expect(validatePassword('12345678'), isNull);
    });
  });

  group('validateName', () {
    test('returns error for empty name', () {
      expect(validateName(''), 'Informe seu nome');
    });

    test('returns null for valid name', () {
      expect(validateName('Maria'), isNull);
    });
  });
}
