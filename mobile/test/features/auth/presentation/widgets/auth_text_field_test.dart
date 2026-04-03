import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oriz/features/auth/presentation/widgets/auth_text_field.dart';

void main() {
  Widget buildTestWidget({
    String label = 'Email',
    String? errorText,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    TextEditingController? controller,
    bool enabled = true,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: AuthTextField(
          label: label,
          errorText: errorText,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          controller: controller,
          enabled: enabled,
        ),
      ),
    );
  }

  testWidgets('renders label text', (tester) async {
    await tester.pumpWidget(buildTestWidget(label: 'Senha'));
    expect(find.text('Senha'), findsOneWidget);
  });

  testWidgets('shows error text when provided', (tester) async {
    await tester.pumpWidget(buildTestWidget(errorText: 'Campo obrigatorio'));
    expect(find.text('Campo obrigatorio'), findsOneWidget);
  });

  testWidgets('does not show error when errorText is null', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    expect(find.text('Campo obrigatorio'), findsNothing);
  });

  testWidgets('obscures text when obscureText is true', (tester) async {
    final controller = TextEditingController(text: 'secret');
    await tester.pumpWidget(buildTestWidget(obscureText: true, controller: controller));
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
  });

  testWidgets('toggles password visibility on eye icon tap', (tester) async {
    final controller = TextEditingController(text: 'secret');
    await tester.pumpWidget(buildTestWidget(obscureText: true, controller: controller));
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pump();
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
  });

  testWidgets('disables input when enabled is false', (tester) async {
    await tester.pumpWidget(buildTestWidget(enabled: false));
    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.enabled, isFalse);
  });

  testWidgets('accepts text input', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(buildTestWidget(controller: controller));
    await tester.enterText(find.byType(TextField), 'hello@test.com');
    expect(controller.text, 'hello@test.com');
  });
}
