import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/http/api_client.dart';
import '../models/appointment_model.dart';

final blockedSlotRepositoryProvider = Provider<BlockedSlotRepository>((ref) {
  throw UnimplementedError(
    'blockedSlotRepositoryProvider must be overridden in main.dart',
  );
});

class BlockedSlotRepository {
  final ApiClient _client;

  BlockedSlotRepository(this._client);

  /// GET /api/v1/blocked-slots?date_from=X&date_to=Y[&professional_id=Z]
  Future<List<BlockedSlot>> listByDateRange(
    String dateFrom,
    String dateTo, {
    String? professionalId,
  }) async {
    final params = StringBuffer(
      '/api/v1/blocked-slots?date_from=$dateFrom&date_to=$dateTo',
    );
    if (professionalId != null) {
      params.write('&professional_id=$professionalId');
    }
    final response = await _client.get(params.toString());
    final data = response['data'] as List<dynamic>;
    return data
        .map((e) => BlockedSlot.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/v1/blocked-slots
  Future<BlockedSlot> create({
    required String professionalId,
    required String date,
    required String startTime,
    required String endTime,
    String? title,
    RecurrenceRule? recurrenceRule,
  }) async {
    final body = <String, dynamic>{
      'professional_id': professionalId,
      'date': date,
      'start_time': startTime,
      'end_time': endTime,
      if (title != null) 'title': title,
      if (recurrenceRule != null) 'recurrence_rule': recurrenceRule.toJson(),
    };
    final response = await _client.post('/api/v1/blocked-slots', body: body);
    return BlockedSlot.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// DELETE /api/v1/blocked-slots/:id
  Future<void> delete(String id) async {
    await _client.delete('/api/v1/blocked-slots/$id');
  }
}
