import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/http/api_client.dart';
import '../models/financial_summary_model.dart';
import '../models/payment_model.dart';

final financialRepositoryProvider = Provider<FinancialRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return FinancialRepository(apiClient);
});

class FinancialRepository {
  final ApiClient _api;

  FinancialRepository(this._api);

  Future<FinancialSummaryModel> getSummary({
    required String period,
    required String date,
  }) async {
    final response = await _api.get(
      '/api/v1/financial/summary?period=$period&date=$date',
    );
    return FinancialSummaryModel.fromJson(
      response['data'] as Map<String, dynamic>,
    );
  }

  Future<List<BreakdownItem>> getBreakdownByProfessional({
    required String dateFrom,
    required String dateTo,
  }) async {
    final response = await _api.get(
      '/api/v1/financial/breakdown/professionals?date_from=$dateFrom&date_to=$dateTo',
    );
    final data = response['data'] as List;
    return data
        .map((e) => BreakdownItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<BreakdownItem>> getBreakdownByService({
    required String dateFrom,
    required String dateTo,
  }) async {
    final response = await _api.get(
      '/api/v1/financial/breakdown/services?date_from=$dateFrom&date_to=$dateTo',
    );
    final data = response['data'] as List;
    return data
        .map((e) => BreakdownItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<({List<PaymentListItem> items, bool hasMore, String? cursor})>
      listPayments({
    required String dateFrom,
    required String dateTo,
    String? method,
    String? professionalId,
    String? cursor,
    int limit = 20,
  }) async {
    final params = StringBuffer('?date_from=$dateFrom&date_to=$dateTo&limit=$limit');
    if (method != null && method.isNotEmpty) params.write('&method=$method');
    if (professionalId != null && professionalId.isNotEmpty) {
      params.write('&professional_id=$professionalId');
    }
    if (cursor != null && cursor.isNotEmpty) params.write('&cursor=$cursor');

    final response = await _api.get('/api/v1/payments$params');
    final data = response['data'] as List;
    final meta = response['meta'] as Map<String, dynamic>? ?? {};

    return (
      items: data
          .map((e) => PaymentListItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasMore: meta['hasMore'] as bool? ?? false,
      cursor: meta['cursor'] as String?,
    );
  }
}
