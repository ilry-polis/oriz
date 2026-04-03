import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:oriz/features/auth/providers/auth_provider.dart';
import 'package:oriz/features/auth/presentation/forgot_password_screen.dart';
import 'package:oriz/features/auth/data/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

Widget buildForgotPasswordScreen({
  required MockAuthRepository mockRepo,
}) {
  final router = GoRouter(
    initialLocation: '/forgot-password',
    routes: [
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const Scaffold(body: Text('Login')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(mockRepo),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  late MockAuthRepository mockRepo;

  setUp(() {
    mockRepo = MockAuthRepository();
    when(() => mockRepo.currentSession).thenReturn(null);
    when(() => mockRepo.onAuthStateChange)
        .thenAnswer((_) => const Stream.empty());
  });

  group('rendering', () {
    testWidgets('shows email field and submit button', (tester) async {
      await tester.pumpWidget(buildForgotPasswordScreen(mockRepo: mockRepo));
      await tester.pumpAndSettle();

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Enviar instrucoes'), findsOneWidget);
    });

    testWidgets('shows descriptive text', (tester) async {
      await tester.pumpWidget(buildForgotPasswordScreen(mockRepo: mockRepo));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Informe seu email'),
        findsOneWidget,
      );
    });
  });

  group('validation', () {
    testWidgets('shows error when email is empty', (tester) async {
      await tester.pumpWidget(buildForgotPasswordScreen(mockRepo: mockRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Enviar instrucoes'));
      await tester.pump();

      expect(find.text('Informe seu email'), findsWidgets);
    });
  });

  group('success state', () {
    testWidgets('shows generic success message', (tester) async {
      when(() => mockRepo.resetPassword(email: any(named: 'email')))
          .thenAnswer((_) async {});

      await tester.pumpWidget(buildForgotPasswordScreen(mockRepo: mockRepo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'a@b.com');
      await tester.tap(find.text('Enviar instrucoes'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Se o email existir'),
        findsOneWidget,
      );
    });

    testWidgets('shows same message even for non-existent email',
        (tester) async {
      // Even if Supabase throws, we show success to prevent enumeration
      when(() => mockRepo.resetPassword(email: any(named: 'email')))
          .thenThrow(AuthException('User not found'));

      await tester.pumpWidget(buildForgotPasswordScreen(mockRepo: mockRepo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'nobody@example.com');
      await tester.tap(find.text('Enviar instrucoes'));
      await tester.pumpAndSettle();

      // Must still show generic success — never reveal if email exists
      expect(
        find.textContaining('Se o email existir'),
        findsOneWidget,
      );
    });
  });
}
