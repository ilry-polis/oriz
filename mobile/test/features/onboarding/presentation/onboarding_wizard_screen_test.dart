import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oriz/features/onboarding/data/onboarding_repository.dart';
import 'package:oriz/features/onboarding/presentation/onboarding_wizard_screen.dart';
import 'package:oriz/features/onboarding/presentation/widgets/wizard_stepper.dart';

class MockOnboardingRepository extends Mock implements OnboardingRepository {}

void main() {
  late MockOnboardingRepository mockRepo;

  setUp(() {
    mockRepo = MockOnboardingRepository();
    when(() => mockRepo.getGlobalCategories()).thenAnswer((_) async => []);
  });

  Widget buildScreen() {
    return ProviderScope(
      overrides: [
        onboardingRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: const MaterialApp(
        home: OnboardingWizardScreen(),
      ),
    );
  }

  testWidgets('renders stepper and starts at step 1', (tester) async {
    when(() => mockRepo.getMyStudio()).thenAnswer((_) async => null);

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.byType(WizardStepper), findsOneWidget);
    expect(find.text('Dados do Estudio'), findsOneWidget);
  });

  testWidgets('shows loading indicator initially', (tester) async {
    when(() => mockRepo.getMyStudio()).thenAnswer(
      (_) => Future.delayed(const Duration(seconds: 2), () => null),
    );

    await tester.pumpWidget(buildScreen());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Clean up pending timer
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });

  testWidgets('resumes at step 2 when onboarding step is services', (tester) async {
    when(() => mockRepo.getMyStudio()).thenAnswer((_) async => const StudioInfo(
          studioId: 's1',
          studioName: 'Test',
          onboardingStep: 'services',
          professionalId: 'p1',
        ));

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('Servicos'), findsOneWidget);
  });
}
