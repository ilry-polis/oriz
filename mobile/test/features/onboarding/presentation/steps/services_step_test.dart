import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oriz/features/onboarding/data/onboarding_repository.dart';
import 'package:oriz/features/onboarding/presentation/steps/services_step.dart';
import 'package:oriz/features/onboarding/providers/onboarding_provider.dart';

class MockOnboardingRepository extends Mock implements OnboardingRepository {}

void main() {
  late MockOnboardingRepository mockRepo;

  setUp(() {
    mockRepo = MockOnboardingRepository();
    when(() => mockRepo.getGlobalCategories()).thenAnswer(
      (_) async => [
        const ServiceCategory(id: 'c1', name: 'Unhas'),
        const ServiceCategory(id: 'c2', name: 'Cilios'),
      ],
    );
  });

  Widget buildStep() {
    return ProviderScope(
      overrides: [
        onboardingRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: const MaterialApp(
        home: Scaffold(body: ServicesStep()),
      ),
    );
  }

  testWidgets('renders category chips', (tester) async {
    await tester.pumpWidget(buildStep());
    await tester.pumpAndSettle();

    expect(find.text('Unhas'), findsOneWidget);
    expect(find.text('Cilios'), findsOneWidget);
    expect(find.text('Cabelo'), findsOneWidget);
    expect(find.text('Micropigmentacao'), findsOneWidget);
  });

  testWidgets('selecting category shows templates', (tester) async {
    await tester.pumpWidget(buildStep());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Unhas'));
    await tester.pump();

    expect(find.text('Manicure'), findsOneWidget);
    expect(find.text('Pedicure'), findsOneWidget);
    expect(find.text('Esmaltacao em gel'), findsOneWidget);
  });

  testWidgets('shows custom service button', (tester) async {
    await tester.pumpWidget(buildStep());
    await tester.pumpAndSettle();

    expect(find.text('+ Servico personalizado'), findsOneWidget);
  });

  testWidgets('skip link present', (tester) async {
    await tester.pumpWidget(buildStep());
    await tester.pumpAndSettle();

    expect(find.text('Pular por agora'), findsOneWidget);
  });

  testWidgets('tapping custom adds empty card', (tester) async {
    await tester.pumpWidget(buildStep());
    await tester.pumpAndSettle();

    await tester.tap(find.text('+ Servico personalizado'));
    await tester.pump();

    expect(find.byIcon(Icons.close), findsOneWidget);
  });
}
