# Flutter Auth Screens Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build Login, Signup, and ForgotPassword screens in Flutter with Supabase Auth integration, TDD-first.

**Architecture:** Flutter → Riverpod Provider → AuthRepository → Supabase Auth SDK. GoRouter handles auth redirects based on session state. Screens follow existing design system tokens (AppColors, AppTypography, AppSpacing).

**Tech Stack:** Flutter 3.11+, supabase_flutter 2.x, flutter_riverpod 3.x, go_router 17.x, mocktail 1.x

**Spec:** `docs/superpowers/specs/2026-03-22-flutter-auth-screens-design.md`

**Reference files:**
- Design tokens: `mobile/lib/core/theme/app_colors.dart`, `app_typography.dart`, `app_spacing.dart`
- Reference screen: `mobile/lib/features/agenda/agenda_day_screen.dart`
- Current main: `mobile/lib/main.dart` (MaterialApp + AppShell with IndexedStack)

---

## Task 1: Add Dependencies

**Files:**
- Modify: `mobile/pubspec.yaml`

- [ ] **Step 1: Add packages**

Add to `dependencies` section of `mobile/pubspec.yaml`:
```yaml
  supabase_flutter: ^2.0.0
  flutter_riverpod: ^3.3.1
  go_router: ^17.1.0
```

Add to `dev_dependencies`:
```yaml
  mocktail: ^1.0.4
```

- [ ] **Step 2: Install**

Run: `cd mobile && flutter pub get`
Expected: "Resolving dependencies..." followed by success

- [ ] **Step 3: Commit**

```bash
git add mobile/pubspec.yaml mobile/pubspec.lock
git commit -m "chore: add supabase_flutter, riverpod, go_router, mocktail"
```

---

## Task 2: Supabase Config

**Files:**
- Create: `mobile/lib/core/supabase/supabase_config.dart`

- [ ] **Step 1: Create Supabase init wrapper**

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

/// Initialize Supabase SDK. Call once in main() before runApp().
Future<void> initSupabase({
  required String url,
  required String anonKey,
}) async {
  await Supabase.initialize(
    url: url,
    anonKey: anonKey,
  );
}

/// Shorthand to access the Supabase client singleton.
SupabaseClient get supabase => Supabase.instance.client;
```

- [ ] **Step 2: Create .env.example for reference**

Create `mobile/.env.example`:
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

Note: Actual env values will be passed via `--dart-define` at build time or read from a `.env` file. For now, hardcode dev values in main.dart during development (will be replaced by proper env management later).

- [ ] **Step 3: Commit**

```bash
git add mobile/lib/core/supabase/supabase_config.dart mobile/.env.example
git commit -m "feat: supabase config wrapper and env template"
```

---

## Task 3: AuthRepository — TDD

**Files:**
- Test: `mobile/test/features/auth/data/auth_repository_test.dart`
- Create: `mobile/lib/features/auth/data/auth_repository.dart`

- [ ] **Step 1: Write failing tests**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oriz/features/auth/data/auth_repository.dart';

class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  late MockGoTrueClient mockAuth;
  late AuthRepository repository;

  setUp(() {
    mockAuth = MockGoTrueClient();
    repository = AuthRepository(mockAuth);
  });

  group('signIn', () {
    test('calls signInWithPassword with email and password', () async {
      when(() => mockAuth.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => AuthResponse(
            session: null,
            user: null,
          ));

      await repository.signIn(
        email: 'test@example.com',
        password: 'password123',
      );

      verify(() => mockAuth.signInWithPassword(
            email: 'test@example.com',
            password: 'password123',
          )).called(1);
    });

    test('throws AuthException on invalid credentials', () async {
      when(() => mockAuth.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(AuthException('Invalid login credentials'));

      expect(
        () => repository.signIn(
          email: 'test@example.com',
          password: 'wrong',
        ),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('signUp', () {
    test('calls signUp with email, password, and full_name in data', () async {
      when(() => mockAuth.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
            data: any(named: 'data'),
          )).thenAnswer((_) async => AuthResponse(
            session: null,
            user: null,
          ));

      await repository.signUp(
        email: 'new@example.com',
        password: 'password123',
        fullName: 'Maria Silva',
      );

      verify(() => mockAuth.signUp(
            email: 'new@example.com',
            password: 'password123',
            data: {'full_name': 'Maria Silva'},
          )).called(1);
    });

    test('throws AuthException when email already exists', () async {
      when(() => mockAuth.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
            data: any(named: 'data'),
          )).thenThrow(AuthException('User already registered'));

      expect(
        () => repository.signUp(
          email: 'existing@example.com',
          password: 'password123',
          fullName: 'Ana',
        ),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('resetPassword', () {
    test('calls resetPasswordForEmail with email', () async {
      when(() => mockAuth.resetPasswordForEmail(
            any(),
          )).thenAnswer((_) async {});

      await repository.resetPassword(email: 'test@example.com');

      verify(() => mockAuth.resetPasswordForEmail('test@example.com')).called(1);
    });
  });

  group('signOut', () {
    test('calls signOut on GoTrueClient', () async {
      when(() => mockAuth.signOut()).thenAnswer((_) async {});

      await repository.signOut();

      verify(() => mockAuth.signOut()).called(1);
    });
  });

  group('currentSession', () {
    test('returns current session from GoTrueClient', () {
      when(() => mockAuth.currentSession).thenReturn(null);

      expect(repository.currentSession, isNull);

      verify(() => mockAuth.currentSession).called(1);
    });
  });

  group('onAuthStateChange', () {
    test('returns stream from GoTrueClient', () {
      final controller = StreamController<AuthState>();
      when(() => mockAuth.onAuthStateChange).thenReturn(controller.stream);

      expect(repository.onAuthStateChange, isA<Stream<AuthState>>());

      controller.close();
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd mobile && flutter test test/features/auth/data/auth_repository_test.dart`
Expected: FAIL — `auth_repository.dart` does not exist yet

