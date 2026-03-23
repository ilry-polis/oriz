# Flutter Onboarding Wizard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Flutter onboarding wizard UI that guides new studio owners through setup (studio data, services, business hours) consuming the backend onboarding endpoints already implemented.

**Architecture:** Feature-based structure under `lib/features/onboarding/` following the established auth feature patterns. Data layer uses an HTTP client (`ApiClient`) to call backend Fastify endpoints. State managed by a Riverpod `Notifier` with sealed classes. UI uses `PageView` with animated stepper for step transitions.

**Tech Stack:** Flutter, Riverpod (NotifierProvider), GoRouter, http package, mocktail for tests

**Spec:** `docs/superpowers/specs/2026-03-22-onboarding-wizard-design.md`

---

## File Structure

```
lib/
├── core/
│   ├── http/
│   │   └── api_client.dart                  # HTTP client with auth token injection
│   └── router/
│       └── app_router.dart                  # MODIFY: add onboarding routes + redirect logic
├── main.dart                                # MODIFY: add provider overrides
└── features/
    └── onboarding/
        ├── data/
        │   ├── onboarding_repository.dart   # HTTP wrapper for backend onboarding endpoints
        │   └── service_templates.dart       # Static service template data by category
        ├── providers/
        │   └── onboarding_provider.dart     # Riverpod state machine for wizard flow
        └── presentation/
            ├── onboarding_wizard_screen.dart # Container: stepper + PageView
            ├── onboarding_complete_screen.dart
            ├── steps/
            │   ├── studio_data_step.dart    # Step 1: name, slug, phone, address, timezone
            │   ├── services_step.dart       # Step 2: category chips + service cards
            │   └── business_hours_step.dart # Step 3: 7-day inline time ranges
            └── widgets/
                ├── wizard_stepper.dart      # Animated numeric stepper (1-2-3)
                ├── service_template_card.dart # Editable service card
                └── day_hours_card.dart      # Day card with toggle + time range(s)
                                             # NOTE: spec lists time_range_picker.dart separately,
                                             # but it's implemented inline as _TimeDropdown in day_hours_card.dart

test/features/onboarding/
├── data/
│   └── onboarding_repository_test.dart
├── providers/
│   └── onboarding_provider_test.dart
└── presentation/
    ├── widgets/
    │   ├── wizard_stepper_test.dart
    │   ├── service_template_card_test.dart
    │   └── day_hours_card_test.dart
    ├── steps/
    │   ├── studio_data_step_test.dart
    │   ├── services_step_test.dart
    │   └── business_hours_step_test.dart
    ├── onboarding_wizard_screen_test.dart
    └── onboarding_complete_screen_test.dart
```

**Wave parallelization guide** (for subagent-driven execution):

| Wave | Tasks | Rationale |
|------|-------|-----------|
| 1 | 1, 3, 5, 9 | No dependencies: ApiClient, templates, stepper widget, DayHoursCard |
| 2 | 2 | Repo needs ApiClient |
| 3 | 4, 7 | Provider needs repo; ServiceTemplateCard needs templates |
| 4 | 6, 8, 10 | Steps need provider + respective widgets |
| 5 | 11, 12 | WizardScreen needs all steps; CompleteScreen needs provider |
| 6 | 13 | Router + wiring needs everything |

---

### Task 1: Add http dependency + create ApiClient

**Files:**
- Modify: `mobile/pubspec.yaml`
- Create: `mobile/lib/core/http/api_client.dart`

- [ ] **Step 1: Add http package to pubspec.yaml**

In `mobile/pubspec.yaml`, add under `dependencies:` after `go_router`:

```yaml
  http: ^1.4.0
```

- [ ] **Step 2: Run flutter pub get**

```bash
cd mobile && flutter pub get
```

Expected: dependencies resolve successfully

- [ ] **Step 3: Create ApiClient**

Create `mobile/lib/core/http/api_client.dart`:

```dart
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiClient {
  final http.Client _httpClient;
  final GoTrueClient _auth;
  final String baseUrl;

  ApiClient({
    required this.baseUrl,
    required GoTrueClient auth,
    http.Client? httpClient,
  })  : _auth = auth,
        _httpClient = httpClient ?? http.Client();

  Map<String, String> get _headers {
    final token = _auth.currentSession?.accessToken;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> get(String path) async {
    final response = await _httpClient.get(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _httpClient.patch(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final error = body['error'] as Map<String, dynamic>?;
    final code = error?['code'] as String? ?? 'UNKNOWN';
    final message = error?['message'] as String? ?? 'Erro desconhecido';

    throw ApiException(
      statusCode: response.statusCode,
      code: code,
      message: message,
    );
  }

  void dispose() {
    _httpClient.close();
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String code;
  final String message;

  const ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
  });

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}
```

- [ ] **Step 4: Verify it compiles**

```bash
cd mobile && dart analyze lib/core/http/api_client.dart
```

Expected: No issues found

- [ ] **Step 5: Commit**

```bash
cd mobile && git add pubspec.yaml pubspec.lock lib/core/http/api_client.dart
git commit -m "feat(onboarding): add http dependency and ApiClient base"
```

---

### Task 2: OnboardingRepository + tests

**Files:**
- Create: `mobile/lib/features/onboarding/data/onboarding_repository.dart`
- Create: `mobile/test/features/onboarding/data/onboarding_repository_test.dart`

**Depends on:** Task 1 (ApiClient)

- [ ] **Step 1: Write the failing tests**

Create `mobile/test/features/onboarding/data/onboarding_repository_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oriz/core/http/api_client.dart';
import 'package:oriz/features/onboarding/data/onboarding_repository.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockClient;
  late OnboardingRepository repo;

  setUp(() {
    mockClient = MockApiClient();
    repo = OnboardingRepository(mockClient);
  });

  group('getMyStudio', () {
    test('returns studio data on success', () async {
      when(() => mockClient.get('/api/v1/studios/me')).thenAnswer(
        (_) async => {
          'data': {
            'studio': {'id': 's1', 'name': 'Meu Studio'},
            'onboarding': {'current_step': 'services'},
            'professional': {'id': 'p1'},
          }
        },
      );

      final result = await repo.getMyStudio();

      expect(result.studioId, 's1');
      expect(result.studioName, 'Meu Studio');
      expect(result.onboardingStep, 'services');
      expect(result.professionalId, 'p1');
    });

    test('returns null on 404', () async {
      when(() => mockClient.get('/api/v1/studios/me'))
          .thenThrow(const ApiException(
        statusCode: 404,
        code: 'NOT_FOUND',
        message: 'Studio not found',
      ));

      final result = await repo.getMyStudio();

      expect(result, isNull);
    });

    test('rethrows non-404 errors', () async {
      when(() => mockClient.get('/api/v1/studios/me'))
          .thenThrow(const ApiException(
        statusCode: 500,
        code: 'INTERNAL',
        message: 'Server error',
      ));

      expect(() => repo.getMyStudio(), throwsA(isA<ApiException>()));
    });
  });

  group('createStudio', () {
    test('sends correct body and returns composite response', () async {
      when(() => mockClient.post(
            '/api/v1/studios',
            body: any(named: 'body'),
          )).thenAnswer((_) async => {
            'data': {
              'studio': {'id': 's1', 'name': 'Studio Bela', 'slug': 'studio-bela'},
              'onboarding': {'current_step': 'studio_data'},
              'professional': {'id': 'p1'},
            }
          });

      final result = await repo.createStudio(
        name: 'Studio Bela',
        slug: 'studio-bela',
        phone: '+5579999999999',
        address: 'Rua A, 123',
        timezone: 'America/Sao_Paulo',
      );

      verify(() => mockClient.post(
            '/api/v1/studios',
            body: {
              'name': 'Studio Bela',
              'slug': 'studio-bela',
              'phone': '+5579999999999',
              'address': 'Rua A, 123',
              'timezone': 'America/Sao_Paulo',
            },
          )).called(1);

      expect(result.studioId, 's1');
      expect(result.professionalId, 'p1');
    });
  });

  group('updateOnboardingStep', () {
    test('sends PATCH with step', () async {
      when(() => mockClient.patch(
            '/api/v1/studios/me/onboarding',
            body: any(named: 'body'),
          )).thenAnswer((_) async => {
            'data': {'current_step': 'services'}
          });

      await repo.updateOnboardingStep('services');

      verify(() => mockClient.patch(
            '/api/v1/studios/me/onboarding',
            body: {'current_step': 'services'},
          )).called(1);
    });
  });

  group('getServiceCategories', () {
    test('returns list of categories', () async {
      when(() => mockClient.get('/api/v1/service-categories')).thenAnswer(
        (_) async => {
          'data': [
            {'id': 'c1', 'name': 'Unhas'},
            {'id': 'c2', 'name': 'Cilios'},
          ]
        },
      );

      final result = await repo.getServiceCategories();

      expect(result, hasLength(2));
      expect(result[0].id, 'c1');
      expect(result[0].name, 'Unhas');
    });
  });

  group('createService', () {
    test('sends correct body', () async {
      when(() => mockClient.post(
            '/api/v1/services',
            body: any(named: 'body'),
          )).thenAnswer((_) async => {
            'data': {'id': 'svc1', 'name': 'Manicure'}
          });

      await repo.createService(
        categoryId: 'c1',
        name: 'Manicure',
        durationMinutes: 30,
        price: 5000,
      );

      verify(() => mockClient.post(
            '/api/v1/services',
            body: {
              'category_id': 'c1',
              'name': 'Manicure',
              'duration_minutes': 30,
              'price': 5000,
            },
          )).called(1);
    });
  });

  group('updateWorkingHours', () {
    test('sends PATCH with working_hours', () async {
      final hours = {
        'monday': [
          {'open': '09:00', 'close': '18:00'}
        ],
        'tuesday': <Map<String, String>>[],
      };

      when(() => mockClient.patch(
            '/api/v1/professionals/p1',
            body: any(named: 'body'),
          )).thenAnswer((_) async => {
            'data': {'id': 'p1', 'working_hours': hours}
          });

      await repo.updateWorkingHours('p1', hours);

      verify(() => mockClient.patch(
            '/api/v1/professionals/p1',
            body: {'working_hours': hours},
          )).called(1);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd mobile && flutter test test/features/onboarding/data/onboarding_repository_test.dart
```

