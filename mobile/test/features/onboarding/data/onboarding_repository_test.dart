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

      expect(result, isNotNull);
      expect(result!.studioId, 's1');
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

  group('getGlobalCategories', () {
    test('returns list of categories', () async {
      when(() => mockClient.get('/api/v1/service-categories?scope=global')).thenAnswer(
        (_) async => {
          'data': [
            {'id': 'c1', 'name': 'Unhas'},
            {'id': 'c2', 'name': 'Cilios'},
          ]
        },
      );

      final result = await repo.getGlobalCategories();

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
