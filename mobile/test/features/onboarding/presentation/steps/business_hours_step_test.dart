import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oriz/features/onboarding/data/onboarding_repository.dart';
import 'package:oriz/features/onboarding/presentation/steps/business_hours_step.dart';
import 'package:oriz/features/onboarding/presentation/widgets/day_hours_card.dart';

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
        home: Scaffold(body: BusinessHoursStep()),
      ),
    );
  }

  testWidgets('renders 7 day cards', (tester) async {
    await tester.pumpWidget(buildStep());

    expect(find.byType(DayHoursCard), findsNWidgets(7));
  });

  testWidgets('Mon-Sat enabled by default, Sun disabled', (tester) async {
    await tester.pumpWidget(buildStep());

    expect(find.byType(Switch), findsNWidgets(7));
    expect(find.text('Fechado'), findsOneWidget);
  });

  testWidgets('has Concluir button and skip link', (tester) async {
    await tester.pumpWidget(buildStep());

    expect(find.text('Concluir'), findsOneWidget);
    expect(find.text('Pular por agora'), findsOneWidget);
  });

  testWidgets('renders title and step label', (tester) async {
    await tester.pumpWidget(buildStep());

    expect(find.text('Horarios'), findsOneWidget);
    expect(find.text('Passo 3 de 3'), findsOneWidget);
  });
}
