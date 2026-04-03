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

  /// Gets global categories (for onboarding template selection).
  Future<List<ServiceCategory>> getGlobalCategories() async {
    final response =
        await _client.get('/api/v1/service-categories?scope=global');
    final list = response['data'] as List<dynamic>;

    return list
        .map((item) => ServiceCategory(
              id: (item as Map<String, dynamic>)['id'] as String,
              name: item['name'] as String,
            ))
        .toList();
  }

  /// Copies selected global categories to the studio.
  /// Returns the created studio-specific categories.
  Future<List<ServiceCategory>> copyGlobalCategories(
      List<String> globalCategoryIds) async {
    final response = await _client.post(
      '/api/v1/service-categories/copy-globals',
      body: {'category_ids': globalCategoryIds},
    );
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
