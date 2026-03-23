import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:oriz/features/onboarding/presentation/onboarding_complete_screen.dart';

void main() {
  testWidgets('renders success message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OnboardingCompleteScreen(),
      ),
    );

    expect(find.text('Seu estudio esta pronto!'), findsOneWidget);
    expect(find.text('Agora voce pode agendar seus primeiros atendimentos.'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
  });

  testWidgets('has button to go to agenda', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OnboardingCompleteScreen(),
      ),
    );

    expect(find.text('Ir para Agenda'), findsOneWidget);
  });

  testWidgets('button navigates to /agenda', (tester) async {
    String? navigatedTo;

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/onboarding/complete',
          routes: [
            GoRoute(
              path: '/onboarding/complete',
              builder: (_, __) => const OnboardingCompleteScreen(),
            ),
            GoRoute(
              path: '/agenda',
              builder: (_, __) {
                navigatedTo = '/agenda';
                return const Scaffold(body: Text('Agenda'));
              },
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('Ir para Agenda'));
    await tester.pumpAndSettle();

    expect(navigatedTo, '/agenda');
  });
}
