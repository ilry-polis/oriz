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

  /// Lists studio-only categories (excludes globals).
  Future<List<Map<String, dynamic>>> listCategories() async {
    final response =
        await _api.get('/api/v1/service-categories?scope=studio');
    final data = response['data'] as List;
    return data.map((e) => e as Map<String, dynamic>).toList();
  }

  Future<Map<String, dynamic>> createCategory(String name, {String? icon}) async {
    final body = <String, dynamic>{'name': name};
    if (icon != null) body['icon'] = icon;
    final response =
        await _api.post('/api/v1/service-categories', body: body);
    return response['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateCategory(
      String id, Map<String, dynamic> data) async {
    final response =
        await _api.patch('/api/v1/service-categories/$id', body: data);
    return response['data'] as Map<String, dynamic>;
  }

  Future<void> deleteCategory(String id) async {
    await _api.delete('/api/v1/service-categories/$id');
  }

  Future<ServiceModel> getService(String id) async {
    final response = await _api.get('/api/v1/services/$id');
    return ServiceModel.fromJson(response['data'] as Map<String, dynamic>);
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
