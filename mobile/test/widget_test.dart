import 'package:flutter_test/flutter_test.dart';
import 'package:oriz/main.dart';

void main() {
  testWidgets('App renders AgendaDayScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const OrizApp());

    // Pump through the simulated loading delay
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Agenda'), findsWidgets);
  });
}
