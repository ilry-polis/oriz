import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/http/api_client.dart';
import '../domain/professional_model.dart';

final teamRepositoryProvider = Provider<TeamRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return TeamRepository(apiClient);
});

class TeamRepository {
  final ApiClient _api;

  TeamRepository(this._api);

  Future<List<ProfessionalModel>> listProfessionals() async {
    final response = await _api.get('/api/v1/professionals');
    final data = response['data'] as List;
    return data
        .map((e) => ProfessionalModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ProfessionalModel> getProfessionalById(String id) async {
    final response = await _api.get('/api/v1/professionals/$id');
    return ProfessionalModel.fromJson(
        response['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> createInvite(Map<String, dynamic> data) async {
    return await _api.post('/api/v1/professionals/invites', body: data);
  }

  Future<ProfessionalModel> updateProfessional(
      String id, Map<String, dynamic> data) async {
    final response =
        await _api.patch('/api/v1/professionals/$id', body: data);
    return ProfessionalModel.fromJson(
        response['data'] as Map<String, dynamic>);
  }

  Future<ProfessionalModel> toggleActive(String id, bool isActive) async {
    final response = await _api
        .patch('/api/v1/professionals/$id/active', body: {'is_active': isActive});
    return ProfessionalModel.fromJson(
        response['data'] as Map<String, dynamic>);
  }

  // Public endpoints — no auth needed
  Future<InviteInfo> getInviteInfo(String token) async {
    final response = await _api.get('/api/v1/professionals/invites/$token');
    return InviteInfo.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> acceptInvite(
      String token, String email, String password) async {
    return await _api.post('/api/v1/auth/accept-invite',
        body: {'token': token, 'email': email, 'password': password});
  }
}
