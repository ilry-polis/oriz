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
      state = OnboardingError(_userMessage(e), code: e.code);
    } catch (_) {
      state = const OnboardingError('Erro de conexao. Verifique sua internet.');
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
      state = OnboardingError(_userMessage(e), code: e.code);
    } catch (_) {
      state = const OnboardingError('Erro de conexao. Verifique sua internet.');
    }
  }

  Future<void> addServices(List<ServiceInput> services) async {
    final prev = _requireStep();
    if (prev == null) return;
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
      // On partial failure, advance anyway — services already created are fine.
      // User can add more services later in settings.
      state = prev.copyWith(currentStep: 2, isSaving: false);
      if (e.code != 'UNKNOWN') {
        state = OnboardingError(_userMessage(e),
            code: e.code);
      }
    } catch (_) {
      state = prev.copyWith(isSaving: false);
    }
  }

  Future<void> skipServices() async {
    final prev = _requireStep();
    if (prev == null) return;
    state = prev.copyWith(isSaving: true);

    try {
      await _repo.updateOnboardingStep('business_hours');
      state = prev.copyWith(currentStep: 2, isSaving: false);
    } on ApiException catch (e) {
      state = OnboardingError(_userMessage(e), code: e.code);
    } catch (_) {
      state = prev.copyWith(isSaving: false);
    }
  }

  Future<void> setBusinessHours(
    Map<String, List<Map<String, String>>> hours,
  ) async {
    final prev = _requireStep();
    if (prev == null) return;
    state = prev.copyWith(isSaving: true);

    try {
      await _repo.updateWorkingHours(prev.professionalId!, hours);
      await _repo.updateOnboardingStep('complete');
      state = const OnboardingComplete();
    } on ApiException catch (e) {
      state = OnboardingError(_userMessage(e), code: e.code);
    } catch (_) {
      state = prev.copyWith(isSaving: false);
    }
  }

  Future<void> skipBusinessHours() async {
    final prev = _requireStep();
    if (prev == null) return;
    state = prev.copyWith(isSaving: true);

    try {
      await _repo.updateOnboardingStep('complete');
      state = const OnboardingComplete();
    } on ApiException catch (e) {
      state = OnboardingError(_userMessage(e), code: e.code);
    } catch (_) {
      state = prev.copyWith(isSaving: false);
    }
  }

  /// Safe cast: returns current OnboardingStep or null if in wrong state.
  OnboardingStep? _requireStep() {
    final s = state;
    if (s is OnboardingStep) return s;
    return null;
  }

  /// Maps API error codes to user-friendly messages.
  String _userMessage(ApiException e) {
    return switch (e.code) {
      'SLUG_TAKEN' => 'Esta URL ja esta em uso. Escolha outra.',
      'STUDIO_ALREADY_EXISTS' => 'Voce ja possui um estudio cadastrado.',
      'NOT_FOUND' => 'Recurso nao encontrado.',
      'VALIDATION_ERROR' => 'Dados invalidos. Verifique os campos.',
      _ => 'Algo deu errado. Tente novamente.',
    };
  }

  void goToStep(int step) {
    final prev = state;
    if (prev is OnboardingStep && step < prev.currentStep) {
      state = prev.copyWith(currentStep: step);
    }
  }
}
