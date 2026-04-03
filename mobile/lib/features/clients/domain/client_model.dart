class ClientModel {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? birthDate;
  final List<String> tags;
  final List<String> autoTags;
  final String? lastAppointmentAt;
  final String createdAt;

  const ClientModel({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.birthDate,
    this.tags = const [],
    this.autoTags = const [],
    this.lastAppointmentAt,
    required this.createdAt,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) => ClientModel(
        id: json['id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        birthDate: json['birth_date'] as String?,
        tags: (json['tags'] as List?)?.map((e) => e as String).toList() ?? [],
        autoTags:
            (json['auto_tags'] as List?)?.map((e) => e as String).toList() ??
                [],
        lastAppointmentAt: json['last_appointment_at'] as String?,
        createdAt: json['created_at'] as String,
      );

  List<String> get allTags => [...autoTags, ...tags];

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

class ClientNote {
  final String id;
  final String content;
  final String professionalId;
  final String createdAt;

  const ClientNote({
    required this.id,
    required this.content,
    required this.professionalId,
    required this.createdAt,
  });

  factory ClientNote.fromJson(Map<String, dynamic> json) => ClientNote(
        id: json['id'] as String,
        content: json['content'] as String,
        professionalId: json['professional_id'] as String,
        createdAt: json['created_at'] as String,
      );
}

class AppointmentHistory {
  final String id;
  final String serviceName;
  final String professionalName;
  final String scheduledAt;
  final String status;

  const AppointmentHistory({
    required this.id,
    required this.serviceName,
    required this.professionalName,
    required this.scheduledAt,
    required this.status,
  });

  factory AppointmentHistory.fromJson(Map<String, dynamic> json) =>
      AppointmentHistory(
        id: json['id'] as String,
        serviceName: json['service_name'] as String,
        professionalName: json['professional_name'] as String,
        scheduledAt: json['scheduled_at'] as String,
        status: json['status'] as String,
      );
}
