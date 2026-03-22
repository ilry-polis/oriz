import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oriz/core/router/app_router.dart';
import 'package:oriz/features/auth/providers/auth_provider.dart';
import 'package:oriz/features/auth/data/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepo;

  setUp(() {
    mockRepo = MockAuthRepository();
    when(() => mockRepo.onAuthStateChange)
        .thenAnswer((_) => const Stream.empty());
  });

  Widget buildApp({required bool hasSession}) {
    when(() => mockRepo.currentSession).thenReturn(
      hasSession ? _FakeSession() : null,
    );

    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          final router = ref.watch(routerProvider);
          return MaterialApp.router(routerConfig: router);
        },
      ),
    );
  }

  testWidgets('redirects to /login when no session', (tester) async {
    await tester.pumpWidget(buildApp(hasSession: false));
    await tester.pumpAndSettle();

    // Should see LoginScreen content
    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets('redirects to /agenda when session exists', (tester) async {
    await tester.pumpWidget(buildApp(hasSession: true));
    await tester.pumpAndSettle();

    // Should see Agenda content (bottom nav label)
    expect(find.text('Agenda'), findsWidgets);
  });
}

// Minimal fake for Session — just needs to be non-null
class _FakeSession implements Session {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