Expected: compilation error — `OnboardingRepository` not found

- [ ] **Step 3: Implement OnboardingRepository**

Create `mobile/lib/features/onboarding/data/onboarding_repository.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/http/api_client.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  throw UnimplementedError(
    'onboardingRepositoryProvider must be overridden with a real OnboardingRepository',
  );
});

class StudioInfo {
  final String studioId;
  final String studioName;
  final String onboardingStep;
  final String professionalId;

  const StudioInfo({
    required this.studioId,
    required this.studioName,
    required this.onboardingStep,
    required this.professionalId,
  });
}

class ServiceCategory {
  final String id;
  final String name;

  const ServiceCategory({required this.id, required this.name});
}

class OnboardingRepository {
  final ApiClient _client;

  OnboardingRepository(this._client);

  Future<StudioInfo?> getMyStudio() async {
    try {
      final response = await _client.get('/api/v1/studios/me');
      final data = response['data'] as Map<String, dynamic>;

      final studio = data['studio'] as Map<String, dynamic>?;
      final onboarding = data['onboarding'] as Map<String, dynamic>?;
      final professional = data['professional'] as Map<String, dynamic>?;

      // Fallback: GET /studios/me pode retornar flat ou nested
      final studioId = studio?['id'] as String? ?? data['id'] as String;
      final studioName = studio?['name'] as String? ?? data['name'] as String;
      final step = onboarding?['current_step'] as String? ?? 'studio_data';
      final profId = professional?['id'] as String? ?? '';

      return StudioInfo(
        studioId: studioId,
        studioName: studioName,
        onboardingStep: step,
        professionalId: profId,
      );
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<StudioInfo> createStudio({
    required String name,
    required String slug,
    String? phone,
    String? address,
    String timezone = 'America/Sao_Paulo',
  }) async {
    final response = await _client.post(
      '/api/v1/studios',
      body: {
        'name': name,
        'slug': slug,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
        'timezone': timezone,
      },
    );

    final data = response['data'] as Map<String, dynamic>;
    final studio = data['studio'] as Map<String, dynamic>;
    final onboarding = data['onboarding'] as Map<String, dynamic>;
    final professional = data['professional'] as Map<String, dynamic>;

    return StudioInfo(
      studioId: studio['id'] as String,
      studioName: studio['name'] as String,
      onboardingStep: onboarding['current_step'] as String,
      professionalId: professional['id'] as String,
    );
  }

  Future<void> updateOnboardingStep(String step) async {
    await _client.patch(
      '/api/v1/studios/me/onboarding',
      body: {'current_step': step},
    );
  }

  Future<List<ServiceCategory>> getServiceCategories() async {
    final response = await _client.get('/api/v1/service-categories');
    final list = response['data'] as List<dynamic>;

    return list
        .map((item) => ServiceCategory(
              id: (item as Map<String, dynamic>)['id'] as String,
              name: item['name'] as String,
            ))
        .toList();
  }

  Future<void> createService({
    required String categoryId,
    required String name,
    required int durationMinutes,
    required int price,
  }) async {
    await _client.post(
      '/api/v1/services',
      body: {
        'category_id': categoryId,
        'name': name,
        'duration_minutes': durationMinutes,
        'price': price,
      },
    );
  }

  Future<void> updateWorkingHours(
    String professionalId,
    Map<String, List<Map<String, String>>> hours,
  ) async {
    await _client.patch(
      '/api/v1/professionals/$professionalId',
      body: {'working_hours': hours},
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd mobile && flutter test test/features/onboarding/data/onboarding_repository_test.dart
```

Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
cd mobile && git add lib/features/onboarding/data/onboarding_repository.dart test/features/onboarding/data/onboarding_repository_test.dart
git commit -m "feat(onboarding): OnboardingRepository with HTTP client + 7 tests"
```

---

### Task 3: Service Templates static data

**Files:**
- Create: `mobile/lib/features/onboarding/data/service_templates.dart`

**Depends on:** Nothing

- [ ] **Step 1: Create service templates file**

Create `mobile/lib/features/onboarding/data/service_templates.dart`:

```dart
class ServiceTemplate {
  final String category;
  final String name;
  final int durationMinutes;
  final int price; // centavos

  const ServiceTemplate({
    required this.category,
    required this.name,
    required this.durationMinutes,
    required this.price,
  });
}

const serviceTemplates = <ServiceTemplate>[
  // Unhas
  ServiceTemplate(category: 'Unhas', name: 'Manicure', durationMinutes: 30, price: 5000),
  ServiceTemplate(category: 'Unhas', name: 'Pedicure', durationMinutes: 45, price: 6000),
  ServiceTemplate(category: 'Unhas', name: 'Esmaltacao em gel', durationMinutes: 60, price: 8000),

  // Cilios
  ServiceTemplate(category: 'Cilios', name: 'Extensao de cilios', durationMinutes: 90, price: 15000),
  ServiceTemplate(category: 'Cilios', name: 'Lash lifting', durationMinutes: 60, price: 10000),

  // Cabelo
  ServiceTemplate(category: 'Cabelo', name: 'Corte feminino', durationMinutes: 45, price: 8000),
  ServiceTemplate(category: 'Cabelo', name: 'Escova', durationMinutes: 30, price: 5000),
  ServiceTemplate(category: 'Cabelo', name: 'Coloracao', durationMinutes: 120, price: 20000),

  // Micropigmentacao
  ServiceTemplate(category: 'Micropigmentacao', name: 'Sobrancelha', durationMinutes: 120, price: 40000),
  ServiceTemplate(category: 'Micropigmentacao', name: 'Labios', durationMinutes: 120, price: 50000),

  // Sobrancelha
  ServiceTemplate(category: 'Sobrancelha', name: 'Design de sobrancelha', durationMinutes: 30, price: 4000),
  ServiceTemplate(category: 'Sobrancelha', name: 'Henna', durationMinutes: 30, price: 5000),

  // Depilacao
  ServiceTemplate(category: 'Depilacao', name: 'Buzzo', durationMinutes: 15, price: 2000),
  ServiceTemplate(category: 'Depilacao', name: 'Meia perna', durationMinutes: 30, price: 4000),
];

const categoryNames = [
  'Unhas',
  'Cilios',
  'Cabelo',
  'Micropigmentacao',
  'Sobrancelha',
  'Depilacao',
  'Outro',
];

List<ServiceTemplate> templatesForCategory(String category) {
  return serviceTemplates.where((t) => t.category == category).toList();
}
```

- [ ] **Step 2: Verify it compiles**

```bash
cd mobile && dart analyze lib/features/onboarding/data/service_templates.dart
```

Expected: No issues found

- [ ] **Step 3: Commit**

```bash
cd mobile && git add lib/features/onboarding/data/service_templates.dart
git commit -m "feat(onboarding): static service templates data by category"
```

---

### Task 4: OnboardingProvider + tests

**Files:**
- Create: `mobile/lib/features/onboarding/providers/onboarding_provider.dart`
- Create: `mobile/test/features/onboarding/providers/onboarding_provider_test.dart`

**Depends on:** Task 2 (OnboardingRepository)

- [ ] **Step 1: Write the failing tests**

Create `mobile/test/features/onboarding/providers/onboarding_provider_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oriz/core/http/api_client.dart';
import 'package:oriz/features/onboarding/data/onboarding_repository.dart';
import 'package:oriz/features/onboarding/providers/onboarding_provider.dart';

class MockOnboardingRepository extends Mock implements OnboardingRepository {}

