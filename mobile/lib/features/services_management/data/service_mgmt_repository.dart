import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/http/api_client.dart';
import '../domain/service_model.dart';

final serviceMgmtRepositoryProvider = Provider<ServiceMgmtRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return ServiceMgmtRepository(apiClient);
});

class ServiceMgmtRepository {
  final ApiClient _api;

  ServiceMgmtRepository(this._api);

  Future<List<Map<String, dynamic>>> listCategories() async {
    final response = await _api.get('/api/v1/service-categories');
    final data = response['data'] as List;
    return data.map((e) => e as Map<String, dynamic>).toList();
  }

  Future<List<ServiceModel>> listServices() async {
    final response = await _api.get('/api/v1/services');
    final data = response['data'] as List;
    return data
        .map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ServiceModel> createService(Map<String, dynamic> data) async {
    final response = await _api.post('/api/v1/services', body: data);
    return ServiceModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<ServiceModel> updateService(
      String id, Map<String, dynamic> data) async {
    final response = await _api.patch('/api/v1/services/$id', body: data);
    return ServiceModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<ServiceModel> toggleActive(String id, bool isActive) async {
    final response = await _api.patch('/api/v1/services/$id/active',
        body: {'is_active': isActive});
    return ServiceModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> deleteService(String id) async {
    await _api.delete('/api/v1/services/$id');
  }
}