- [ ] **Step 3: Write minimal implementation**

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final GoTrueClient _auth;

  AuthRepository(this._auth);

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) {
    return _auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }

  Future<void> resetPassword({required String email}) {
    return _auth.resetPasswordForEmail(email);
  }

  Future<void> signOut() {
    return _auth.signOut();
  }

  Session? get currentSession => _auth.currentSession;

  Stream<AuthState> get onAuthStateChange => _auth.onAuthStateChange;
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd mobile && flutter test test/features/auth/data/auth_repository_test.dart`
Expected: All tests PASS

- [ ] **Step 5: Commit**

```bash
git add mobile/test/features/auth/data/auth_repository_test.dart mobile/lib/features/auth/data/auth_repository.dart
git commit -m "feat: AuthRepository with TDD — wraps Supabase GoTrueClient"
```

---

## Task 4: Auth Provider — TDD

**Files:**
- Test: `mobile/test/features/auth/providers/auth_provider_test.dart`
- Create: `mobile/lib/features/auth/providers/auth_provider.dart`

- [ ] **Step 1: Write failing tests**

```dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:oriz/features/auth/providers/auth_provider.dart';
import 'package:oriz/features/auth/data/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class FakeSession extends Fake implements Session {}

void main() {
  late MockAuthRepository mockRepo;
  late ProviderContainer container;
  late Session fakeSession;

  setUp(() {
    mockRepo = MockAuthRepository();
    fakeSession = FakeSession();

    // Default: no active session, empty auth stream
    when(() => mockRepo.currentSession).thenReturn(null);
    when(() => mockRepo.onAuthStateChange).thenReturn(const Stream.empty());

    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('initial state is AuthUnauthenticated when no session', () {
    final state = container.read(authNotifierProvider);
    expect(state, isA<AuthUnauthenticated>());
  });

  group('signIn', () {
    test('transitions to AuthLoading then AuthAuthenticated on success',
        () async {
      when(() => mockRepo.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => AuthResponse(
            session: fakeSession,
            user: null,
          ));

      final notifier = container.read(authNotifierProvider.notifier);

      final states = <AuthStateData>[];
      container.listen(authNotifierProvider, (_, next) => states.add(next));

      await notifier.signIn(email: 'test@example.com', password: 'pass1234');

      expect(states, [
        isA<AuthLoading>(),
        isA<AuthAuthenticated>(),
      ]);
    });

    test('transitions to AuthLoading then AuthError on failure', () async {
      when(() => mockRepo.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(AuthException('Invalid login credentials'));

      final notifier = container.read(authNotifierProvider.notifier);

      final states = <AuthStateData>[];
      container.listen(authNotifierProvider, (_, next) => states.add(next));

      await notifier.signIn(email: 'test@example.com', password: 'wrong');

      expect(states[0], isA<AuthLoading>());
      expect(states[1], isA<AuthError>());
      expect((states[1] as AuthError).message, 'Invalid login credentials');
    });

    test('increments failure count and rate limits after 3 failures', () async {
      when(() => mockRepo.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(AuthException('Invalid login credentials'));

      final notifier = container.read(authNotifierProvider.notifier);

      final states = <AuthStateData>[];
      container.listen(authNotifierProvider, (_, next) => states.add(next));

      // 3 failed attempts
      await notifier.signIn(email: 'a@b.com', password: 'wrong');
      await notifier.signIn(email: 'a@b.com', password: 'wrong');
      await notifier.signIn(email: 'a@b.com', password: 'wrong');

      final lastError = states.last as AuthError;
      expect(lastError.rateLimited, isTrue);
    });
  });

  group('signUp', () {
    test('transitions to AuthAuthenticated on success', () async {
      when(() => mockRepo.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
            fullName: any(named: 'fullName'),
          )).thenAnswer((_) async => AuthResponse(
            session: fakeSession,
            user: null,
          ));

      final notifier = container.read(authNotifierProvider.notifier);

      final states = <AuthStateData>[];
      container.listen(authNotifierProvider, (_, next) => states.add(next));

      await notifier.signUp(
        email: 'new@example.com',
        password: 'pass1234',
        fullName: 'Maria',
      );

      expect(states, [
        isA<AuthLoading>(),
        isA<AuthAuthenticated>(),
      ]);
    });

    test('transitions to AuthError on email already exists', () async {
      when(() => mockRepo.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
            fullName: any(named: 'fullName'),
          )).thenThrow(AuthException('User already registered'));

      final notifier = container.read(authNotifierProvider.notifier);

      final states = <AuthStateData>[];
      container.listen(authNotifierProvider, (_, next) => states.add(next));

      await notifier.signUp(
        email: 'existing@example.com',
        password: 'pass1234',
        fullName: 'Ana',
      );

      expect(states[1], isA<AuthError>());
      expect(
        (states[1] as AuthError).message,
        'User already registered',
      );
    });
  });

  group('resetPassword', () {
    test('transitions to AuthActionSuccess on success', () async {
      when(() => mockRepo.resetPassword(email: any(named: 'email')))
          .thenAnswer((_) async {});

      final notifier = container.read(authNotifierProvider.notifier);

      final states = <AuthStateData>[];
      container.listen(authNotifierProvider, (_, next) => states.add(next));

      await notifier.resetPassword(email: 'test@example.com');

      expect(states, [
        isA<AuthLoading>(),
        isA<AuthActionSuccess>(),
      ]);
      expect(
        (states[1] as AuthActionSuccess).message,
        'Se o email existir, enviaremos instrucoes.',
      );
    });
  });

  group('signOut', () {
    test('transitions to AuthUnauthenticated', () async {
      // Start authenticated
      when(() => mockRepo.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => AuthResponse(
            session: fakeSession,
            user: null,
          ));
      when(() => mockRepo.signOut()).thenAnswer((_) async {});

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.signIn(email: 'a@b.com', password: 'pass1234');

      final states = <AuthStateData>[];
      container.listen(authNotifierProvider, (_, next) => states.add(next));

      await notifier.signOut();

      expect(states.last, isA<AuthUnauthenticated>());
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd mobile && flutter test test/features/auth/providers/auth_provider_test.dart`
Expected: FAIL — `auth_provider.dart` does not exist yet

- [ ] **Step 3: Write minimal implementation**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../data/auth_repository.dart';

// ─── State ────────────────────────────────────────────────
sealed class AuthStateData {
  const AuthStateData();
}

class AuthUnauthenticated extends AuthStateData {
  const AuthUnauthenticated();
}

class AuthLoading extends AuthStateData {
  const AuthLoading();
}

class AuthAuthenticated extends AuthStateData {
  final Session session;
  const AuthAuthenticated(this.session);
}

class AuthError extends AuthStateData {
  final String message;
  final bool rateLimited;
  final DateTime? rateLimitedUntil;
  const AuthError(this.message, {this.rateLimited = false, this.rateLimitedUntil});
}

class AuthActionSuccess extends AuthStateData {
  final String message;
  const AuthActionSuccess(this.message);
}

// ─── Provider ─────────────────────────────────────────────
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  throw UnimplementedError(
    'authRepositoryProvider must be overridden with a real AuthRepository',
  );
});

final authNotifierProvider =
    NotifierProvider<AuthNotifier, AuthStateData>(AuthNotifier.new);

class AuthNotifier extends Notifier<AuthStateData> {
  int _failureCount = 0;

  @override
  AuthStateData build() {
    final repo = ref.read(authRepositoryProvider);
    final session = repo.currentSession;
    return session != null
        ? AuthAuthenticated(session)
        : const AuthUnauthenticated();
  }

  /// True if within the 30-second cooldown after 3 failed attempts.
  bool get isRateLimited {
    final s = state;
    if (s is AuthError && s.rateLimitedUntil != null) {
      return DateTime.now().isBefore(s.rateLimitedUntil!);
    }
    return false;
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    if (isRateLimited) return;

    state = const AuthLoading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final response = await repo.signIn(email: email, password: password);
      _failureCount = 0;
      state = AuthAuthenticated(response.session!);
    } on AuthException catch (e) {
      _failureCount++;
      final limited = _failureCount >= 3;
      state = AuthError(
        e.message,
        rateLimited: limited,
        rateLimitedUntil: limited
            ? DateTime.now().add(const Duration(seconds: 30))
            : null,
      );
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = const AuthLoading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final response = await repo.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );
      state = AuthAuthenticated(response.session!);
    } on AuthException catch (e) {
      state = AuthError(e.message);
    }
  }

  Future<void> resetPassword({required String email}) async {
    state = const AuthLoading();
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.resetPassword(email: email);
      state = const AuthActionSuccess(
        'Se o email existir, enviaremos instrucoes.',
      );
    } on AuthException catch (e) {
      // Always show success to prevent email enumeration
      state = const AuthActionSuccess(
        'Se o email existir, enviaremos instrucoes.',
      );
    }
  }

  Future<void> signOut() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.signOut();
    _failureCount = 0;
    state = const AuthUnauthenticated();
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd mobile && flutter test test/features/auth/providers/auth_provider_test.dart`
Expected: All tests PASS

- [ ] **Step 5: Commit**

```bash
git add mobile/test/features/auth/providers/auth_provider_test.dart mobile/lib/features/auth/providers/auth_provider.dart
git commit -m "feat: auth provider with Riverpod — state machine + rate limit"
```

---

## Task 5: AuthTextField Widget — TDD

**Files:**
- Test: `mobile/test/features/auth/presentation/widgets/auth_text_field_test.dart`
- Create: `mobile/lib/features/auth/presentation/widgets/auth_text_field.dart`

- [ ] **Step 1: Write failing tests**

```dart
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
    await tester.pumpWidget(buildTestWidget(
      errorText: 'Campo obrigatorio',
    ));
    expect(find.text('Campo obrigatorio'), findsOneWidget);
  });

  testWidgets('does not show error when errorText is null', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    expect(find.text('Campo obrigatorio'), findsNothing);
  });

  testWidgets('obscures text when obscureText is true', (tester) async {
    final controller = TextEditingController(text: 'secret');
    await tester.pumpWidget(buildTestWidget(
      obscureText: true,
      controller: controller,
    ));

    // Password visibility toggle icon should be present
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
  });

  testWidgets('toggles password visibility on eye icon tap', (tester) async {
    final controller = TextEditingController(text: 'secret');
    await tester.pumpWidget(buildTestWidget(
      obscureText: true,
      controller: controller,
    ));

    // Initially obscured — visibility_off icon
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

    // Tap to reveal
    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pump();

    // Now showing — visibility icon
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd mobile && flutter test test/features/auth/presentation/widgets/auth_text_field_test.dart`
Expected: FAIL — `auth_text_field.dart` does not exist

- [ ] **Step 3: Write minimal implementation**

```dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class AuthTextField extends StatefulWidget {
  final String label;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextEditingController? controller;
  final bool enabled;

  const AuthTextField({
    super.key,
    required this.label,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.controller,
    this.enabled = true,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late bool _obscured;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.label, style: AppTypography.caption),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          height: 48,
          child: TextField(
            controller: widget.controller,
            obscureText: _obscured,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            enabled: widget.enabled,
            style: AppTypography.body,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.neutral100,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide(
                  color: hasError ? AppColors.error : AppColors.neutral200,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide(
                  color: hasError ? AppColors.error : AppColors.neutral200,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide(
                  color: hasError ? AppColors.error : AppColors.primary,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.neutral200),
              ),
              suffixIcon: widget.obscureText
                  ? IconButton(
                      icon: Icon(
                        _obscured
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.neutral400,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscured = !_obscured),
                    )
                  : null,
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.errorText!,
            style: AppTypography.caption.copyWith(color: AppColors.error),
          ),
        ],
      ],
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd mobile && flutter test test/features/auth/presentation/widgets/auth_text_field_test.dart`
Expected: All tests PASS

- [ ] **Step 5: Commit**

```bash
git add mobile/test/features/auth/presentation/widgets/auth_text_field_test.dart mobile/lib/features/auth/presentation/widgets/auth_text_field.dart
git commit -m "feat: AuthTextField widget with error state and password toggle"
```

---

## Task 6: LoginScreen — TDD

**Files:**
- Test: `mobile/test/features/auth/presentation/login_screen_test.dart`
- Create: `mobile/lib/features/auth/presentation/login_screen.dart`

- [ ] **Step 1: Write failing tests**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:oriz/features/auth/providers/auth_provider.dart';
import 'package:oriz/features/auth/presentation/login_screen.dart';
import 'package:oriz/features/auth/data/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

// Helper to build a testable widget with required providers
Widget buildLoginScreen({
  required MockAuthRepository mockRepo,
  List<String> navigatedTo = const [],
}) {
  final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (_, __) {
          navigatedTo.add('/signup');
          return const Scaffold(body: Text('Signup'));
        },
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) {
          navigatedTo.add('/forgot-password');
          return const Scaffold(body: Text('ForgotPassword'));
        },
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(mockRepo),
    ],
    child: MaterialApp.router(
      routerConfig: router,
    ),
  );
}

void main() {
  late MockAuthRepository mockRepo;

  setUp(() {
    mockRepo = MockAuthRepository();
    when(() => mockRepo.currentSession).thenReturn(null);
    when(() => mockRepo.onAuthStateChange)
        .thenAnswer((_) => const Stream.empty());
  });

  group('rendering', () {
    testWidgets('shows email and password fields', (tester) async {
      await tester.pumpWidget(buildLoginScreen(mockRepo: mockRepo));
      await tester.pumpAndSettle();

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Senha'), findsOneWidget);
    });

    testWidgets('shows Entrar button', (tester) async {
      await tester.pumpWidget(buildLoginScreen(mockRepo: mockRepo));
      await tester.pumpAndSettle();

      expect(find.text('Entrar'), findsOneWidget);
    });

    testWidgets('shows navigation links', (tester) async {
      await tester.pumpWidget(buildLoginScreen(mockRepo: mockRepo));
      await tester.pumpAndSettle();

      expect(find.text('Criar conta'), findsOneWidget);
      expect(find.text('Esqueci senha'), findsOneWidget);
    });
  });

  group('validation', () {
    testWidgets('shows error when email is empty on submit', (tester) async {
      await tester.pumpWidget(buildLoginScreen(mockRepo: mockRepo));
      await tester.pumpAndSettle();

      // Enter password but leave email empty
      await tester.enterText(
        find.widgetWithText(TextField, '').first,
        '',
      );
      await tester.enterText(
        find.widgetWithText(TextField, '').last,
        'password123',
      );
      await tester.tap(find.text('Entrar'));
      await tester.pump();

      expect(find.text('Informe seu email'), findsOneWidget);
    });

    testWidgets('shows error for invalid email format', (tester) async {
      await tester.pumpWidget(buildLoginScreen(mockRepo: mockRepo));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).first,
        'not-an-email',
      );
      await tester.enterText(
        find.byType(TextField).last,
        'password123',
      );
      await tester.tap(find.text('Entrar'));
      await tester.pump();

      expect(find.text('Email invalido'), findsOneWidget);
    });

    testWidgets('shows error when password is too short', (tester) async {
      await tester.pumpWidget(buildLoginScreen(mockRepo: mockRepo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'a@b.com');
      await tester.enterText(find.byType(TextField).last, '123');
      await tester.tap(find.text('Entrar'));
      await tester.pump();

      expect(find.text('Minimo 8 caracteres'), findsOneWidget);
    });
  });

  group('loading state', () {
    testWidgets('shows spinner and disables fields during loading',
        (tester) async {
      // Make signIn hang to keep loading state visible
      when(() => mockRepo.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 10));
        return AuthResponse(session: null, user: null);
      });

      await tester.pumpWidget(buildLoginScreen(mockRepo: mockRepo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'a@b.com');
      await tester.enterText(find.byType(TextField).last, 'password123');
      await tester.tap(find.text('Entrar'));
      await tester.pump();

      // Spinner should be visible (CircularProgressIndicator)
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('error state', () {
    testWidgets('shows error message after failed login', (tester) async {
      when(() => mockRepo.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(AuthException('Invalid login credentials'));

      await tester.pumpWidget(buildLoginScreen(mockRepo: mockRepo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'a@b.com');
      await tester.enterText(find.byType(TextField).last, 'password123');
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Email ou senha incorretos'), findsOneWidget);
    });
  });

  group('navigation', () {
    testWidgets('tapping Criar conta navigates to /signup', (tester) async {
      final navigated = <String>[];
      await tester.pumpWidget(buildLoginScreen(
        mockRepo: mockRepo,
        navigatedTo: navigated,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Criar conta'));
      await tester.pumpAndSettle();

      expect(navigated, contains('/signup'));
    });

    testWidgets('tapping Esqueci senha navigates to /forgot-password',
        (tester) async {
      final navigated = <String>[];
      await tester.pumpWidget(buildLoginScreen(
        mockRepo: mockRepo,
        navigatedTo: navigated,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Esqueci senha'));
      await tester.pumpAndSettle();

      expect(navigated, contains('/forgot-password'));
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd mobile && flutter test test/features/auth/presentation/login_screen_test.dart`
Expected: FAIL — `login_screen.dart` does not exist

- [ ] **Step 3: Write implementation**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/auth_provider.dart';
import 'widgets/auth_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _emailError;
  String? _passwordError;
  String? _generalError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _generalError = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    var valid = true;

    if (email.isEmpty) {
      setState(() => _emailError = 'Informe seu email');
      valid = false;
    } else if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _emailError = 'Email invalido');
      valid = false;
    }

    if (password.length < 8) {
      setState(() => _passwordError = 'Minimo 8 caracteres');
      valid = false;
    }

    return valid;
  }

  Future<void> _submit() async {
    if (!_validate()) return;

    HapticFeedback.lightImpact();

    await ref.read(authNotifierProvider.notifier).signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthLoading;

    // Listen for auth errors
    ref.listen(authNotifierProvider, (prev, next) {
      if (next is AuthError) {
        setState(() {
          _generalError = next.rateLimited
              ? 'Muitas tentativas. Aguarde antes de tentar novamente.'
              : 'Email ou senha incorretos';
        });
      }
      if (next is AuthAuthenticated) {
        context.go('/agenda');
      }
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xxl * 2),
              // Logo
              Text(
                'Oriz',
                style: AppTypography.display.copyWith(
                  fontSize: 40,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Error banner
              if (_generalError != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.errorSoft,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    _generalError!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // Email
              AuthTextField(
                label: 'Email',
                controller: _emailController,
                errorText: _emailError,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                enabled: !isLoading,
              ),
              const SizedBox(height: AppSpacing.md),

              // Password
              AuthTextField(
                label: 'Senha',
                controller: _passwordController,
                errorText: _passwordError,
                obscureText: true,
                textInputAction: TextInputAction.done,
                enabled: !isLoading,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Submit button
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primary.withAlpha(102),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accent,
                          ),
                        )
                      : Text('Entrar', style: AppTypography.bodySemibold.copyWith(
                          color: Colors.white,
                        )),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Navigation links
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: isLoading ? null : () => context.go('/signup'),
                    child: Text(
                      'Criar conta',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.neutral600,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: isLoading
                        ? null
                        : () => context.go('/forgot-password'),
                    child: Text(
                      'Esqueci senha',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.neutral600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd mobile && flutter test test/features/auth/presentation/login_screen_test.dart`
Expected: All tests PASS. Some tests may need minor adjustments depending on exact widget tree — fix any failures and re-run.

- [ ] **Step 5: Commit**

```bash
git add mobile/test/features/auth/presentation/login_screen_test.dart mobile/lib/features/auth/presentation/login_screen.dart
git commit -m "feat: LoginScreen with validation, loading state, and error handling"
```

---

## Task 7: SignupScreen — TDD

**Files:**
- Test: `mobile/test/features/auth/presentation/signup_screen_test.dart`
- Create: `mobile/lib/features/auth/presentation/signup_screen.dart`

- [ ] **Step 1: Write failing tests**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:oriz/features/auth/providers/auth_provider.dart';
import 'package:oriz/features/auth/presentation/signup_screen.dart';
import 'package:oriz/features/auth/data/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

Widget buildSignupScreen({
  required MockAuthRepository mockRepo,
  List<String> navigatedTo = const [],
}) {
  final router = GoRouter(
    initialLocation: '/signup',
    routes: [
      GoRoute(
        path: '/signup',
        builder: (_, __) => const SignupScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) {
          navigatedTo.add('/login');
          return const Scaffold(body: Text('Login'));
        },
      ),
      GoRoute(
        path: '/agenda',
        builder: (_, __) {
          navigatedTo.add('/agenda');
          return const Scaffold(body: Text('Agenda'));
        },
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(mockRepo),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  late MockAuthRepository mockRepo;

  setUp(() {
    mockRepo = MockAuthRepository();
    when(() => mockRepo.currentSession).thenReturn(null);
    when(() => mockRepo.onAuthStateChange)
        .thenAnswer((_) => const Stream.empty());
  });

  group('rendering', () {
    testWidgets('shows name, email, and password fields', (tester) async {
      await tester.pumpWidget(buildSignupScreen(mockRepo: mockRepo));
      await tester.pumpAndSettle();

      expect(find.text('Nome completo'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Senha'), findsOneWidget);
    });

    testWidgets('shows Criar conta button', (tester) async {
      await tester.pumpWidget(buildSignupScreen(mockRepo: mockRepo));
      await tester.pumpAndSettle();

      expect(find.text('Criar conta'), findsWidgets); // button + app bar title
    });
  });

  group('validation', () {
    testWidgets('shows error when name is empty', (tester) async {
      await tester.pumpWidget(buildSignupScreen(mockRepo: mockRepo));
      await tester.pumpAndSettle();

      // Fill email and password but leave name empty
      await tester.enterText(find.byType(TextField).at(1), 'a@b.com');
      await tester.enterText(find.byType(TextField).at(2), 'password123');

      // Find and tap the submit button (ElevatedButton with "Criar conta")
      await tester.tap(find.widgetWithText(ElevatedButton, 'Criar conta'));
      await tester.pump();

      expect(find.text('Informe seu nome'), findsOneWidget);
    });

    testWidgets('shows error for invalid email', (tester) async {
      await tester.pumpWidget(buildSignupScreen(mockRepo: mockRepo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Maria');
      await tester.enterText(find.byType(TextField).at(1), 'bad-email');
      await tester.enterText(find.byType(TextField).at(2), 'password123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Criar conta'));
      await tester.pump();

      expect(find.text('Email invalido'), findsOneWidget);
    });

    testWidgets('shows error for short password', (tester) async {
      await tester.pumpWidget(buildSignupScreen(mockRepo: mockRepo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Maria');
      await tester.enterText(find.byType(TextField).at(1), 'a@b.com');
      await tester.enterText(find.byType(TextField).at(2), '123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Criar conta'));
      await tester.pump();

      expect(find.text('Minimo 8 caracteres'), findsOneWidget);
    });
  });

  group('error state', () {
    testWidgets('shows email already exists error', (tester) async {
      when(() => mockRepo.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
            fullName: any(named: 'fullName'),
          )).thenThrow(AuthException('User already registered'));

      await tester.pumpWidget(buildSignupScreen(mockRepo: mockRepo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Maria');
      await tester.enterText(find.byType(TextField).at(1), 'a@b.com');
      await tester.enterText(find.byType(TextField).at(2), 'password123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Criar conta'));
      await tester.pumpAndSettle();

      expect(find.text('Email ja cadastrado'), findsOneWidget);
    });
  });

  group('navigation', () {
    testWidgets('tapping Ja tem conta navigates to /login', (tester) async {
      final navigated = <String>[];
      await tester.pumpWidget(buildSignupScreen(
        mockRepo: mockRepo,
        navigatedTo: navigated,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Ja tem conta'));
      await tester.pumpAndSettle();

      expect(navigated, contains('/login'));
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd mobile && flutter test test/features/auth/presentation/signup_screen_test.dart`
Expected: FAIL — `signup_screen.dart` does not exist

- [ ] **Step 3: Write implementation**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/auth_provider.dart';
import 'widgets/auth_text_field.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _generalError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
      _generalError = null;
    });

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    var valid = true;

    if (name.isEmpty) {
      setState(() => _nameError = 'Informe seu nome');
      valid = false;
    }
    if (email.isEmpty) {
      setState(() => _emailError = 'Informe seu email');
      valid = false;
    } else if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _emailError = 'Email invalido');
      valid = false;
    }
    if (password.length < 8) {
      setState(() => _passwordError = 'Minimo 8 caracteres');
      valid = false;
    }

    return valid;
  }

  Future<void> _submit() async {
    if (!_validate()) return;

    HapticFeedback.lightImpact();

    await ref.read(authNotifierProvider.notifier).signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _nameController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthLoading;

    ref.listen(authNotifierProvider, (prev, next) {
      if (next is AuthError) {
        setState(() {
          _generalError = next.message.contains('already registered')
              ? 'Email ja cadastrado'
              : next.message;
        });
      }
      if (next is AuthAuthenticated) {
        context.go('/agenda');
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
        title: const Text('Criar conta'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.lg),

              if (_generalError != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.errorSoft,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    _generalError!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              AuthTextField(
                label: 'Nome completo',
                controller: _nameController,
                errorText: _nameError,
                textInputAction: TextInputAction.next,
                enabled: !isLoading,
              ),
              const SizedBox(height: AppSpacing.md),

              AuthTextField(
                label: 'Email',
                controller: _emailController,
                errorText: _emailError,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                enabled: !isLoading,
              ),
              const SizedBox(height: AppSpacing.md),

              AuthTextField(
                label: 'Senha',
                controller: _passwordController,
                errorText: _passwordError,
                obscureText: true,
                textInputAction: TextInputAction.done,
                enabled: !isLoading,
              ),
              const SizedBox(height: AppSpacing.lg),

              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primary.withAlpha(102),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accent,
                          ),
                        )
                      : Text('Criar conta',
                          style: AppTypography.bodySemibold.copyWith(
                            color: Colors.white,
                          )),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              Center(
                child: GestureDetector(
                  onTap: isLoading ? null : () => context.go('/login'),
                  child: Text(
                    'Ja tem conta? Entrar',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.neutral600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd mobile && flutter test test/features/auth/presentation/signup_screen_test.dart`
Expected: All tests PASS

- [ ] **Step 5: Commit**

```bash
git add mobile/test/features/auth/presentation/signup_screen_test.dart mobile/lib/features/auth/presentation/signup_screen.dart
git commit -m "feat: SignupScreen with name/email/password validation and error handling"
```

---

## Task 8: ForgotPasswordScreen — TDD

**Files:**
- Test: `mobile/test/features/auth/presentation/forgot_password_screen_test.dart`
- Create: `mobile/lib/features/auth/presentation/forgot_password_screen.dart`

- [ ] **Step 1: Write failing tests**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:oriz/features/auth/providers/auth_provider.dart';
import 'package:oriz/features/auth/presentation/forgot_password_screen.dart';
import 'package:oriz/features/auth/data/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

Widget buildForgotPasswordScreen({
  required MockAuthRepository mockRepo,
}) {
  final router = GoRouter(
    initialLocation: '/forgot-password',
    routes: [
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const Scaffold(body: Text('Login')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(mockRepo),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  late MockAuthRepository mockRepo;

  setUp(() {
    mockRepo = MockAuthRepository();
    when(() => mockRepo.currentSession).thenReturn(null);
    when(() => mockRepo.onAuthStateChange)
        .thenAnswer((_) => const Stream.empty());
  });

  group('rendering', () {
    testWidgets('shows email field and submit button', (tester) async {
      await tester.pumpWidget(buildForgotPasswordScreen(mockRepo: mockRepo));
      await tester.pumpAndSettle();

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Enviar instrucoes'), findsOneWidget);
    });

    testWidgets('shows descriptive text', (tester) async {
      await tester.pumpWidget(buildForgotPasswordScreen(mockRepo: mockRepo));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Informe seu email'),
        findsOneWidget,
      );
    });
  });

  group('validation', () {
    testWidgets('shows error when email is empty', (tester) async {
      await tester.pumpWidget(buildForgotPasswordScreen(mockRepo: mockRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Enviar instrucoes'));
      await tester.pump();

      expect(find.text('Informe seu email'), findsWidgets);
    });
  });

  group('success state', () {
    testWidgets('shows generic success message', (tester) async {
      when(() => mockRepo.resetPassword(email: any(named: 'email')))
          .thenAnswer((_) async {});

      await tester.pumpWidget(buildForgotPasswordScreen(mockRepo: mockRepo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'a@b.com');
      await tester.tap(find.text('Enviar instrucoes'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Se o email existir'),
        findsOneWidget,
      );
    });

    testWidgets('shows same message even for non-existent email',
        (tester) async {
      // Even if Supabase throws, we show success to prevent enumeration
      when(() => mockRepo.resetPassword(email: any(named: 'email')))
          .thenThrow(AuthException('User not found'));

      await tester.pumpWidget(buildForgotPasswordScreen(mockRepo: mockRepo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'nobody@example.com');
      await tester.tap(find.text('Enviar instrucoes'));
      await tester.pumpAndSettle();

      // Must still show generic success — never reveal if email exists
      expect(
        find.textContaining('Se o email existir'),
        findsOneWidget,
      );
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd mobile && flutter test test/features/auth/presentation/forgot_password_screen_test.dart`
Expected: FAIL

- [ ] **Step 3: Write implementation**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/auth_provider.dart';
import 'widgets/auth_text_field.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  String? _emailError;
  bool _submitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() => _emailError = null);
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() => _emailError = 'Informe seu email');
      return false;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _emailError = 'Email invalido');
      return false;
    }
    return true;
  }

  Future<void> _submit() async {
    if (!_validate()) return;

    HapticFeedback.lightImpact();

    await ref.read(authNotifierProvider.notifier).resetPassword(
          email: _emailController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthLoading;

    ref.listen(authNotifierProvider, (prev, next) {
      if (next is AuthActionSuccess) {
        setState(() => _submitted = true);
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
        title: const Text('Recuperar senha'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.lg),

              if (_submitted) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.successSoft,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    'Se o email existir, enviaremos instrucoes.',
                    style: AppTypography.body.copyWith(
                      color: AppColors.success,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ] else ...[
                Text(
                  'Informe seu email e enviaremos instrucoes para redefinir sua senha.',
                  style: AppTypography.body.copyWith(
                    color: AppColors.neutral600,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                AuthTextField(
                  label: 'Email',
                  controller: _emailController,
                  errorText: _emailError,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  enabled: !isLoading,
                ),
                const SizedBox(height: AppSpacing.lg),

                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppColors.primary.withAlpha(102),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.accent,
                            ),
                          )
                        : Text('Enviar instrucoes',
                            style: AppTypography.bodySemibold.copyWith(
                              color: Colors.white,
                            )),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd mobile && flutter test test/features/auth/presentation/forgot_password_screen_test.dart`
Expected: All tests PASS

- [ ] **Step 5: Commit**

```bash
git add mobile/test/features/auth/presentation/forgot_password_screen_test.dart mobile/lib/features/auth/presentation/forgot_password_screen.dart
git commit -m "feat: ForgotPasswordScreen with email enumeration protection"
```

---

## Task 9: GoRouter + Auth Redirect — TDD

**Files:**
- Test: `mobile/test/core/router/app_router_test.dart`
- Create: `mobile/lib/core/router/app_router.dart`
- Create: `mobile/lib/core/shell/app_shell.dart`

- [ ] **Step 1: Write failing tests**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oriz/core/router/app_router.dart';
import 'package:oriz/features/auth/providers/auth_provider.dart';
import 'package:oriz/features/auth/data/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepo;

  setUp(() {
    mockRepo = MockAuthRepository();
    when(() => mockRepo.onAuthStateChange)
        .thenAnswer((_) => const Stream.empty());
  });

  Widget buildApp({required bool hasSession}) {
    when(() => mockRepo.currentSession).thenReturn(
      hasSession ? _FakeSession() : null,
    );

    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          final router = ref.watch(routerProvider);
          return MaterialApp.router(routerConfig: router);
        },
      ),
    );
  }

  testWidgets('redirects to /login when no session', (tester) async {
    await tester.pumpWidget(buildApp(hasSession: false));
    await tester.pumpAndSettle();

    // Should see LoginScreen content
    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets('redirects to /agenda when session exists', (tester) async {
    await tester.pumpWidget(buildApp(hasSession: true));
    await tester.pumpAndSettle();

    // Should see Agenda content (bottom nav label)
    expect(find.text('Agenda'), findsWidgets);
  });
}

// Minimal fake for Session — just needs to be non-null
class _FakeSession implements Session {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
```

Note: `Session` is from `supabase_flutter`. We use a fake rather than a mock because we only need it to be non-null.

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd mobile && flutter test test/core/router/app_router_test.dart`
Expected: FAIL — `app_router.dart` does not exist

- [ ] **Step 3: Write implementation**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/agenda/agenda_day_screen.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../shell/app_shell.dart';

/// Listenable that notifies GoRouter when auth state changes.
class AuthNotifierListenable extends ChangeNotifier {
  AuthNotifierListenable(Ref ref) {
    ref.listen(authNotifierProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final repo = ref.read(authRepositoryProvider);
  final authListenable = AuthNotifierListenable(ref);

  return GoRouter(
    initialLocation: '/agenda',
    refreshListenable: authListenable,
    redirect: (context, state) {
      final hasSession = repo.currentSession != null;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/forgot-password';

      if (!hasSession && !isAuthRoute) return '/login';
      if (hasSession && isAuthRoute) return '/agenda';
      return null;
    },
    routes: [
      // Auth routes (no shell)
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (_, __) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),

      // Protected routes with shell (bottom nav)
      ShellRoute(
        builder: (_, __, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/agenda',
            builder: (_, __) => const AgendaDayScreen(),
          ),
          GoRoute(
            path: '/clients',
            builder: (_, __) => const _Placeholder('Clientes'),
          ),
          GoRoute(
            path: '/financial',
            builder: (_, __) => const _Placeholder('Financeiro'),
          ),
          GoRoute(
            path: '/more',
            builder: (_, __) => const _Placeholder('Mais'),
          ),
        ],
      ),
    ],
  );
});

class _Placeholder extends StatelessWidget {
  final String label;
  const _Placeholder(this.label);

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(label, style: const TextStyle(fontSize: 24)));
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd mobile && flutter test test/core/router/app_router_test.dart`
Expected: All tests PASS

- [ ] **Step 5: Create AppShell**

Create `mobile/lib/core/shell/app_shell.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

/// App shell with bottom navigation for protected routes.
/// Used by GoRouter ShellRoute.
class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/agenda')) return 0;
    if (location.startsWith('/clients')) return 1;
    if (location.startsWith('/financial')) return 2;
    if (location.startsWith('/more')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.neutral200, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex(context),
          onTap: (i) {
            switch (i) {
              case 0: context.go('/agenda');
              case 1: context.go('/clients');
              case 2: context.go('/financial');
              case 3: context.go('/more');
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today_rounded),
              label: 'Agenda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline_rounded),
              activeIcon: Icon(Icons.people_rounded),
              label: 'Clientes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.attach_money_rounded),
              activeIcon: Icon(Icons.attach_money_rounded),
              label: 'Financeiro',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.more_horiz_rounded),
              activeIcon: Icon(Icons.more_horiz_rounded),
              label: 'Mais',
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Commit**

```bash
git add mobile/test/core/router/app_router_test.dart mobile/lib/core/router/app_router.dart mobile/lib/core/shell/app_shell.dart
git commit -m "feat: GoRouter with auth redirect, refreshListenable, and ShellRoute"
```

---

## Task 10: Migrate main.dart

**Files:**
- Modify: `mobile/lib/main.dart`
- Modify: `mobile/test/widget_test.dart`

- [ ] **Step 1: Update main.dart**

Replace `mobile/lib/main.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/supabase/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initSupabase(
    url: const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'http://localhost:54321',
    ),
    anonKey: const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: 'dev-anon-key',
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          AuthRepository(supabase.auth),
        ),
      ],
      child: const OrizApp(),
    ),
  );
}

class OrizApp extends ConsumerWidget {
  const OrizApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Oriz',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: router,
    );
  }
}
```

- [ ] **Step 2: Update widget test**

Replace `mobile/test/widget_test.dart`:

```dart
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
```

- [ ] **Step 3: Run all tests**

Run: `cd mobile && flutter test`
Expected: All tests PASS

- [ ] **Step 4: Commit**

```bash
git add mobile/lib/main.dart mobile/test/widget_test.dart
git commit -m "feat: migrate main.dart to Riverpod + GoRouter with auth flow"
```

---

## Task 11: Run Full Test Suite + Smoke Test

- [ ] **Step 1: Run all Flutter tests**

Run: `cd mobile && flutter test`
Expected: All tests pass (should be ~40+ tests across 8 test files)

- [ ] **Step 2: Verify app compiles**

Run: `cd mobile && flutter build apk --debug --dart-define=SUPABASE_URL=http://localhost:54321 --dart-define=SUPABASE_ANON_KEY=test-key 2>&1 | tail -5`
Expected: Build succeeds (we just need compilation, not a working Supabase instance)

- [ ] **Step 3: Final commit with all remaining files**

If any files were missed in previous commits:
```bash
cd mobile && git add -A && git status
```

If clean, no commit needed. Otherwise:
```bash
git commit -m "chore: ensure all auth files are tracked"
```

---

## Summary

| Task | Descricao | Arquivos |
|------|-----------|----------|
| 1 | Dependencias | pubspec.yaml |
| 2 | Supabase config | supabase_config.dart |
| 3 | AuthRepository TDD | auth_repository.dart + test |
| 4 | Auth Provider TDD | auth_provider.dart + test |
| 5 | AuthTextField TDD | auth_text_field.dart + test |
| 6 | LoginScreen TDD | login_screen.dart + test |
| 7 | SignupScreen TDD | signup_screen.dart + test |
| 8 | ForgotPasswordScreen TDD | forgot_password_screen.dart + test |
| 9 | GoRouter TDD | app_router.dart + test |
| 10 | Migrar main.dart | main.dart + widget_test.dart |
| 11 | Suite completa + smoke test | — |
