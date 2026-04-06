import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/http/api_client.dart';
import '../models/commission_model.dart';

final commissionRepositoryProvider = Provider<CommissionRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return CommissionRepository(apiClient);
});

class CommissionRepository {
  final ApiClient _api;

  CommissionRepository(this._api);

  Future<({List<CommissionModel> items, bool hasMore, String? cursor})> list({
    String? professionalId,
    String? status,
    String? periodStart,
    String? periodEnd,
    String? cursor,
    int limit = 50,
  }) async {
    final params = StringBuffer('?limit=$limit');
    if (professionalId != null && professionalId.isNotEmpty) {
      params.write('&professional_id=$professionalId');
    }
    if (status != null && status.isNotEmpty) params.write('&status=$status');
    if (periodStart != null && periodStart.isNotEmpty) {
      params.write('&period_start=$periodStart');
    }
    if (periodEnd != null && periodEnd.isNotEmpty) {
      params.write('&period_end=$periodEnd');
    }
    if (cursor != null && cursor.isNotEmpty) params.write('&cursor=$cursor');

    final response = await _api.get('/api/v1/commissions$params');
    final data = response['data'] as List;
    final meta = response['meta'] as Map<String, dynamic>? ?? {};

    return (
      items: data
          .map((e) => CommissionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasMore: meta['hasMore'] as bool? ?? false,
      cursor: meta['cursor'] as String?,
    );
  }

  Future<List<CommissionSummary>> sumByProfessional({
    required String periodStart,
    required String periodEnd,
  }) async {
    final response = await _api.get(
      '/api/v1/commissions/summary?period_start=$periodStart&period_end=$periodEnd',
    );
    final data = response['data'] as List;
    return data
        .map((e) => CommissionSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markPaid(List<String> commissionIds) async {
    await _api.post(
      '/api/v1/commissions/pay',
      body: {'commission_ids': commissionIds},
    );
  }
}
