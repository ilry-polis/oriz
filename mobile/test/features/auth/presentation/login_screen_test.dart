import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:oriz/features/auth/providers/auth_provider.dart';
import 'package:oriz/features/auth/presentation/login_screen.dart';
import 'package:oriz/features/auth/data/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

Widget buildLoginScreen({
  required MockAuthRepository mockRepo,
  List<String> navigatedTo = const [],
}) {
  final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, __) { navigatedTo.add('/signup'); return const Scaffold(body: Text('Signup')); }),
      GoRoute(path: '/forgot-password', builder: (_, __) { navigatedTo.add('/forgot-password'); return const Scaffold(body: Text('ForgotPassword')); }),
    ],
  );
  return ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(mockRepo)],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  late MockAuthRepository mockRepo;

  setUp(() {
    mockRepo = MockAuthRepository();
    when(() => mockRepo.currentSession).thenReturn(null);
    when(() => mockRepo.onAuthStateChange).thenAnswer((_) => const Stream.empty());
  });

  group('rendering', () {
    testWidgets('shows email and password fields', (tester) async {
      await tester.pumpWidget(buildLoginScreen(mockRepo: mockRepo));
      await tester.pumpAndSettle();
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Senha'), findsOneWidget);
    });

    testWidgets('shows Entrar button', (tester) async {
      await tester.pumpWidget(buildLoginScreen(mockRepo: mockRepo));
      await tester.pumpAndSettle();
      expect(find.text('Entrar'), findsOneWidget);
    });

    testWidgets('shows navigation links', (tester) async {
      await tester.pumpWidget(buildLoginScreen(mockRepo: mockRepo));
      await tester.pumpAndSettle();
      expect(find.text('Criar conta'), findsOneWidget);
      expect(find.text('Esqueci senha'), findsOneWidget);
    });
  });

  group('validation', () {
    testWidgets('shows error when email is empty on submit', (tester) async {
      await tester.pumpWidget(buildLoginScreen(mockRepo: mockRepo));
      await tester.pumpAndSettle();
      // Leave email empty, enter password
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      await tester.tap(find.text('Entrar'));
      await tester.pump();
      expect(find.text('Informe seu email'), findsOneWidget);
    });

    testWidgets('shows error for invalid email format', (tester) async {
      await tester.pumpWidget(buildLoginScreen(mockRepo: mockRepo));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'not-an-email');
      await tester.enterText(find.byType(TextField).last, 'password123');
      await tester.tap(find.text('Entrar'));
      await tester.pump();
      expect(find.text('Email invalido'), findsOneWidget);
    });

    testWidgets('shows error when password is too short', (tester) async {
      await tester.pumpWidget(buildLoginScreen(mockRepo: mockRepo));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'a@b.com');
      await tester.enterText(find.byType(TextField).last, '123');
      await tester.tap(find.text('Entrar'));
      await tester.pump();
      expect(find.text('Minimo 8 caracteres'), findsOneWidget);
    });
  });

  group('loading state', () {
    testWidgets('shows spinner during loading', (tester) async {
      // Use a completer that never completes during this test to keep loading state
      final completer = Completer<AuthResponse>();
      when(() => mockRepo.signIn(email: any(named: 'email'), password: any(named: 'password')))
          .thenAnswer((_) => completer.future);
      await tester.pumpWidget(buildLoginScreen(mockRepo: mockRepo));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'a@b.com');
      await tester.enterText(find.byType(TextField).last, 'password123');
      await tester.tap(find.text('Entrar'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Complete with a non-null session stub to allow clean teardown
      completer.completeError(AuthException('cancelled'));
      await tester.pumpAndSettle();
    });
  });

  group('error state', () {
    testWidgets('shows error message after failed login', (tester) async {
      when(() => mockRepo.signIn(email: any(named: 'email'), password: any(named: 'password')))
          .thenThrow(AuthException('Invalid login credentials'));
      await tester.pumpWidget(buildLoginScreen(mockRepo: mockRepo));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'a@b.com');
      await tester.enterText(find.byType(TextField).last, 'password123');
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Email ou senha incorretos'), findsOneWidget);
    });
  });

  group('navigation', () {
    testWidgets('tapping Criar conta navigates to /signup', (tester) async {
      final navigated = <String>[];
      await tester.pumpWidget(buildLoginScreen(mockRepo: mockRepo, navigatedTo: navigated));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Criar conta'));
      await tester.pumpAndSettle();
      expect(navigated, contains('/signup'));
    });

    testWidgets('tapping Esqueci senha navigates to /forgot-password', (tester) async {
      final navigated = <String>[];
      await tester.pumpWidget(buildLoginScreen(mockRepo: mockRepo, navigatedTo: navigated));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Esqueci senha'));
      await tester.pumpAndSettle();
      expect(navigated, contains('/forgot-password'));
    });
  });
}
