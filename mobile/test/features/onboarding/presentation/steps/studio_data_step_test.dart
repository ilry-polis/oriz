import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oriz/features/onboarding/data/onboarding_repository.dart';
import 'package:oriz/features/onboarding/presentation/steps/studio_data_step.dart';
import 'package:oriz/features/onboarding/providers/onboarding_provider.dart';

class MockOnboardingRepository extends Mock implements OnboardingRepository {}

void main() {
  late MockOnboardingRepository mockRepo;

  setUp(() {
    mockRepo = MockOnboardingRepository();
  });

  Widget buildStep() {
    return ProviderScope(
      overrides: [
        onboardingRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: const MaterialApp(
        home: Scaffold(body: StudioDataStep()),
      ),
    );
  }

  testWidgets('renders all form fields', (tester) async {
    await tester.pumpWidget(buildStep());

    expect(find.text('Nome do estudio'), findsOneWidget);
    expect(find.text('URL publica'), findsOneWidget);
    expect(find.text('Telefone'), findsOneWidget);
    expect(find.text('Endereco'), findsOneWidget);
    expect(find.text('Fuso horario'), findsOneWidget);
    expect(find.text('Proximo'), findsOneWidget);
  });

  testWidgets('validates name is required', (tester) async {
    await tester.pumpWidget(buildStep());

    await tester.tap(find.text('Proximo'));
    await tester.pump();

    expect(find.text('Nome e obrigatorio'), findsOneWidget);
  });

  testWidgets('auto-generates slug from name', (tester) async {
    await tester.pumpWidget(buildStep());

    // Find the first TextField (name field)
    final nameFields = find.byType(TextField);
    await tester.enterText(nameFields.first, 'Studio da Maria');
    await tester.pump();

    // The slug field should contain a slugified version
    final slugField = find.byKey(const Key('slug_field'));
    expect(slugField, findsOneWidget);
    final slugTextField = tester.widget<TextField>(
      find.descendant(of: slugField, matching: find.byType(TextField)),
    );
    expect(slugTextField.controller?.text, 'studio-da-maria');
  });

  testWidgets('shows loading spinner when saving', (tester) async {
    final completer = Completer<StudioInfo>();

    when(() => mockRepo.getMyStudio()).thenAnswer((_) async => null);
    when(() => mockRepo.createStudio(
          name: any(named: 'name'),
          slug: any(named: 'slug'),
          phone: any(named: 'phone'),
          address: any(named: 'address'),
          timezone: any(named: 'timezone'),
        )).thenAnswer((_) => completer.future);
    when(() => mockRepo.updateOnboardingStep(any())).thenAnswer((_) async {});

    await tester.pumpWidget(buildStep());

    // Initialize the provider to OnboardingStep(currentStep: 0)
    final container = ProviderScope.containerOf(
      tester.element(find.byType(StudioDataStep)),
    );
    await container.read(onboardingNotifierProvider.notifier).init();
    await tester.pump();

    // Fill required name field
    final nameFields = find.byType(TextField);
    await tester.enterText(nameFields.first, 'Test Studio');
    await tester.pump();

    await tester.tap(find.text('Proximo'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Complete the future to clean up
    completer.complete(const StudioInfo(
      studioId: 's1',
      studioName: 'Test',
      onboardingStep: 'studio_data',
      professionalId: 'p1',
    ));
    await tester.pumpAndSettle();
  });
}
