import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oriz/features/onboarding/presentation/widgets/service_template_card.dart';

void main() {
  Widget buildCard({
    String name = 'Manicure',
    int durationMinutes = 30,
    int price = 5000,
    VoidCallback? onRemove,
    void Function(String name, int duration, int price)? onChanged,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ServiceTemplateCard(
          name: name,
          durationMinutes: durationMinutes,
          price: price,
          onRemove: onRemove ?? () {},
          onChanged: onChanged ?? (_, __, ___) {},
        ),
      ),
    );
  }

  testWidgets('renders name, duration, and formatted price', (tester) async {
    await tester.pumpWidget(buildCard());

    expect(find.text('Manicure'), findsOneWidget);
    expect(find.text('30 min'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'R\$ 50,00'), findsOneWidget);
  });

  testWidgets('remove button calls onRemove', (tester) async {
    bool removed = false;
    await tester.pumpWidget(buildCard(onRemove: () => removed = true));

    await tester.tap(find.byIcon(Icons.close));
    expect(removed, isTrue);
  });

  testWidgets('editing name calls onChanged', (tester) async {
    String? newName;
    await tester.pumpWidget(buildCard(
      onChanged: (name, _, __) => newName = name,
    ));

    final nameField = find.widgetWithText(TextField, 'Manicure');
    await tester.enterText(nameField, 'Manicure Gel');
    await tester.pump();

    expect(newName, 'Manicure Gel');
  });
}