void main() {
  late MockOnboardingRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockOnboardingRepository();
    container = ProviderContainer(
      overrides: [
        onboardingRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  });

  tearDown(() => container.dispose());

  group('init', () {
    test('sets step 0 when user has no studio', () async {
      when(() => mockRepo.getMyStudio()).thenAnswer((_) async => null);

      final notifier = container.read(onboardingNotifierProvider.notifier);
      await notifier.init();

      final state = container.read(onboardingNotifierProvider);
      expect(state, isA<OnboardingStep>());
      expect((state as OnboardingStep).currentStep, 0);
      expect(state.studioId, isNull);
    });

    test('resumes at correct step when studio exists with incomplete onboarding', () async {
      when(() => mockRepo.getMyStudio()).thenAnswer((_) async => const StudioInfo(
            studioId: 's1',
            studioName: 'Meu Studio',
            onboardingStep: 'services',
            professionalId: 'p1',
          ));

      final notifier = container.read(onboardingNotifierProvider.notifier);
      await notifier.init();

      final state = container.read(onboardingNotifierProvider);
      expect(state, isA<OnboardingStep>());
      expect((state as OnboardingStep).currentStep, 1);
      expect(state.studioId, 's1');
    });

    test('sets OnboardingComplete when onboarding step is complete', () async {
      when(() => mockRepo.getMyStudio()).thenAnswer((_) async => const StudioInfo(
            studioId: 's1',
            studioName: 'Meu Studio',
            onboardingStep: 'complete',
            professionalId: 'p1',
          ));

      final notifier = container.read(onboardingNotifierProvider.notifier);
      await notifier.init();

      final state = container.read(onboardingNotifierProvider);
      expect(state, isA<OnboardingComplete>());
    });

    test('sets OnboardingError on failure', () async {
      when(() => mockRepo.getMyStudio())
          .thenThrow(const ApiException(statusCode: 500, code: 'ERR', message: 'fail'));

      final notifier = container.read(onboardingNotifierProvider.notifier);
      await notifier.init();

      final state = container.read(onboardingNotifierProvider);
      expect(state, isA<OnboardingError>());
    });
  });

  group('createStudio', () {
    test('creates studio and advances to step 1', () async {
      when(() => mockRepo.createStudio(
            name: any(named: 'name'),
            slug: any(named: 'slug'),
            phone: any(named: 'phone'),
            address: any(named: 'address'),
            timezone: any(named: 'timezone'),
          )).thenAnswer((_) async => const StudioInfo(
            studioId: 's1',
            studioName: 'Studio Bela',
            onboardingStep: 'studio_data',
            professionalId: 'p1',
          ));

      when(() => mockRepo.updateOnboardingStep('services'))
          .thenAnswer((_) async {});

      final notifier = container.read(onboardingNotifierProvider.notifier);
      final states = <OnboardingState>[];
      container.listen(onboardingNotifierProvider, (_, next) => states.add(next));

      await notifier.createStudio(
        name: 'Studio Bela',
        slug: 'studio-bela',
      );

      expect(states.last, isA<OnboardingStep>());
      expect((states.last as OnboardingStep).currentStep, 1);
      expect((states.last as OnboardingStep).studioId, 's1');
    });

    test('sets error on SLUG_TAKEN', () async {
      when(() => mockRepo.createStudio(
            name: any(named: 'name'),
            slug: any(named: 'slug'),
            phone: any(named: 'phone'),
            address: any(named: 'address'),
            timezone: any(named: 'timezone'),
          )).thenThrow(const ApiException(
        statusCode: 409,
        code: 'SLUG_TAKEN',
        message: 'Slug already taken',
      ));

      final notifier = container.read(onboardingNotifierProvider.notifier);
      await notifier.createStudio(name: 'Test', slug: 'taken-slug');

      final state = container.read(onboardingNotifierProvider);
      expect(state, isA<OnboardingError>());
      expect((state as OnboardingError).code, 'SLUG_TAKEN');
    });
  });

  group('addServices', () {
    test('creates services and advances to step 2', () async {
      // Set up at step 1
      when(() => mockRepo.getMyStudio()).thenAnswer((_) async => const StudioInfo(
            studioId: 's1',
            studioName: 'Test',
            onboardingStep: 'services',
            professionalId: 'p1',
          ));

      final notifier = container.read(onboardingNotifierProvider.notifier);
      await notifier.init();

      when(() => mockRepo.createService(
            categoryId: any(named: 'categoryId'),
            name: any(named: 'name'),
            durationMinutes: any(named: 'durationMinutes'),
            price: any(named: 'price'),
          )).thenAnswer((_) async {});

      when(() => mockRepo.updateOnboardingStep('business_hours'))
          .thenAnswer((_) async {});

      await notifier.addServices([
        ServiceInput(categoryId: 'c1', name: 'Manicure', durationMinutes: 30, price: 5000),
      ]);

      final state = container.read(onboardingNotifierProvider);
      expect(state, isA<OnboardingStep>());
      expect((state as OnboardingStep).currentStep, 2);
    });
  });

  group('skipServices', () {
    test('advances to step 2 without creating services', () async {
      when(() => mockRepo.getMyStudio()).thenAnswer((_) async => const StudioInfo(
            studioId: 's1',
            studioName: 'Test',
            onboardingStep: 'services',
            professionalId: 'p1',
          ));

      final notifier = container.read(onboardingNotifierProvider.notifier);
      await notifier.init();

      when(() => mockRepo.updateOnboardingStep('business_hours'))
          .thenAnswer((_) async {});

      await notifier.skipServices();

      final state = container.read(onboardingNotifierProvider);
      expect((state as OnboardingStep).currentStep, 2);
      verifyNever(() => mockRepo.createService(
            categoryId: any(named: 'categoryId'),
            name: any(named: 'name'),
            durationMinutes: any(named: 'durationMinutes'),
            price: any(named: 'price'),
          ));
    });
  });

  group('setBusinessHours', () {
    test('updates working hours and completes onboarding', () async {
      when(() => mockRepo.getMyStudio()).thenAnswer((_) async => const StudioInfo(
            studioId: 's1',
            studioName: 'Test',
            onboardingStep: 'business_hours',
            professionalId: 'p1',
          ));

      final notifier = container.read(onboardingNotifierProvider.notifier);
      await notifier.init();

      final hours = {
        'monday': [
          {'open': '09:00', 'close': '18:00'}
        ],
      };

      when(() => mockRepo.updateWorkingHours('p1', any()))
          .thenAnswer((_) async {});
      when(() => mockRepo.updateOnboardingStep('complete'))
          .thenAnswer((_) async {});

      await notifier.setBusinessHours(hours);

      final state = container.read(onboardingNotifierProvider);
      expect(state, isA<OnboardingComplete>());
    });
  });

  group('goToStep', () {
    test('navigates back to completed step without API call', () async {
      when(() => mockRepo.getMyStudio()).thenAnswer((_) async => const StudioInfo(
            studioId: 's1',
            studioName: 'Test',
            onboardingStep: 'business_hours',
            professionalId: 'p1',
          ));

      final notifier = container.read(onboardingNotifierProvider.notifier);
      await notifier.init();

      // Should be at step 2 (business_hours)
      expect((container.read(onboardingNotifierProvider) as OnboardingStep).currentStep, 2);

      notifier.goToStep(0);

      final state = container.read(onboardingNotifierProvider);
      expect((state as OnboardingStep).currentStep, 0);
      // studioId and professionalId preserved
      expect(state.studioId, 's1');
    });

    test('does nothing when navigating forward', () async {
      when(() => mockRepo.getMyStudio()).thenAnswer((_) async => const StudioInfo(
            studioId: 's1',
            studioName: 'Test',
            onboardingStep: 'services',
            professionalId: 'p1',
          ));

      final notifier = container.read(onboardingNotifierProvider.notifier);
      await notifier.init();

      notifier.goToStep(2); // Try to go forward — should be ignored

      final state = container.read(onboardingNotifierProvider);
      expect((state as OnboardingStep).currentStep, 1); // Still at services
    });
  });

  group('skipBusinessHours', () {
    test('completes onboarding without updating hours', () async {
      when(() => mockRepo.getMyStudio()).thenAnswer((_) async => const StudioInfo(
            studioId: 's1',
            studioName: 'Test',
            onboardingStep: 'business_hours',
            professionalId: 'p1',
          ));

      final notifier = container.read(onboardingNotifierProvider.notifier);
      await notifier.init();

      when(() => mockRepo.updateOnboardingStep('complete'))
          .thenAnswer((_) async {});

      await notifier.skipBusinessHours();

      final state = container.read(onboardingNotifierProvider);
      expect(state, isA<OnboardingComplete>());
      verifyNever(() => mockRepo.updateWorkingHours(any(), any()));
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd mobile && flutter test test/features/onboarding/providers/onboarding_provider_test.dart
```

Expected: compilation error — `OnboardingNotifier` not found

- [ ] **Step 3: Implement OnboardingProvider**

Create `mobile/lib/features/onboarding/providers/onboarding_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/http/api_client.dart';
import '../data/onboarding_repository.dart';

// ─── State ────────────────────────────────────────────────
sealed class OnboardingState {
  const OnboardingState();
}

class OnboardingLoading extends OnboardingState {
  const OnboardingLoading();
}

class OnboardingStep extends OnboardingState {
  final int currentStep; // 0 = studio_data, 1 = services, 2 = business_hours
  final String? studioId;
  final String? professionalId;
  final bool isSaving;

  const OnboardingStep({
    required this.currentStep,
    this.studioId,
    this.professionalId,
    this.isSaving = false,
  });

  OnboardingStep copyWith({
    int? currentStep,
    String? studioId,
    String? professionalId,
    bool? isSaving,
  }) {
    return OnboardingStep(
      currentStep: currentStep ?? this.currentStep,
      studioId: studioId ?? this.studioId,
      professionalId: professionalId ?? this.professionalId,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class OnboardingComplete extends OnboardingState {
  const OnboardingComplete();
}

class OnboardingError extends OnboardingState {
  final String message;
  final String? code;

  const OnboardingError(this.message, {this.code});
}

// ─── Data transfer ────────────────────────────────────────
class ServiceInput {
  final String categoryId;
  final String name;
  final int durationMinutes;
  final int price;

  const ServiceInput({
    required this.categoryId,
    required this.name,
    required this.durationMinutes,
    required this.price,
  });
}

// ─── Step mapping ─────────────────────────────────────────
const _stepToIndex = {
  'studio_data': 0,
  'services': 1,
  'business_hours': 2,
  'complete': -1,
};

// ─── Provider ─────────────────────────────────────────────
final onboardingNotifierProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(OnboardingNotifier.new);

class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() => const OnboardingLoading();

  OnboardingRepository get _repo => ref.read(onboardingRepositoryProvider);

  Future<void> init() async {
    state = const OnboardingLoading();
    try {
      final info = await _repo.getMyStudio();
      if (info == null) {
        state = const OnboardingStep(currentStep: 0);
        return;
      }

      if (info.onboardingStep == 'complete') {
        state = const OnboardingComplete();
        return;
      }

      final stepIndex = _stepToIndex[info.onboardingStep] ?? 0;
      state = OnboardingStep(
        currentStep: stepIndex,
        studioId: info.studioId,
        professionalId: info.professionalId,
      );
    } on ApiException catch (e) {
      state = OnboardingError(e.message, code: e.code);
    } catch (e) {
      state = OnboardingError(e.toString());
    }
  }

  Future<void> createStudio({
    required String name,
    required String slug,
    String? phone,
    String? address,
    String timezone = 'America/Sao_Paulo',
  }) async {
    final prev = state;
    state = (prev is OnboardingStep)
        ? prev.copyWith(isSaving: true)
        : const OnboardingLoading();

    try {
      final info = await _repo.createStudio(
        name: name,
        slug: slug,
        phone: phone,
        address: address,
        timezone: timezone,
      );

      await _repo.updateOnboardingStep('services');

      state = OnboardingStep(
        currentStep: 1,
        studioId: info.studioId,
        professionalId: info.professionalId,
      );
    } on ApiException catch (e) {
      state = OnboardingError(e.message, code: e.code);
    } catch (e) {
      state = OnboardingError(e.toString());
    }
  }

  Future<void> addServices(List<ServiceInput> services) async {
    final prev = state as OnboardingStep;
    state = prev.copyWith(isSaving: true);

    try {
      for (final svc in services) {
        await _repo.createService(
          categoryId: svc.categoryId,
          name: svc.name,
          durationMinutes: svc.durationMinutes,
          price: svc.price,
        );
      }
      await _repo.updateOnboardingStep('business_hours');

      state = prev.copyWith(currentStep: 2, isSaving: false);
    } on ApiException catch (e) {
      state = OnboardingError(e.message, code: e.code);
    } catch (e) {
      state = OnboardingError(e.toString());
    }
  }

  Future<void> skipServices() async {
    final prev = state as OnboardingStep;
    state = prev.copyWith(isSaving: true);

    try {
      await _repo.updateOnboardingStep('business_hours');
      state = prev.copyWith(currentStep: 2, isSaving: false);
    } on ApiException catch (e) {
      state = OnboardingError(e.message, code: e.code);
    } catch (e) {
      state = OnboardingError(e.toString());
    }
  }

  Future<void> setBusinessHours(
    Map<String, List<Map<String, String>>> hours,
  ) async {
    final prev = state as OnboardingStep;
    state = prev.copyWith(isSaving: true);

    try {
      await _repo.updateWorkingHours(prev.professionalId!, hours);
      await _repo.updateOnboardingStep('complete');
      state = const OnboardingComplete();
    } on ApiException catch (e) {
      state = OnboardingError(e.message, code: e.code);
    } catch (e) {
      state = OnboardingError(e.toString());
    }
  }

  Future<void> skipBusinessHours() async {
    final prev = state as OnboardingStep;
    state = prev.copyWith(isSaving: true);

    try {
      await _repo.updateOnboardingStep('complete');
      state = const OnboardingComplete();
    } on ApiException catch (e) {
      state = OnboardingError(e.message, code: e.code);
    } catch (e) {
      state = OnboardingError(e.toString());
    }
  }

  /// Navigate back to a completed step (view-only, no API call).
  /// Used by WizardStepper when tapping a completed step circle.
  void goToStep(int step) {
    final prev = state;
    if (prev is OnboardingStep && step < prev.currentStep) {
      state = prev.copyWith(currentStep: step);
    }
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd mobile && flutter test test/features/onboarding/providers/onboarding_provider_test.dart
```

Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
cd mobile && git add lib/features/onboarding/providers/onboarding_provider.dart test/features/onboarding/providers/onboarding_provider_test.dart
git commit -m "feat(onboarding): OnboardingProvider state machine with 10 tests"
```

---

### Task 5: WizardStepper widget + tests

**Files:**
- Create: `mobile/lib/features/onboarding/presentation/widgets/wizard_stepper.dart`
- Create: `mobile/test/features/onboarding/presentation/widgets/wizard_stepper_test.dart`

**Depends on:** Nothing

- [ ] **Step 1: Write the failing tests**

Create `mobile/test/features/onboarding/presentation/widgets/wizard_stepper_test.dart`:

```dart
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

    // 3 step circles with numbers or checkmarks
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('marks current step as active', (tester) async {
    await tester.pumpWidget(buildStepper(currentStep: 1));

    // Step 2 should be active (index 1)
    // Step 1 should be completed (shows check icon)
    expect(find.byIcon(Icons.check), findsOneWidget); // step 0 completed
    expect(find.text('2'), findsOneWidget); // step 1 active number
    expect(find.text('3'), findsOneWidget); // step 2 inactive
  });

  testWidgets('marks completed steps with check icon', (tester) async {
    await tester.pumpWidget(buildStepper(currentStep: 2));

    // Steps 0 and 1 are completed
    expect(find.byIcon(Icons.check), findsNWidgets(2));
    expect(find.text('3'), findsOneWidget); // step 2 is active
  });

  testWidgets('tapping completed step calls onStepTapped', (tester) async {
    int? tapped;
    await tester.pumpWidget(buildStepper(
      currentStep: 2,
      onStepTapped: (step) => tapped = step,
    ));

    // Tap first step (completed, should be tappable)
    await tester.tap(find.byIcon(Icons.check).first);
    expect(tapped, 0);
  });

  testWidgets('tapping inactive step does NOT call onStepTapped', (tester) async {
    int? tapped;
    await tester.pumpWidget(buildStepper(
      currentStep: 0,
      onStepTapped: (step) => tapped = step,
    ));

    // Tap step 2 (inactive) — find the text '2' and tap its parent
    await tester.tap(find.text('2'));
    expect(tapped, isNull);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd mobile && flutter test test/features/onboarding/presentation/widgets/wizard_stepper_test.dart
```

Expected: compilation error — `WizardStepper` not found

- [ ] **Step 3: Implement WizardStepper**

Create `mobile/lib/features/onboarding/presentation/widgets/wizard_stepper.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class WizardStepper extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final void Function(int)? onStepTapped;

  const WizardStepper({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.onStepTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps * 2 - 1, (i) {
        if (i.isOdd) {
          // Connector line
          final stepBefore = i ~/ 2;
          final isCompleted = stepBefore < currentStep;
          return SizedBox(
            width: 40,
            child: Divider(
              thickness: 2,
              color: isCompleted ? AppColors.success : AppColors.neutral200,
            ),
          );
        }

        final stepIndex = i ~/ 2;
        final isCompleted = stepIndex < currentStep;
        final isActive = stepIndex == currentStep;

        return GestureDetector(
          onTap: isCompleted ? () => onStepTapped?.call(stepIndex) : null,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? AppColors.success
                      : isActive
                          ? AppColors.primary
                          : AppColors.neutral200,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : Text(
                          '${stepIndex + 1}',
                          style: AppTypography.caption.copyWith(
                            color: isActive ? Colors.white : AppColors.neutral400,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd mobile && flutter test test/features/onboarding/presentation/widgets/wizard_stepper_test.dart
```

Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
cd mobile && git add lib/features/onboarding/presentation/widgets/wizard_stepper.dart test/features/onboarding/presentation/widgets/wizard_stepper_test.dart
git commit -m "feat(onboarding): WizardStepper animated widget with 5 tests"
```

---

### Task 6: StudioDataStep + tests

**Files:**
- Create: `mobile/lib/features/onboarding/presentation/steps/studio_data_step.dart`
- Create: `mobile/test/features/onboarding/presentation/steps/studio_data_step_test.dart`

**Depends on:** Task 4 (OnboardingProvider)

- [ ] **Step 1: Write the failing tests**

Create `mobile/test/features/onboarding/presentation/steps/studio_data_step_test.dart`:

```dart
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

    await tester.enterText(
      find.widgetWithText(TextField, '').first,
      'Studio da Maria',
    );
    await tester.pump();

    // The slug field should contain a slugified version
    final slugField = find.byKey(const Key('slug_field'));
    expect(slugField, findsOneWidget);
    // Verify slug field has auto-generated content
    final slugTextField = tester.widget<TextField>(
      find.descendant(of: slugField, matching: find.byType(TextField)),
    );
    expect(slugTextField.controller?.text, 'studio-da-maria');
  });

  testWidgets('validates slug format', (tester) async {
    await tester.pumpWidget(buildStep());

    // Enter valid name
    await tester.enterText(
      find.widgetWithText(TextField, '').first,
      'Test',
    );
    await tester.pump();

    // Manually clear slug and enter invalid
    final slugTextField = find.byKey(const Key('slug_field'));
    await tester.enterText(
      find.descendant(of: slugTextField, matching: find.byType(TextField)),
      'AB',
    );
    await tester.pump();

    await tester.tap(find.text('Proximo'));
    await tester.pump();

    expect(find.text('URL deve ter 3-50 caracteres (letras, numeros e hifens)'), findsOneWidget);
  });

  testWidgets('shows loading spinner when saving', (tester) async {
    when(() => mockRepo.createStudio(
          name: any(named: 'name'),
          slug: any(named: 'slug'),
          phone: any(named: 'phone'),
          address: any(named: 'address'),
          timezone: any(named: 'timezone'),
        )).thenAnswer((_) async {
      // Delay to observe loading state
      await Future.delayed(const Duration(seconds: 1));
      return const StudioInfo(
        studioId: 's1',
        studioName: 'Test',
        onboardingStep: 'studio_data',
        professionalId: 'p1',
      );
    });
    when(() => mockRepo.updateOnboardingStep(any())).thenAnswer((_) async {});

    await tester.pumpWidget(buildStep());

    // Fill required fields
    await tester.enterText(find.widgetWithText(TextField, '').first, 'Test Studio');
    await tester.pump();

    await tester.tap(find.text('Proximo'));
    await tester.pump();

    // Should show loading indicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd mobile && flutter test test/features/onboarding/presentation/steps/studio_data_step_test.dart
```

Expected: compilation error — `StudioDataStep` not found

- [ ] **Step 3: Implement StudioDataStep**

Create `mobile/lib/features/onboarding/presentation/steps/studio_data_step.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/widgets/auth_text_field.dart';
import '../../providers/onboarding_provider.dart';

String _slugify(String input) {
  return input
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
      .replaceAll(RegExp(r'\s+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}

class StudioDataStep extends ConsumerStatefulWidget {
  const StudioDataStep({super.key});

  @override
  ConsumerState<StudioDataStep> createState() => _StudioDataStepState();
}

class _StudioDataStepState extends ConsumerState<StudioDataStep> {
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  String _timezone = 'America/Sao_Paulo';
  bool _slugManuallyEdited = false;

  String? _nameError;
  String? _slugError;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    if (!_slugManuallyEdited) {
      _slugController.text = _slugify(_nameController.text);
    }
  }

  bool _validate() {
    String? nameErr;
    String? slugErr;

    if (_nameController.text.trim().isEmpty) {
      nameErr = 'Nome e obrigatorio';
    }

    final slug = _slugController.text.trim();
    if (!RegExp(r'^[a-z0-9-]{3,50}$').hasMatch(slug)) {
      slugErr = 'URL deve ter 3-50 caracteres (letras, numeros e hifens)';
    }

    setState(() {
      _nameError = nameErr;
      _slugError = slugErr;
    });

    return nameErr == null && slugErr == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;

    await ref.read(onboardingNotifierProvider.notifier).createStudio(
          name: _nameController.text.trim(),
          slug: _slugController.text.trim(),
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          address: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
          timezone: _timezone,
        );
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingNotifierProvider);
    final isSaving = onboardingState is OnboardingStep && onboardingState.isSaving;

    ref.listen(onboardingNotifierProvider, (prev, next) {
      if (next is OnboardingError && next.code == 'SLUG_TAKEN') {
        setState(() {
          _slugError = 'Esta URL ja esta em uso';
        });
      }
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Dados do Estudio',
            style: AppTypography.title,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Passo 1 de 3',
            style: AppTypography.caption,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),

          // Nome
          AuthTextField(
            label: 'Nome do estudio',
            controller: _nameController,
            errorText: _nameError,
            textInputAction: TextInputAction.next,
            enabled: !isSaving,
          ),
          const SizedBox(height: AppSpacing.md),

          // Slug
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('URL publica', style: AppTypography.caption),
              const SizedBox(height: AppSpacing.xs),
              SizedBox(
                height: 48,
                key: const Key('slug_field'),
                child: Row(
                  children: [
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.neutral200,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(AppRadius.md),
                          bottomLeft: Radius.circular(AppRadius.md),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text('oriz.app/', style: AppTypography.caption),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _slugController,
                        enabled: !isSaving,
                        style: AppTypography.body,
                        onChanged: (_) => _slugManuallyEdited = true,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.neutral100,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          border: OutlineInputBorder(
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(AppRadius.md),
                              bottomRight: Radius.circular(AppRadius.md),
                            ),
                            borderSide: BorderSide(
                              color: _slugError != null
                                  ? AppColors.error
                                  : AppColors.neutral200,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(AppRadius.md),
                              bottomRight: Radius.circular(AppRadius.md),
                            ),
                            borderSide: BorderSide(
                              color: _slugError != null
                                  ? AppColors.error
                                  : AppColors.neutral200,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(AppRadius.md),
                              bottomRight: Radius.circular(AppRadius.md),
                            ),
                            borderSide: BorderSide(
                              color: _slugError != null
                                  ? AppColors.error
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_slugError != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _slugError!,
                  style: AppTypography.caption.copyWith(color: AppColors.error),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Telefone
          AuthTextField(
            label: 'Telefone',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            enabled: !isSaving,
          ),
          const SizedBox(height: AppSpacing.md),

          // Endereco
          AuthTextField(
            label: 'Endereco',
            controller: _addressController,
            textInputAction: TextInputAction.next,
            enabled: !isSaving,
          ),
          const SizedBox(height: AppSpacing.md),

          // Fuso horario
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Fuso horario', style: AppTypography.caption),
              const SizedBox(height: AppSpacing.xs),
              SizedBox(
                height: 48,
                child: DropdownButtonFormField<String>(
                  value: _timezone,
                  isExpanded: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.neutral100,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(color: AppColors.neutral200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(color: AppColors.neutral200),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'America/Sao_Paulo',
                      child: Text('Brasilia (GMT-3)'),
                    ),
                    DropdownMenuItem(
                      value: 'America/Manaus',
                      child: Text('Manaus (GMT-4)'),
                    ),
                    DropdownMenuItem(
                      value: 'America/Belem',
                      child: Text('Belem (GMT-3)'),
                    ),
                    DropdownMenuItem(
                      value: 'America/Cuiaba',
                      child: Text('Cuiaba (GMT-4)'),
                    ),
                    DropdownMenuItem(
                      value: 'America/Recife',
                      child: Text('Recife (GMT-3)'),
                    ),
                    DropdownMenuItem(
                      value: 'America/Fortaleza',
                      child: Text('Fortaleza (GMT-3)'),
                    ),
                  ],
                  onChanged: isSaving
                      ? null
                      : (value) {
                          if (value != null) setState(() => _timezone = value);
                        },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Botao
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: isSaving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primary.withAlpha(102),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accent,
                      ),
                    )
                  : Text('Proximo',
                      style: AppTypography.bodySemibold.copyWith(color: Colors.white)),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
```

**Note:** `AppRadius.md` is defined in `lib/core/theme/app_spacing.dart` (same file as AppSpacing).

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd mobile && flutter test test/features/onboarding/presentation/steps/studio_data_step_test.dart
```

Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
cd mobile && git add lib/features/onboarding/presentation/steps/studio_data_step.dart test/features/onboarding/presentation/steps/studio_data_step_test.dart
git commit -m "feat(onboarding): StudioDataStep with slug auto-generation + 4 tests"
```

---

### Task 7: ServiceTemplateCard widget + tests

**Files:**
- Create: `mobile/lib/features/onboarding/presentation/widgets/service_template_card.dart`
- Create: `mobile/test/features/onboarding/presentation/widgets/service_template_card_test.dart`

**Depends on:** Task 3 (service_templates)

- [ ] **Step 1: Write the failing tests**

Create `mobile/test/features/onboarding/presentation/widgets/service_template_card_test.dart`:

```dart
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
    // Duration dropdown showing 30min
    expect(find.text('30 min'), findsOneWidget);
    // Price field showing R$ 50,00 (inside TextField, use widgetWithText)
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

    // Find name text field and change it
    final nameField = find.widgetWithText(TextField, 'Manicure');
    await tester.enterText(nameField, 'Manicure Gel');
    await tester.pump();

    expect(newName, 'Manicure Gel');
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd mobile && flutter test test/features/onboarding/presentation/widgets/service_template_card_test.dart
```

Expected: compilation error

- [ ] **Step 3: Implement ServiceTemplateCard**

Create `mobile/lib/features/onboarding/presentation/widgets/service_template_card.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Durations from 15min to 240min in 15min increments
const _durationOptions = [15, 30, 45, 60, 75, 90, 105, 120, 150, 180, 210, 240];

String _formatPrice(int cents) {
  final reais = cents ~/ 100;
  final centavos = cents % 100;
  return 'R\$ $reais,${centavos.toString().padLeft(2, '0')}';
}

int _parsePrice(String text) {
  final cleaned = text.replaceAll(RegExp(r'[^0-9]'), '');
  return int.tryParse(cleaned) ?? 0;
}

class ServiceTemplateCard extends StatefulWidget {
  final String name;
  final int durationMinutes;
  final int price; // centavos
  final VoidCallback onRemove;
  final void Function(String name, int durationMinutes, int price) onChanged;

  const ServiceTemplateCard({
    super.key,
    required this.name,
    required this.durationMinutes,
    required this.price,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<ServiceTemplateCard> createState() => _ServiceTemplateCardState();
}

class _ServiceTemplateCardState extends State<ServiceTemplateCard> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late int _duration;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _priceController = TextEditingController(text: _formatPrice(widget.price));
    _duration = widget.durationMinutes;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _notifyChanged() {
    widget.onChanged(
      _nameController.text,
      _duration,
      _parsePrice(_priceController.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Name + remove button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  style: AppTypography.bodySemibold,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                  onChanged: (_) => _notifyChanged(),
                ),
              ),
              SizedBox(
                width: 44,
                height: 44,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 18, color: AppColors.neutral400),
                  onPressed: widget.onRemove,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Duration + Price row
          Row(
            children: [
              // Duration dropdown
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _durationOptions.contains(_duration) ? _duration : 30,
                  isExpanded: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      borderSide: const BorderSide(color: AppColors.neutral200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      borderSide: const BorderSide(color: AppColors.neutral200),
                    ),
                  ),
                  items: _durationOptions
                      .map((d) => DropdownMenuItem(
                            value: d,
                            child: Text('$d min', style: AppTypography.caption),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _duration = value);
                      _notifyChanged();
                    }
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Price field
              Expanded(
                child: TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  style: AppTypography.caption,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      borderSide: const BorderSide(color: AppColors.neutral200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      borderSide: const BorderSide(color: AppColors.neutral200),
                    ),
                  ),
                  onChanged: (_) => _notifyChanged(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd mobile && flutter test test/features/onboarding/presentation/widgets/service_template_card_test.dart
```

Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
cd mobile && git add lib/features/onboarding/presentation/widgets/service_template_card.dart test/features/onboarding/presentation/widgets/service_template_card_test.dart
git commit -m "feat(onboarding): ServiceTemplateCard editable widget with 3 tests"
```

---

### Task 8: ServicesStep + tests

**Files:**
- Create: `mobile/lib/features/onboarding/presentation/steps/services_step.dart`
- Create: `mobile/test/features/onboarding/presentation/steps/services_step_test.dart`

**Depends on:** Tasks 3, 4, 7 (templates, provider, ServiceTemplateCard)

- [ ] **Step 1: Write the failing tests**

Create `mobile/test/features/onboarding/presentation/steps/services_step_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oriz/features/onboarding/data/onboarding_repository.dart';
import 'package:oriz/features/onboarding/presentation/steps/services_step.dart';
import 'package:oriz/features/onboarding/providers/onboarding_provider.dart';

class MockOnboardingRepository extends Mock implements OnboardingRepository {}

void main() {
  late MockOnboardingRepository mockRepo;

  setUp(() {
    mockRepo = MockOnboardingRepository();
    when(() => mockRepo.getServiceCategories()).thenAnswer(
      (_) async => [
        const ServiceCategory(id: 'c1', name: 'Unhas'),
        const ServiceCategory(id: 'c2', name: 'Cilios'),
      ],
    );
  });

  Widget buildStep() {
    return ProviderScope(
      overrides: [
        onboardingRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: const MaterialApp(
        home: Scaffold(body: ServicesStep()),
      ),
    );
  }

  testWidgets('renders category chips', (tester) async {
    await tester.pumpWidget(buildStep());
    await tester.pumpAndSettle(); // resolve async category load

    expect(find.text('Unhas'), findsOneWidget);
    expect(find.text('Cilios'), findsOneWidget);
    expect(find.text('Cabelo'), findsOneWidget);
    expect(find.text('Micropigmentacao'), findsOneWidget);
  });

  testWidgets('selecting category shows templates', (tester) async {
    await tester.pumpWidget(buildStep());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Unhas'));
    await tester.pump();

    expect(find.text('Manicure'), findsOneWidget);
    expect(find.text('Pedicure'), findsOneWidget);
    expect(find.text('Esmaltacao em gel'), findsOneWidget);
  });

  testWidgets('shows custom service button', (tester) async {
    await tester.pumpWidget(buildStep());
    await tester.pumpAndSettle();

    expect(find.text('+ Servico personalizado'), findsOneWidget);
  });

  testWidgets('skip link present', (tester) async {
    await tester.pumpWidget(buildStep());
    await tester.pumpAndSettle();

    expect(find.text('Pular por agora'), findsOneWidget);
  });

  testWidgets('tapping custom adds empty card', (tester) async {
    await tester.pumpWidget(buildStep());
    await tester.pumpAndSettle();

    await tester.tap(find.text('+ Servico personalizado'));
    await tester.pump();

    // Should find a close button for the new card
    expect(find.byIcon(Icons.close), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd mobile && flutter test test/features/onboarding/presentation/steps/services_step_test.dart
```

Expected: compilation error

- [ ] **Step 3: Implement ServicesStep**

Create `mobile/lib/features/onboarding/presentation/steps/services_step.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/onboarding_repository.dart';
import '../../data/service_templates.dart';
import '../../providers/onboarding_provider.dart';
import '../widgets/service_template_card.dart';

class _EditableService {
  String categoryId;
  String name;
  int durationMinutes;
  int price;

  _EditableService({
    required this.categoryId,
    required this.name,
    required this.durationMinutes,
    required this.price,
  });
}

class ServicesStep extends ConsumerStatefulWidget {
  const ServicesStep({super.key});

  @override
  ConsumerState<ServicesStep> createState() => _ServicesStepState();
}

class _ServicesStepState extends ConsumerState<ServicesStep> {
  final Set<String> _selectedCategories = {};
  final List<_EditableService> _services = [];
  Map<String, String> _categoryIdMap = {}; // name → uuid
  bool _categoriesLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final repo = ref.read(onboardingRepositoryProvider);
      final categories = await repo.getServiceCategories();
      if (mounted) {
        setState(() {
          _categoryIdMap = {for (final c in categories) c.name: c.id};
          _categoriesLoaded = true;
        });
      }
    } catch (_) {
      // Categories are nice-to-have; templates still work without IDs
      if (mounted) setState(() => _categoriesLoaded = true);
    }
  }

  void _toggleCategory(String category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
        _services.removeWhere((s) => s.categoryId == category);
      } else {
        _selectedCategories.add(category);
        final templates = templatesForCategory(category);
        for (final t in templates) {
          _services.add(_EditableService(
            categoryId: _categoryIdMap[t.category] ?? category,
            name: t.name,
            durationMinutes: t.durationMinutes,
            price: t.price,
          ));
        }
      }
    });
  }

  void _addCustomService() {
    setState(() {
      _services.add(_EditableService(
        categoryId: _categoryIdMap['Outro'] ?? 'custom',
        name: '',
        durationMinutes: 30,
        price: 0,
      ));
    });
  }

  void _removeService(int index) {
    setState(() => _services.removeAt(index));
  }

  void _updateService(int index, String name, int duration, int price) {
    _services[index]
      ..name = name
      ..durationMinutes = duration
      ..price = price;
  }

  Future<void> _submit() async {
    final validServices = _services.where((s) => s.name.trim().isNotEmpty).toList();
    if (validServices.isEmpty) {
      await _skip();
      return;
    }

    final notifier = ref.read(onboardingNotifierProvider.notifier);
    await notifier.addServices(
      validServices
          .map((s) => ServiceInput(
                categoryId: s.categoryId,
                name: s.name,
                durationMinutes: s.durationMinutes,
                price: s.price,
              ))
          .toList(),
    );
  }

  Future<void> _skip() async {
    await ref.read(onboardingNotifierProvider.notifier).skipServices();
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingNotifierProvider);
    final isSaving = onboardingState is OnboardingStep && onboardingState.isSaving;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.lg),
          Text('Servicos', style: AppTypography.title, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xs),
          Text('Passo 2 de 3', style: AppTypography.caption, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xl),

          // Category chips
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: categoryNames.map((cat) {
              final selected = _selectedCategories.contains(cat);
              return FilterChip(
                label: Text(cat),
                selected: selected,
                onSelected: isSaving ? null : (_) => _toggleCategory(cat),
                selectedColor: AppColors.accentSoft,
                checkmarkColor: AppColors.primary,
                labelStyle: AppTypography.caption.copyWith(
                  color: selected ? AppColors.primary : AppColors.neutral600,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Service cards
          ...List.generate(_services.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ServiceTemplateCard(
                name: _services[i].name,
                durationMinutes: _services[i].durationMinutes,
                price: _services[i].price,
                onRemove: () => _removeService(i),
                onChanged: (name, dur, price) => _updateService(i, name, dur, price),
              ),
            );
          }),

          // Add custom button
          TextButton.icon(
            onPressed: isSaving ? null : _addCustomService,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('+ Servico personalizado'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              minimumSize: const Size(44, 44),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Submit button
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: isSaving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primary.withAlpha(102),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accent,
                      ),
                    )
                  : Text('Proximo',
                      style: AppTypography.bodySemibold.copyWith(color: Colors.white)),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Skip link
          Center(
            child: TextButton(
              onPressed: isSaving ? null : _skip,
              style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
              child: Text(
                'Pular por agora',
                style: AppTypography.caption.copyWith(color: AppColors.neutral600),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd mobile && flutter test test/features/onboarding/presentation/steps/services_step_test.dart
```

Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
cd mobile && git add lib/features/onboarding/presentation/steps/services_step.dart test/features/onboarding/presentation/steps/services_step_test.dart
git commit -m "feat(onboarding): ServicesStep with category chips and templates + 5 tests"
```

---

### Task 9: DayHoursCard widget + tests

**Files:**
- Create: `mobile/lib/features/onboarding/presentation/widgets/day_hours_card.dart`
- Create: `mobile/test/features/onboarding/presentation/widgets/day_hours_card_test.dart`

**Depends on:** Nothing

- [ ] **Step 1: Write the failing tests**

Create `mobile/test/features/onboarding/presentation/widgets/day_hours_card_test.dart`:

```dart
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

    expect(find.text('09:00'), findsOneWidget);
    expect(find.text('18:00'), findsOneWidget);
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
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd mobile && flutter test test/features/onboarding/presentation/widgets/day_hours_card_test.dart
```

Expected: compilation error

- [ ] **Step 3: Implement DayHoursCard**

Create `mobile/lib/features/onboarding/presentation/widgets/day_hours_card.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class TimeRange {
  final String open;
  final String close;

  const TimeRange({required this.open, required this.close});
}

/// Generates time options from 00:00 to 23:45 in 15-minute increments
List<String> get timeOptions {
  final options = <String>[];
  for (var h = 0; h < 24; h++) {
    for (var m = 0; m < 60; m += 15) {
      options.add('${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}');
    }
  }
  return options;
}

class DayHoursCard extends StatelessWidget {
  final String dayLabel;
  final bool enabled;
  final List<TimeRange> ranges;
  final void Function(bool enabled, List<TimeRange> ranges) onChanged;

  const DayHoursCard({
    super.key,
    required this.dayLabel,
    required this.enabled,
    required this.ranges,
    required this.onChanged,
  });

  void _toggleEnabled() {
    onChanged(!enabled, ranges);
  }

  void _addRange() {
    onChanged(enabled, [...ranges, const TimeRange(open: '09:00', close: '18:00')]);
  }

  void _removeRange(int index) {
    if (ranges.length <= 1) return;
    final updated = [...ranges]..removeAt(index);
    onChanged(enabled, updated);
  }

  void _updateOpen(int index, String value) {
    final updated = [...ranges];
    updated[index] = TimeRange(open: value, close: updated[index].close);
    onChanged(enabled, updated);
  }

  void _updateClose(int index, String value) {
    final updated = [...ranges];
    updated[index] = TimeRange(open: updated[index].open, close: value);
    onChanged(enabled, updated);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: enabled ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.neutral100,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: day label + toggle
            Row(
              children: [
                Text(dayLabel, style: AppTypography.bodySemibold),
                const Spacer(),
                Switch(
                  value: enabled,
                  onChanged: (_) => _toggleEnabled(),
                  activeColor: AppColors.primary,
                ),
              ],
            ),

            if (!enabled)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text('Fechado',
                    style: AppTypography.caption.copyWith(color: AppColors.neutral400)),
              ),

            if (enabled) ...[
              // Time ranges
              ...List.generate(ranges.length, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      // Open time dropdown
                      Expanded(
                        child: _TimeDropdown(
                          value: ranges[i].open,
                          onChanged: (v) => _updateOpen(i, v),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                        child: Text('ate', style: AppTypography.caption),
                      ),
                      // Close time dropdown
                      Expanded(
                        child: _TimeDropdown(
                          value: ranges[i].close,
                          onChanged: (v) => _updateClose(i, v),
                        ),
                      ),
                      // Remove button (only if >1 range)
                      if (ranges.length > 1)
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: IconButton(
                            icon: const Icon(Icons.close, size: 16, color: AppColors.neutral400),
                            onPressed: () => _removeRange(i),
                          ),
                        ),
                    ],
                  ),
                );
              }),

              // Add interval link
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _addRange,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    foregroundColor: AppColors.primary,
                  ),
                  child: Text('+ Intervalo', style: AppTypography.caption.copyWith(color: AppColors.primary)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimeDropdown extends StatelessWidget {
  final String value;
  final void Function(String) onChanged;

  const _TimeDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final options = timeOptions;
    return DropdownButtonFormField<String>(
      value: options.contains(value) ? value : '09:00',
      isExpanded: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.neutral200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.neutral200),
        ),
      ),
      items: options
          .map((t) => DropdownMenuItem(value: t, child: Text(t, style: AppTypography.caption)))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd mobile && flutter test test/features/onboarding/presentation/widgets/day_hours_card_test.dart
```

Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
cd mobile && git add lib/features/onboarding/presentation/widgets/day_hours_card.dart test/features/onboarding/presentation/widgets/day_hours_card_test.dart
git commit -m "feat(onboarding): DayHoursCard with toggle + multi-interval + 6 tests"
```

---

### Task 10: BusinessHoursStep + tests

**Files:**
- Create: `mobile/lib/features/onboarding/presentation/steps/business_hours_step.dart`
- Create: `mobile/test/features/onboarding/presentation/steps/business_hours_step_test.dart`

**Depends on:** Tasks 4, 9 (provider, DayHoursCard)

- [ ] **Step 1: Write the failing tests**

Create `mobile/test/features/onboarding/presentation/steps/business_hours_step_test.dart`:

```dart
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

    // 7 switches total
    expect(find.byType(Switch), findsNWidgets(7));

    // Dom should show Fechado
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
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd mobile && flutter test test/features/onboarding/presentation/steps/business_hours_step_test.dart
```

Expected: compilation error

- [ ] **Step 3: Implement BusinessHoursStep**

Create `mobile/lib/features/onboarding/presentation/steps/business_hours_step.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../providers/onboarding_provider.dart';
import '../widgets/day_hours_card.dart';

const _dayKeys = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
const _dayLabels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab', 'Dom'];

class _DayState {
  bool enabled;
  List<TimeRange> ranges;

  _DayState({required this.enabled, required this.ranges});
}

class BusinessHoursStep extends ConsumerStatefulWidget {
  const BusinessHoursStep({super.key});

  @override
  ConsumerState<BusinessHoursStep> createState() => _BusinessHoursStepState();
}

class _BusinessHoursStepState extends ConsumerState<BusinessHoursStep> {
  late final List<_DayState> _days;

  @override
  void initState() {
    super.initState();
    _days = List.generate(7, (i) {
      final isSunday = i == 6;
      return _DayState(
        enabled: !isSunday,
        ranges: isSunday
            ? []
            : [const TimeRange(open: '09:00', close: '18:00')],
      );
    });
  }

  Map<String, List<Map<String, String>>> _buildHoursPayload() {
    final result = <String, List<Map<String, String>>>{};
    for (var i = 0; i < 7; i++) {
      result[_dayKeys[i]] = _days[i].enabled
          ? _days[i].ranges.map((r) => {'open': r.open, 'close': r.close}).toList()
          : [];
    }
    return result;
  }

  Future<void> _submit() async {
    await ref.read(onboardingNotifierProvider.notifier).setBusinessHours(
          _buildHoursPayload(),
        );
  }

  Future<void> _skip() async {
    await ref.read(onboardingNotifierProvider.notifier).skipBusinessHours();
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingNotifierProvider);
    final isSaving = onboardingState is OnboardingStep && onboardingState.isSaving;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.lg),
          Text('Horarios', style: AppTypography.title, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xs),
          Text('Passo 3 de 3', style: AppTypography.caption, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xl),

          // Day cards
          ...List.generate(7, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: DayHoursCard(
                dayLabel: _dayLabels[i],
                enabled: _days[i].enabled,
                ranges: _days[i].ranges,
                onChanged: (enabled, ranges) {
                  setState(() {
                    _days[i].enabled = enabled;
                    _days[i].ranges = ranges.isEmpty && enabled
                        ? [const TimeRange(open: '09:00', close: '18:00')]
                        : ranges;
                  });
                },
              ),
            );
          }),

          const SizedBox(height: AppSpacing.lg),

          // Submit button
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: isSaving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primary.withAlpha(102),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accent,
                      ),
                    )
                  : Text('Concluir',
                      style: AppTypography.bodySemibold.copyWith(color: Colors.white)),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Skip link
          Center(
            child: TextButton(
              onPressed: isSaving ? null : _skip,
              style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
              child: Text(
                'Pular por agora',
                style: AppTypography.caption.copyWith(color: AppColors.neutral600),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd mobile && flutter test test/features/onboarding/presentation/steps/business_hours_step_test.dart
```

Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
cd mobile && git add lib/features/onboarding/presentation/steps/business_hours_step.dart test/features/onboarding/presentation/steps/business_hours_step_test.dart
git commit -m "feat(onboarding): BusinessHoursStep with 7-day defaults + 4 tests"
```

---

### Task 11: OnboardingWizardScreen + tests

**Files:**
- Create: `mobile/lib/features/onboarding/presentation/onboarding_wizard_screen.dart`
- Create: `mobile/test/features/onboarding/presentation/onboarding_wizard_screen_test.dart`

**Depends on:** Tasks 4, 5, 6, 8, 10 (provider, stepper, all steps)

- [ ] **Step 1: Write the failing tests**

Create `mobile/test/features/onboarding/presentation/onboarding_wizard_screen_test.dart`:

```dart
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
    when(() => mockRepo.getMyStudio()).thenAnswer((_) async => null);
    when(() => mockRepo.getServiceCategories()).thenAnswer((_) async => []);
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
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd mobile && flutter test test/features/onboarding/presentation/onboarding_wizard_screen_test.dart
```

Expected: compilation error

- [ ] **Step 3: Implement OnboardingWizardScreen**

Create `mobile/lib/features/onboarding/presentation/onboarding_wizard_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../providers/onboarding_provider.dart';
import 'steps/business_hours_step.dart';
import 'steps/services_step.dart';
import 'steps/studio_data_step.dart';
import 'widgets/wizard_stepper.dart';

class OnboardingWizardScreen extends ConsumerStatefulWidget {
  const OnboardingWizardScreen({super.key});

  @override
  ConsumerState<OnboardingWizardScreen> createState() => _OnboardingWizardScreenState();
}

class _OnboardingWizardScreenState extends ConsumerState<OnboardingWizardScreen> {
  final _pageController = PageController();

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(onboardingNotifierProvider.notifier).init(),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _animateToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingNotifierProvider);

    ref.listen(onboardingNotifierProvider, (prev, next) {
      // Animate page on step change
      if (next is OnboardingStep && prev is OnboardingStep) {
        if (next.currentStep != prev.currentStep) {
          _animateToPage(next.currentStep);
        }
      }
      if (next is OnboardingStep && prev is OnboardingLoading) {
        if (next.currentStep > 0) {
          // Jump without animation on initial resume
          _pageController.jumpToPage(next.currentStep);
        }
      }
      // Navigate to complete screen
      if (next is OnboardingComplete) {
        context.go('/onboarding/complete');
      }
    });

    if (state is OnboardingLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    if (state is OnboardingError) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(state.message),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: () =>
                    ref.read(onboardingNotifierProvider.notifier).init(),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final currentStep = (state is OnboardingStep) ? state.currentStep : 0;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.lg),
            WizardStepper(
              currentStep: currentStep,
              totalSteps: 3,
              onStepTapped: (step) {
                ref.read(onboardingNotifierProvider.notifier).goToStep(step);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  StudioDataStep(),
                  ServicesStep(),
                  BusinessHoursStep(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd mobile && flutter test test/features/onboarding/presentation/onboarding_wizard_screen_test.dart
```

Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
cd mobile && git add lib/features/onboarding/presentation/onboarding_wizard_screen.dart test/features/onboarding/presentation/onboarding_wizard_screen_test.dart
git commit -m "feat(onboarding): OnboardingWizardScreen container with PageView + 3 tests"
```

---

### Task 12: OnboardingCompleteScreen + tests

**Files:**
- Create: `mobile/lib/features/onboarding/presentation/onboarding_complete_screen.dart`
- Create: `mobile/test/features/onboarding/presentation/onboarding_complete_screen_test.dart`

**Depends on:** Task 4 (provider)

- [ ] **Step 1: Write the failing tests**

Create `mobile/test/features/onboarding/presentation/onboarding_complete_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:oriz/features/onboarding/presentation/onboarding_complete_screen.dart';

void main() {
  testWidgets('renders success message', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const OnboardingCompleteScreen(),
      ),
    );

    expect(find.text('Seu estudio esta pronto!'), findsOneWidget);
    expect(find.text('Agora voce pode agendar seus primeiros atendimentos.'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
  });

  testWidgets('has button to go to agenda', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const OnboardingCompleteScreen(),
      ),
    );

    expect(find.text('Ir para Agenda'), findsOneWidget);
  });

  testWidgets('button navigates to /agenda', (tester) async {
    String? navigatedTo;

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/onboarding/complete',
          routes: [
            GoRoute(
              path: '/onboarding/complete',
              builder: (_, __) => const OnboardingCompleteScreen(),
            ),
            GoRoute(
              path: '/agenda',
              builder: (_, __) {
                navigatedTo = '/agenda';
                return const Scaffold(body: Text('Agenda'));
              },
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('Ir para Agenda'));
    await tester.pumpAndSettle();

    expect(navigatedTo, '/agenda');
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd mobile && flutter test test/features/onboarding/presentation/onboarding_complete_screen_test.dart
```

Expected: compilation error

- [ ] **Step 3: Implement OnboardingCompleteScreen**

Create `mobile/lib/features/onboarding/presentation/onboarding_complete_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class OnboardingCompleteScreen extends StatefulWidget {
  const OnboardingCompleteScreen({super.key});

  @override
  State<OnboardingCompleteScreen> createState() => _OnboardingCompleteScreenState();
}

class _OnboardingCompleteScreenState extends State<OnboardingCompleteScreen> {
  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 80,
                color: AppColors.success,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Seu estudio esta pronto!',
                style: AppTypography.display,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Agora voce pode agendar seus primeiros atendimentos.',
                style: AppTypography.body.copyWith(color: AppColors.neutral600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () => context.go('/agenda'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: Text(
                    'Ir para Agenda',
                    style: AppTypography.bodySemibold.copyWith(color: Colors.white),
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

```bash
cd mobile && flutter test test/features/onboarding/presentation/onboarding_complete_screen_test.dart
```

Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
cd mobile && git add lib/features/onboarding/presentation/onboarding_complete_screen.dart test/features/onboarding/presentation/onboarding_complete_screen_test.dart
git commit -m "feat(onboarding): OnboardingCompleteScreen with haptic + 3 tests"
```

---

### Task 13: Router update + main.dart wiring + tests

**Files:**
- Modify: `mobile/lib/core/router/app_router.dart`
- Modify: `mobile/lib/main.dart`
- Replace: `mobile/test/core/router/app_router_test.dart`

**Depends on:** Tasks 2, 11, 12 (repo, wizard screen, complete screen)

- [ ] **Step 1: Write the router tests (replaces existing test file)**

**IMPORTANT:** This file already exists at `mobile/test/core/router/app_router_test.dart` with 2 tests. We must REPLACE it entirely because the router now requires `onboardingRepositoryProvider`. The existing tests are incorporated below with the new override.

Replace `mobile/test/core/router/app_router_test.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oriz/core/router/app_router.dart';
import 'package:oriz/features/auth/data/auth_repository.dart';
import 'package:oriz/features/auth/providers/auth_provider.dart';
import 'package:oriz/features/onboarding/data/onboarding_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

class MockAuthRepository extends Mock implements AuthRepository {}

class MockOnboardingRepository extends Mock implements OnboardingRepository {}

class _FakeSession implements Session {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockAuthRepository mockAuth;
  late MockOnboardingRepository mockOnboarding;

  setUp(() {
    mockAuth = MockAuthRepository();
    mockOnboarding = MockOnboardingRepository();
    when(() => mockAuth.onAuthStateChange).thenAnswer((_) => const Stream.empty());
  });

  Widget buildApp({required bool hasSession}) {
    when(() => mockAuth.currentSession).thenReturn(
      hasSession ? _FakeSession() : null,
    );

    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuth),
        onboardingRepositoryProvider.overrideWithValue(mockOnboarding),
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

    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets('redirects authenticated user without studio to /onboarding', (tester) async {
    when(() => mockOnboarding.getMyStudio()).thenAnswer((_) async => null);

    await tester.pumpWidget(buildApp(hasSession: true));
    await tester.pumpAndSettle();

    // Should land on onboarding wizard (studio check returns null → noStudio → /onboarding)
    expect(find.text('Dados do Estudio'), findsOneWidget);
  });

  testWidgets('redirects to /agenda when session exists and onboarding complete', (tester) async {
    when(() => mockOnboarding.getMyStudio()).thenAnswer(
      (_) async => const StudioInfo(
        studioId: 's1',
        studioName: 'Test',
        onboardingStep: 'complete',
        professionalId: 'p1',
      ),
    );

    await tester.pumpWidget(buildApp(hasSession: true));
    await tester.pumpAndSettle();

    expect(find.text('Agenda'), findsWidgets);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd mobile && flutter test test/core/router/app_router_test.dart
```

Expected: fails — new tests reference onboarding imports/routes that don't exist yet in router

- [ ] **Step 3: Update app_router.dart**

Replace the full content of `mobile/lib/core/router/app_router.dart`:

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
import '../../features/onboarding/data/onboarding_repository.dart';
import '../../features/onboarding/presentation/onboarding_complete_screen.dart';
import '../../features/onboarding/presentation/onboarding_wizard_screen.dart';
import '../shell/app_shell.dart';

/// Listenable that notifies GoRouter when auth state changes.
class AuthNotifierListenable extends ChangeNotifier {
  AuthNotifierListenable(Ref ref) {
    ref.listen(authNotifierProvider, (_, __) => notifyListeners());
  }
}

/// Tracks studio state for routing decisions.
/// Updated after onboarding check and on auth changes.
final studioStateProvider =
    StateProvider<StudioRouteState>((ref) => const StudioRouteState.unknown());

sealed class StudioRouteState {
  const StudioRouteState();
  const factory StudioRouteState.unknown() = StudioUnknown;
  const factory StudioRouteState.noStudio() = StudioNotFound;
  const factory StudioRouteState.hasStudio({required bool onboardingComplete}) =
      StudioExists;
}

class StudioUnknown extends StudioRouteState {
  const StudioUnknown();
}

class StudioNotFound extends StudioRouteState {
  const StudioNotFound();
}

class StudioExists extends StudioRouteState {
  final bool onboardingComplete;
  const StudioExists({required this.onboardingComplete});
}

final routerProvider = Provider<GoRouter>((ref) {
  final authRepo = ref.read(authRepositoryProvider);
  final authListenable = AuthNotifierListenable(ref);

  // Check studio on first authenticated load
  Future<void> checkStudio() async {
    try {
      final onboardingRepo = ref.read(onboardingRepositoryProvider);
      final info = await onboardingRepo.getMyStudio();
      if (info == null) {
        ref.read(studioStateProvider.notifier).state =
            const StudioRouteState.noStudio();
      } else {
        ref.read(studioStateProvider.notifier).state =
            StudioRouteState.hasStudio(
          onboardingComplete: info.onboardingStep == 'complete',
        );
      }
    } catch (_) {
      ref.read(studioStateProvider.notifier).state =
          const StudioRouteState.noStudio();
    }
  }

  // Trigger studio check when auth state becomes authenticated
  ref.listen(authNotifierProvider, (prev, next) {
    if (next is AuthAuthenticated && prev is! AuthAuthenticated) {
      checkStudio();
    }
    if (next is AuthUnauthenticated) {
      ref.read(studioStateProvider.notifier).state =
          const StudioRouteState.unknown();
    }
  });

  // Also listen to studio state changes for re-routing
  ref.listen(studioStateProvider, (_, __) {
    authListenable.notifyListeners();
  });

  // Initial check if already authenticated
  if (authRepo.currentSession != null) {
    Future.microtask(checkStudio);
  }

  return GoRouter(
    initialLocation: '/agenda',
    refreshListenable: authListenable,
    redirect: (context, state) {
      final hasSession = authRepo.currentSession != null;
      final path = state.matchedLocation;

      final isAuthRoute = path == '/login' ||
          path == '/signup' ||
          path == '/forgot-password';
      final isOnboardingRoute = path.startsWith('/onboarding');

      // Not logged in → login
      if (!hasSession && !isAuthRoute) return '/login';

      // Logged in on auth page → check studio state
      if (hasSession && isAuthRoute) {
        final studio = ref.read(studioStateProvider);
        if (studio is StudioNotFound) return '/onboarding';
        if (studio is StudioExists && !studio.onboardingComplete) {
          return '/onboarding';
        }
        return '/agenda';
      }

      // Logged in, not on auth page → check studio-based redirects
      if (hasSession && !isAuthRoute && !isOnboardingRoute) {
        final studio = ref.read(studioStateProvider);
        if (studio is StudioNotFound) return '/onboarding';
        if (studio is StudioExists && !studio.onboardingComplete) {
          return '/onboarding';
        }
      }

      // On onboarding route but already completed → agenda
      if (hasSession && isOnboardingRoute) {
        final studio = ref.read(studioStateProvider);
        if (studio is StudioExists && studio.onboardingComplete) {
          return '/agenda';
        }
      }

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

      // Onboarding routes (no shell)
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingWizardScreen(),
      ),
      GoRoute(
        path: '/onboarding/complete',
        builder: (_, __) => const OnboardingCompleteScreen(),
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

- [ ] **Step 4: Update main.dart to add OnboardingRepository override**

In `mobile/lib/main.dart`, add the import and override:

Add import at top:
```dart
import 'core/http/api_client.dart';
import 'features/onboarding/data/onboarding_repository.dart';
```

Update the `ProviderScope` overrides to include `onboardingRepositoryProvider`:

```dart
  runApp(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          AuthRepository(supabase.auth),
        ),
        onboardingRepositoryProvider.overrideWithValue(
          OnboardingRepository(
            ApiClient(
              baseUrl: const String.fromEnvironment(
                'API_BASE_URL',
                defaultValue: 'http://localhost:3000',
              ),
              auth: supabase.auth,
            ),
          ),
        ),
      ],
      child: const OrizApp(),
    ),
  );
```

- [ ] **Step 5: Run all tests**

```bash
cd mobile && flutter test
```

Expected: All tests pass (existing + new)

- [ ] **Step 6: Commit**

```bash
cd mobile && git add lib/core/router/app_router.dart lib/main.dart test/core/router/app_router_test.dart
git commit -m "feat(onboarding): router update with studio redirect logic + provider wiring"
```

---

## Final Verification

After all tasks are done:

```bash
cd mobile && flutter test
cd mobile && flutter analyze
```

All tests should pass and analysis should show no issues.
