enum AppointmentStatus {
  pending,
  confirmed,
  completed,
  cancelled,
  noShow;

  static AppointmentStatus fromString(String value) {
    return switch (value) {
      'pending' => AppointmentStatus.pending,
      'confirmed' => AppointmentStatus.confirmed,
      'completed' => AppointmentStatus.completed,
      'cancelled' => AppointmentStatus.cancelled,
      'no_show' => AppointmentStatus.noShow,
      _ => AppointmentStatus.pending,
    };
  }

  String toApiString() {
    return switch (this) {
      AppointmentStatus.pending => 'pending',
      AppointmentStatus.confirmed => 'confirmed',
      AppointmentStatus.completed => 'completed',
      AppointmentStatus.cancelled => 'cancelled',
      AppointmentStatus.noShow => 'no_show',
    };
  }
}

class Appointment {
  final String id;
  final String clientId;
  final String clientName;
  final String? clientPhone;
  final String professionalId;
  final String professionalName;
  final String serviceId;
  final String serviceName;
  final int durationMinutes;
  final int price;
  final String date;
  final DateTime startTime;
  final DateTime endTime;
  final AppointmentStatus status;
  final String source;
  final String? notes;
  final String? cancellationReason;

  const Appointment({
    required this.id,
    required this.clientId,
    required this.clientName,
    this.clientPhone,
    required this.professionalId,
    required this.professionalName,
    required this.serviceId,
    required this.serviceName,
    required this.durationMinutes,
    required this.price,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.source,
    this.notes,
    this.cancellationReason,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      clientName: json['client_name'] as String,
      clientPhone: json['client_phone'] as String?,
      professionalId: json['professional_id'] as String,
      professionalName: json['professional_name'] as String,
      serviceId: json['service_id'] as String,
      serviceName: json['service_name'] as String,
      durationMinutes: json['duration_minutes'] as int,
      price: json['price'] as int,
      date: json['date'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      status: AppointmentStatus.fromString(json['status'] as String),
      source: json['source'] as String,
      notes: json['notes'] as String?,
      cancellationReason: json['cancellation_reason'] as String?,
    );
  }

  bool get canConfirm => status == AppointmentStatus.pending;
  bool get canComplete => status == AppointmentStatus.confirmed;
  bool get canCancel =>
      status == AppointmentStatus.pending ||
      status == AppointmentStatus.confirmed;
  bool get canMarkNoShow => status == AppointmentStatus.confirmed;
  bool get isTerminal =>
      status == AppointmentStatus.completed ||
      status == AppointmentStatus.cancelled ||
      status == AppointmentStatus.noShow;
}

class RecurrenceRule {
  final String frequency;
  final List<int> days;
  final DateTime? until;

  const RecurrenceRule({
    required this.frequency,
    required this.days,
    this.until,
  });

  factory RecurrenceRule.fromJson(Map<String, dynamic> json) {
    return RecurrenceRule(
      frequency: json['frequency'] as String? ?? 'weekly',
      days: (json['days'] as List<dynamic>?)?.map((e) => e as int).toList() ??
          [],
      until: json['until'] != null
          ? DateTime.tryParse(json['until'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'frequency': frequency,
      'days': days,
      if (until != null) 'until': until!.toIso8601String().substring(0, 10),
    };
  }
}

class BlockedSlot {
  final String id;
  final String? professionalId;
  final String? title;
  final String? reason;
  final DateTime startTime;
  final DateTime endTime;
  final RecurrenceRule? recurrenceRule;
  final List<DateTime> excludedDates;

  const BlockedSlot({
    required this.id,
    this.professionalId,
    this.title,
    this.reason,
    required this.startTime,
    required this.endTime,
    this.recurrenceRule,
    this.excludedDates = const [],
  });

  bool get isRecurring => recurrenceRule != null;

  String get displayTitle => title ?? reason ?? 'Ausencia';

  factory BlockedSlot.fromJson(Map<String, dynamic> json) {
    final date = json['date'] as String? ?? '';
    final startStr = json['start_time'] as String? ?? '00:00';
    final endStr = json['end_time'] as String? ?? '01:00';

    DateTime parseSlotDateTime(String d, String t) {
      final colonIdx = t.indexOf(':');
      final h = colonIdx > 0 ? int.tryParse(t.substring(0, colonIdx)) ?? 0 : 0;
      final rest = colonIdx > 0 ? t.substring(colonIdx + 1) : '0';
      final m = int.tryParse(rest.length >= 2 ? rest.substring(0, 2) : rest) ?? 0;
      if (d.isEmpty) return DateTime.now();
      final parts = d.split('-');
      if (parts.length != 3) return DateTime.now();
      return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]), h, m);
    }

    final recurrenceJson = json['recurrence_rule'] as Map<String, dynamic>?;

    return BlockedSlot(
      id: json['id'] as String,
      professionalId: json['professional_id'] as String?,
      title: json['title'] as String?,
      reason: json['reason'] as String?,
      startTime: parseSlotDateTime(date, startStr),
      endTime: parseSlotDateTime(date, endStr),
      recurrenceRule:
          recurrenceJson != null ? RecurrenceRule.fromJson(recurrenceJson) : null,
      excludedDates: (json['excluded_dates'] as List<dynamic>?)
              ?.map((e) => DateTime.tryParse(e as String) ?? DateTime.now())
              .toList() ??
          [],
    );
  }
}

class AvailableSlot {
  final DateTime startTime;
  final bool available;

  const AvailableSlot({required this.startTime, required this.available});

  factory AvailableSlot.fromJson(Map<String, dynamic> json) {
    return AvailableSlot(
      startTime: DateTime.parse(json['start_time'] as String).toLocal(),
      available: json['available'] as bool? ?? false,
    );
  }

  String get label {
    final h = startTime.hour.toString().padLeft(2, '0');
    final m = startTime.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class ClientSearchResult {
  final String id;
  final String name;
  final String? phone;

  const ClientSearchResult({required this.id, required this.name, this.phone});

  factory ClientSearchResult.fromJson(Map<String, dynamic> json) {
    return ClientSearchResult(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
    );
  }
}

class ServiceOption {
  final String id;
  final String name;
  final int durationMinutes;
  final int priceCents;

  const ServiceOption({
    required this.id,
    required this.name,
    required this.durationMinutes,
    required this.priceCents,
  });

  factory ServiceOption.fromJson(Map<String, dynamic> json) {
    return ServiceOption(
      id: json['id'] as String,
      name: json['name'] as String,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 60,
      priceCents: (json['price'] as num?)?.toInt() ?? 0,
    );
  }

  String get formattedPrice {
    final reais = priceCents ~/ 100;
    final centavos = priceCents % 100;
    return 'R\$ $reais,${centavos.toString().padLeft(2, '0')}';
  }
}
