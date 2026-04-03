import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/http/api_client.dart';
import '../domain/anamnesis_model.dart';
import '../domain/client_model.dart';

final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return ClientRepository(apiClient);
});

class ClientRepository {
  final ApiClient _api;

  ClientRepository(this._api);

  Future<Map<String, dynamic>> listClients({
    String? cursor,
    int limit = 20,
    String? search,
    String? tag,
  }) async {
    final params = <String, String>{'limit': '$limit'};
    if (cursor != null) params['cursor'] = cursor;
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (tag != null && tag.isNotEmpty) params['tag'] = tag;
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    return await _api.get('/api/v1/clients?$query');
  }

  Future<ClientModel> getClientById(String id) async {
    final response = await _api.get('/api/v1/clients/$id');
    return ClientModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<ClientModel> createClient(Map<String, dynamic> data) async {
    final response = await _api.post('/api/v1/clients', body: data);
    return ClientModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<ClientModel> updateClient(
      String id, Map<String, dynamic> data) async {
    final response = await _api.patch('/api/v1/clients/$id', body: data);
    return ClientModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> updateTags(String id, List<String> tags) async {
    await _api.patch('/api/v1/clients/$id/tags', body: {'tags': tags});
  }

  Future<void> anonymize(String id) async {
    await _api.post('/api/v1/clients/$id/data-deletion');
  }

  Future<AnamnesisModel?> getAnamnesis(String clientId, String category) async {
    final response =
        await _api.get('/api/v1/clients/$clientId/anamneses/$category');
    final data = response['data'];
    if (data == null) return null;
    return AnamnesisModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> upsertAnamnesis(
      String clientId, String category, Map<String, dynamic> fields) async {
    await _api.put('/api/v1/clients/$clientId/anamneses/$category',
        body: {'fields': fields});
  }

  Future<Map<String, dynamic>> listNotes(String clientId,
      {String? cursor, int limit = 20}) async {
    final params = <String, String>{'limit': '$limit'};
    if (cursor != null) params['cursor'] = cursor;
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    return await _api.get('/api/v1/clients/$clientId/notes?$query');
  }

  Future<ClientNote> createNote(String clientId, String content) async {
    final response = await _api
        .post('/api/v1/clients/$clientId/notes', body: {'content': content});
    return ClientNote.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> listAppointments(String clientId,
      {String? cursor, int limit = 20}) async {
    final params = <String, String>{'limit': '$limit'};
    if (cursor != null) params['cursor'] = cursor;
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    return await _api.get('/api/v1/clients/$clientId/appointments?$query');
  }
}
