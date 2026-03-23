import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oriz/features/onboarding/presentation/widgets/wizard_stepper.dart';

void main() {
  Widget buildStepper({required int currentStep, void Function(int)? onStepTapped}) {
    return MaterialApp(
      home: Scaffold(
        body: WizardStepper(
          currentStep: currentStep,
          totalSteps: 3,
          onStepTapped: onStepTapped,
        ),
      ),
    );
  }

  testWidgets('renders 3 step circles', (tester) async {
    await tester.pumpWidget(buildStepper(currentStep: 0));

    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('marks current step as active', (tester) async {
    await tester.pumpWidget(buildStepper(currentStep: 1));

    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('marks completed steps with check icon', (tester) async {
    await tester.pumpWidget(buildStepper(currentStep: 2));

    expect(find.byIcon(Icons.check), findsNWidgets(2));
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('tapping completed step calls onStepTapped', (tester) async {
    int? tapped;
    await tester.pumpWidget(buildStepper(
      currentStep: 2,
      onStepTapped: (step) => tapped = step,
    ));

    await tester.tap(find.byIcon(Icons.check).first);
    expect(tapped, 0);
  });

  testWidgets('tapping inactive step does NOT call onStepTapped', (tester) async {
    int? tapped;
    await tester.pumpWidget(buildStepper(
      currentStep: 0,
      onStepTapped: (step) => tapped = step,
    ));

    await tester.tap(find.text('2'));
    expect(tapped, isNull);
  });
}
