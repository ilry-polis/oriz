import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oriz/core/router/app_router.dart';
import 'package:oriz/features/auth/data/auth_repository.dart';
import 'package:oriz/features/auth/providers/auth_provider.dart';
import 'package:oriz/features/onboarding/data/onboarding_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

class MockAuthRepository extends Mock implements AuthRepository {}

class MockOnboardingRepository extends Mock implements OnboardingRepository {}

class _FakeSession implements Session {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockAuthRepository mockAuth;
  late MockOnboardingRepository mockOnboarding;

  setUp(() {
    mockAuth = MockAuthRepository();
    mockOnboarding = MockOnboardingRepository();
    when(() => mockAuth.onAuthStateChange).thenAnswer((_) => const Stream.empty());
  });

  Widget buildApp({required bool hasSession}) {
    when(() => mockAuth.currentSession).thenReturn(
      hasSession ? _FakeSession() : null,
    );

    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuth),
        onboardingRepositoryProvider.overrideWithValue(mockOnboarding),
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

    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets('redirects authenticated user without studio to /onboarding', (tester) async {
    when(() => mockOnboarding.getMyStudio()).thenAnswer((_) async => null);
    when(() => mockOnboarding.getServiceCategories()).thenAnswer((_) async => []);

    await tester.pumpWidget(buildApp(hasSession: true));
    // Let microtasks resolve: checkStudio → noStudio → redirect → onboarding init
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Should not be on login (redirected to onboarding)
    expect(find.text('Entrar'), findsNothing);
    // OnboardingWizardScreen should be showing (either loading or step 1)
    expect(find.text('Dados do Estudio'), findsOneWidget);
  });

  testWidgets('redirects to /agenda when session exists and onboarding complete', (tester) async {
    when(() => mockOnboarding.getMyStudio()).thenAnswer(
      (_) async => const StudioInfo(
        studioId: 's1',
        studioName: 'Test',
        onboardingStep: 'complete',
        professionalId: 'p1',
      ),
    );

    await tester.pumpWidget(buildApp(hasSession: true));
    await tester.pumpAndSettle();

    expect(find.text('Agenda'), findsWidgets);
  });
}
