import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:oriz/features/auth/providers/auth_provider.dart';
import 'package:oriz/features/auth/presentation/signup_screen.dart';
import 'package:oriz/features/auth/data/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

Widget buildSignupScreen({
  required MockAuthRepository mockRepo,
  List<String> navigatedTo = const [],
}) {
  final router = GoRouter(
    initialLocation: '/signup',
    routes: [
      GoRoute(
        path: '/signup',
        builder: (_, __) => const SignupScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) {
          navigatedTo.add('/login');
          return const Scaffold(body: Text('Login'));
        },
      ),
      GoRoute(
        path: '/agenda',
        builder: (_, __) {
          navigatedTo.add('/agenda');
          return const Scaffold(body: Text('Agenda'));
        },
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
    testWidgets('shows name, email, and password fields', (tester) async {
      await tester.pumpWidget(buildSignupScreen(mockRepo: mockRepo));
      await tester.pumpAndSettle();

      expect(find.text('Nome completo'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Senha'), findsOneWidget);
    });

    testWidgets('shows Criar conta button', (tester) async {
      await tester.pumpWidget(buildSignupScreen(mockRepo: mockRepo));
      await tester.pumpAndSettle();

      expect(find.text('Criar conta'), findsWidgets); // button + app bar title
    });
  });

  group('validation', () {
    testWidgets('shows error when name is empty', (tester) async {
      await tester.pumpWidget(buildSignupScreen(mockRepo: mockRepo));
      await tester.pumpAndSettle();

      // Fill email and password but leave name empty
      await tester.enterText(find.byType(TextField).at(1), 'a@b.com');
      await tester.enterText(find.byType(TextField).at(2), 'password123');

      // Find and tap the submit button (ElevatedButton with "Criar conta")
      await tester.tap(find.widgetWithText(ElevatedButton, 'Criar conta'));
      await tester.pump();

      expect(find.text('Informe seu nome'), findsOneWidget);
    });

    testWidgets('shows error for invalid email', (tester) async {
      await tester.pumpWidget(buildSignupScreen(mockRepo: mockRepo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Maria');
      await tester.enterText(find.byType(TextField).at(1), 'bad-email');
      await tester.enterText(find.byType(TextField).at(2), 'password123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Criar conta'));
      await tester.pump();

      expect(find.text('Email invalido'), findsOneWidget);
    });

    testWidgets('shows error for short password', (tester) async {
      await tester.pumpWidget(buildSignupScreen(mockRepo: mockRepo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Maria');
      await tester.enterText(find.byType(TextField).at(1), 'a@b.com');
      await tester.enterText(find.byType(TextField).at(2), '123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Criar conta'));
      await tester.pump();

      expect(find.text('Minimo 8 caracteres'), findsOneWidget);
    });
  });

  group('error state', () {
    testWidgets('shows email already exists error', (tester) async {
      when(() => mockRepo.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
            fullName: any(named: 'fullName'),
          )).thenThrow(AuthException('User already registered'));

      await tester.pumpWidget(buildSignupScreen(mockRepo: mockRepo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Maria');
      await tester.enterText(find.byType(TextField).at(1), 'a@b.com');
      await tester.enterText(find.byType(TextField).at(2), 'password123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Criar conta'));
      await tester.pumpAndSettle();

      expect(find.text('Email ja cadastrado'), findsOneWidget);
    });
  });

  group('navigation', () {
    testWidgets('tapping Ja tem conta navigates to /login', (tester) async {
      final navigated = <String>[];
      await tester.pumpWidget(buildSignupScreen(
        mockRepo: mockRepo,
        navigatedTo: navigated,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Ja tem conta'));
      await tester.pumpAndSettle();

      expect(navigated, contains('/login'));
    });
  });
}
