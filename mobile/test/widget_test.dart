import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oriz/features/auth/data/auth_repository.dart';
import 'package:oriz/features/auth/providers/auth_provider.dart';
import 'package:oriz/main.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  testWidgets('App shows login screen when no session', (tester) async {
    final mockRepo = MockAuthRepository();
    when(() => mockRepo.currentSession).thenReturn(null);
    when(() => mockRepo.onAuthStateChange)
        .thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const OrizApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Entrar'), findsOneWidget);
  });
}
