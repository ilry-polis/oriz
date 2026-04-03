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
        const ServiceInput(categoryId: 'c1', name: 'Manicure', durationMinutes: 30, price: 5000),
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

      expect((container.read(onboardingNotifierProvider) as OnboardingStep).currentStep, 2);

      notifier.goToStep(0);

      final state = container.read(onboardingNotifierProvider);
      expect((state as OnboardingStep).currentStep, 0);
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

      notifier.goToStep(2);

      final state = container.read(onboardingNotifierProvider);
      expect((state as OnboardingStep).currentStep, 1);
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
