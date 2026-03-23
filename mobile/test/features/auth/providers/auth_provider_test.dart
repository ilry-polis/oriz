import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:oriz/features/auth/providers/auth_provider.dart';
import 'package:oriz/features/auth/data/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class FakeUser extends Fake implements User {}

class FakeSession extends Fake implements Session {
  @override
  User get user => FakeUser();
}

void main() {
  late MockAuthRepository mockRepo;
  late ProviderContainer container;
  late Session fakeSession;

  setUp(() {
    mockRepo = MockAuthRepository();
    fakeSession = FakeSession();

    when(() => mockRepo.currentSession).thenReturn(null);
    when(() => mockRepo.onAuthStateChange).thenAnswer((_) => const Stream.empty());

    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('initial state is AuthUnauthenticated when no session', () {
    final state = container.read(authNotifierProvider);
    expect(state, isA<AuthUnauthenticated>());
  });

  group('signIn', () {
    test('transitions to AuthLoading then AuthAuthenticated on success', () async {
      when(() => mockRepo.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => AuthResponse(session: fakeSession, user: null));

      final notifier = container.read(authNotifierProvider.notifier);
      final states = <AuthStateData>[];
      container.listen(authNotifierProvider, (_, next) => states.add(next));

      await notifier.signIn(email: 'test@example.com', password: 'pass1234');

      expect(states, [isA<AuthLoading>(), isA<AuthAuthenticated>()]);
    });

    test('transitions to AuthError when session is null', () async {
      when(() => mockRepo.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => AuthResponse(session: null, user: null));

      final notifier = container.read(authNotifierProvider.notifier);
      final states = <AuthStateData>[];
      container.listen(authNotifierProvider, (_, next) => states.add(next));

      await notifier.signIn(email: 'test@example.com', password: 'pass1234');

      expect(states[1], isA<AuthError>());
    });

    test('transitions to AuthLoading then AuthError on failure', () async {
      when(() => mockRepo.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(AuthException('Invalid login credentials'));

      final notifier = container.read(authNotifierProvider.notifier);
      final states = <AuthStateData>[];
      container.listen(authNotifierProvider, (_, next) => states.add(next));

      await notifier.signIn(email: 'test@example.com', password: 'wrong');

      expect(states[0], isA<AuthLoading>());
      expect(states[1], isA<AuthError>());
      expect((states[1] as AuthError).message, 'Invalid login credentials');
    });

    test('increments failure count and rate limits after 3 failures', () async {
      when(() => mockRepo.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(AuthException('Invalid login credentials'));

      final notifier = container.read(authNotifierProvider.notifier);
      final states = <AuthStateData>[];
      container.listen(authNotifierProvider, (_, next) => states.add(next));

      await notifier.signIn(email: 'a@b.com', password: 'wrong');
      await notifier.signIn(email: 'a@b.com', password: 'wrong');
      await notifier.signIn(email: 'a@b.com', password: 'wrong');

      final lastError = states.last as AuthError;
      expect(lastError.rateLimited, isTrue);
    });
  });

  group('signUp', () {
    test('transitions to AuthAuthenticated on success', () async {
      when(() => mockRepo.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
            fullName: any(named: 'fullName'),
          )).thenAnswer((_) async => AuthResponse(session: fakeSession, user: null));

      final notifier = container.read(authNotifierProvider.notifier);
      final states = <AuthStateData>[];
      container.listen(authNotifierProvider, (_, next) => states.add(next));

      await notifier.signUp(email: 'new@example.com', password: 'pass1234', fullName: 'Maria');

      expect(states, [isA<AuthLoading>(), isA<AuthAuthenticated>()]);
    });

    test('transitions to AuthActionSuccess when session is null (email confirmation)', () async {
      when(() => mockRepo.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
            fullName: any(named: 'fullName'),
          )).thenAnswer((_) async => AuthResponse(session: null, user: null));

      final notifier = container.read(authNotifierProvider.notifier);
      final states = <AuthStateData>[];
      container.listen(authNotifierProvider, (_, next) => states.add(next));

      await notifier.signUp(email: 'new@example.com', password: 'pass1234', fullName: 'Maria');

      expect(states[1], isA<AuthActionSuccess>());
      expect((states[1] as AuthActionSuccess).message, contains('Verifique seu email'));
    });

    test('transitions to AuthError on email already exists', () async {
      when(() => mockRepo.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
            fullName: any(named: 'fullName'),
          )).thenThrow(AuthException('User already registered'));

      final notifier = container.read(authNotifierProvider.notifier);
      final states = <AuthStateData>[];
      container.listen(authNotifierProvider, (_, next) => states.add(next));

      await notifier.signUp(email: 'existing@example.com', password: 'pass1234', fullName: 'Ana');

      expect(states[1], isA<AuthError>());
      expect((states[1] as AuthError).message, 'User already registered');
    });
  });

  group('resetPassword', () {
    test('transitions to AuthActionSuccess on success', () async {
      when(() => mockRepo.resetPassword(email: any(named: 'email'))).thenAnswer((_) async {});

      final notifier = container.read(authNotifierProvider.notifier);
      final states = <AuthStateData>[];
      container.listen(authNotifierProvider, (_, next) => states.add(next));

      await notifier.resetPassword(email: 'test@example.com');

      expect(states, [isA<AuthLoading>(), isA<AuthActionSuccess>()]);
      expect((states[1] as AuthActionSuccess).message, 'Se o email existir, enviaremos instrucoes.');
    });
  });

  group('signOut', () {
    test('transitions to AuthUnauthenticated', () async {
      when(() => mockRepo.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => AuthResponse(session: fakeSession, user: null));
      when(() => mockRepo.signOut()).thenAnswer((_) async {});

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.signIn(email: 'a@b.com', password: 'pass1234');

      final states = <AuthStateData>[];
      container.listen(authNotifierProvider, (_, next) => states.add(next));

      await notifier.signOut();

      expect(states.last, isA<AuthUnauthenticated>());
    });
  });
}
