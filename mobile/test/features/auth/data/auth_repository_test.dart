import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oriz/features/auth/data/auth_repository.dart';

class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  late MockGoTrueClient mockAuth;
  late AuthRepository repository;

  setUp(() {
    mockAuth = MockGoTrueClient();
    repository = AuthRepository(mockAuth);
  });

  group('signIn', () {
    test('calls signInWithPassword with email and password', () async {
      when(() => mockAuth.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => AuthResponse(
            session: null,
            user: null,
          ));

      await repository.signIn(
        email: 'test@example.com',
        password: 'password123',
      );

      verify(() => mockAuth.signInWithPassword(
            email: 'test@example.com',
            password: 'password123',
          )).called(1);
    });

    test('throws AuthException on invalid credentials', () async {
      when(() => mockAuth.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(AuthException('Invalid login credentials'));

      expect(
        () => repository.signIn(
          email: 'test@example.com',
          password: 'wrong',
        ),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('signUp', () {
    test('calls signUp with email, password, and full_name in data', () async {
      when(() => mockAuth.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
            data: any(named: 'data'),
          )).thenAnswer((_) async => AuthResponse(
            session: null,
            user: null,
          ));

      await repository.signUp(
        email: 'new@example.com',
        password: 'password123',
        fullName: 'Maria Silva',
      );

      verify(() => mockAuth.signUp(
            email: 'new@example.com',
            password: 'password123',
            data: {'full_name': 'Maria Silva'},
          )).called(1);
    });

    test('throws AuthException when email already exists', () async {
      when(() => mockAuth.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
            data: any(named: 'data'),
          )).thenThrow(AuthException('User already registered'));

      expect(
        () => repository.signUp(
          email: 'existing@example.com',
          password: 'password123',
          fullName: 'Ana',
        ),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('resetPassword', () {
    test('calls resetPasswordForEmail with email', () async {
      when(() => mockAuth.resetPasswordForEmail(
            any(),
          )).thenAnswer((_) async {});

      await repository.resetPassword(email: 'test@example.com');

      verify(() => mockAuth.resetPasswordForEmail('test@example.com')).called(1);
    });
  });

  group('signOut', () {
    test('calls signOut on GoTrueClient', () async {
      when(() => mockAuth.signOut()).thenAnswer((_) async {});

      await repository.signOut();

      verify(() => mockAuth.signOut()).called(1);
    });
  });

  group('currentSession', () {
    test('returns current session from GoTrueClient', () {
      when(() => mockAuth.currentSession).thenReturn(null);

      expect(repository.currentSession, isNull);

      verify(() => mockAuth.currentSession).called(1);
    });
  });

  group('onAuthStateChange', () {
    test('returns stream from GoTrueClient', () {
      final controller = StreamController<AuthState>();
      when(() => mockAuth.onAuthStateChange).thenAnswer((_) => controller.stream);

      expect(repository.onAuthStateChange, isA<Stream<AuthState>>());

      controller.close();
    });
  });
}
