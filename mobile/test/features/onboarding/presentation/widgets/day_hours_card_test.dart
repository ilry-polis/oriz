import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oriz/features/onboarding/presentation/widgets/day_hours_card.dart';

void main() {
  Widget buildCard({
    String dayLabel = 'Seg',
    bool enabled = true,
    List<TimeRange>? ranges,
    void Function(bool enabled, List<TimeRange> ranges)? onChanged,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: DayHoursCard(
          dayLabel: dayLabel,
          enabled: enabled,
          ranges: ranges ?? [const TimeRange(open: '09:00', close: '18:00')],
          onChanged: onChanged ?? (_, __) {},
        ),
      ),
    );
  }

  testWidgets('renders day label and toggle', (tester) async {
    await tester.pumpWidget(buildCard());

    expect(find.text('Seg'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
  });

  testWidgets('shows time range when enabled', (tester) async {
    await tester.pumpWidget(buildCard(enabled: true));

    expect(find.text('09:00'), findsWidgets);
    expect(find.text('18:00'), findsWidgets);
  });

  testWidgets('shows Fechado when disabled', (tester) async {
    await tester.pumpWidget(buildCard(enabled: false));

    expect(find.text('Fechado'), findsOneWidget);
  });

  testWidgets('toggle calls onChanged with enabled=false', (tester) async {
    bool? newEnabled;
    await tester.pumpWidget(buildCard(
      enabled: true,
      onChanged: (enabled, _) => newEnabled = enabled,
    ));

    await tester.tap(find.byType(Switch));
    expect(newEnabled, isFalse);
  });

  testWidgets('add interval button present when enabled', (tester) async {
    await tester.pumpWidget(buildCard(enabled: true));

    expect(find.text('+ Intervalo'), findsOneWidget);
  });

  testWidgets('add interval calls onChanged with new range', (tester) async {
    List<TimeRange>? newRanges;
    await tester.pumpWidget(buildCard(
      enabled: true,
      ranges: [const TimeRange(open: '09:00', close: '18:00')],
      onChanged: (_, ranges) => newRanges = ranges,
    ));

    await tester.tap(find.text('+ Intervalo'));
    expect(newRanges, hasLength(2));
  });
}
