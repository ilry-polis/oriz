import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/http/api_client.dart';
import '../models/appointment_model.dart';

export '../models/appointment_model.dart'
    show AvailableSlot, ClientSearchResult, ServiceOption;

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  throw UnimplementedError(
    'appointmentRepositoryProvider must be overridden in main.dart',
  );
});

class AppointmentRepository {
  final ApiClient _client;

  AppointmentRepository(this._client);

  /// GET /api/v1/appointments?date=YYYY-MM-DD[&professional_id=X]
  Future<List<Appointment>> listByDate(
    String date, {
    String? professionalId,
  }) async {
    final params = StringBuffer('/api/v1/appointments?date=$date');
    if (professionalId != null) {
      params.write('&professional_id=$professionalId');
    }
    final response = await _client.get(params.toString());
    final data = response['data'] as List<dynamic>;
    return data
        .map((e) => Appointment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/v1/appointments?date_from=X&date_to=Y[&professional_id=Z]
  Future<List<Appointment>> listByDateRange(
    String dateFrom,
    String dateTo, {
    String? professionalId,
  }) async {
    final params = StringBuffer(
      '/api/v1/appointments?date_from=$dateFrom&date_to=$dateTo&limit=100',
    );
    if (professionalId != null) {
      params.write('&professional_id=$professionalId');
    }
    final response = await _client.get(params.toString());
    final data = response['data'] as List<dynamic>;
    return data
        .map((e) => Appointment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/v1/appointments/available-slots?date=X&professional_id=Y&service_id=Z
  Future<List<AvailableSlot>> getAvailableSlots({
    required String date,
    required String professionalId,
    required String serviceId,
  }) async {
    final path =
        '/api/v1/appointments/available-slots?date=$date&professional_id=$professionalId&service_id=$serviceId';
    final response = await _client.get(path);
    final data = response['data'] as List<dynamic>;
    return data
        .map((e) => AvailableSlot.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/v1/appointments
  Future<Appointment> create({
    required String clientId,
    required String professionalId,
    required String serviceId,
    required String date,
    required String startTime,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'client_id': clientId,
      'professional_id': professionalId,
      'service_id': serviceId,
      'date': date,
      'start_time': startTime,
      'source': 'app',
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };
    final response = await _client.post('/api/v1/appointments', body: body);
    return Appointment.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// POST /api/v1/appointments/:id/confirm
  Future<Appointment> confirm(String id) async {
    final response = await _client.post('/api/v1/appointments/$id/confirm');
    return Appointment.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// POST /api/v1/appointments/:id/complete
  Future<Appointment> complete(
    String id, {
    Map<String, dynamic>? payment,
  }) async {
    final body = payment != null ? {'payment': payment} : null;
    final response =
        await _client.post('/api/v1/appointments/$id/complete', body: body);
    return Appointment.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// POST /api/v1/appointments/:id/cancel
  Future<Appointment> cancel(String id, {String? reason}) async {
    final body = reason != null ? {'cancellation_reason': reason} : null;
    final response =
        await _client.post('/api/v1/appointments/$id/cancel', body: body);
    return Appointment.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// PATCH /api/v1/appointments/:id — reschedule (change start_time)
  Future<Appointment> reschedule(
    String id, {
    required String date,
    required String startTime,
  }) async {
    final response = await _client.patch(
      '/api/v1/appointments/$id',
      body: {'date': date, 'start_time': startTime},
    );
    return Appointment.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// POST /api/v1/appointments/:id/no-show
  Future<Appointment> markNoShow(String id) async {
    final response = await _client.post('/api/v1/appointments/$id/no-show');
    return Appointment.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// GET /api/v1/clients?search=X — for booking sheet autocomplete
  Future<List<ClientSearchResult>> searchClients(String query) async {
    if (query.isEmpty) return [];
    final encoded = Uri.encodeQueryComponent(query);
    final response =
        await _client.get('/api/v1/clients?search=$encoded&limit=20');
    final data = response['data'] as List<dynamic>;
    return data
        .map((e) => ClientSearchResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/v1/clients — quick client registration from booking sheet
  Future<ClientSearchResult> createClient({
    required String name,
    required String phone,
  }) async {
    final response = await _client.post(
      '/api/v1/clients',
      body: {'name': name, 'phone': phone},
    );
    final data = response['data'] as Map<String, dynamic>;
    return ClientSearchResult.fromJson(data);
  }

  /// GET /api/v1/services?professional_id=X — services for a specific professional
  Future<List<ServiceOption>> getServicesForProfessional(
    String professionalId,
  ) async {
    final response = await _client.get(
      '/api/v1/services?professional_id=$professionalId&limit=100',
    );
    final data = response['data'] as List<dynamic>;
    return data
        .map((e) => ServiceOption.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
