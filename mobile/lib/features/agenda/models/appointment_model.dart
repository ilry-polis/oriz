enum AppointmentStatus { confirmed, completed, cancelled, noShow }

class Appointment {
  final String id;
  final String clientName;
  final String serviceName;
  final int durationMinutes;
  final DateTime startTime;
  final DateTime endTime;
  final AppointmentStatus status;

  const Appointment({
    required this.id,
    required this.clientName,
    required this.serviceName,
    required this.durationMinutes,
    required this.startTime,
    required this.endTime,
    required this.status,
  });
}

class BlockedSlot {
  final String id;
  final String reason;
  final DateTime startTime;
  final DateTime endTime;

  const BlockedSlot({
    required this.id,
    required this.reason,
    required this.startTime,
    required this.endTime,
  });
}

/// Mock data for development
List<Appointment> mockAppointments(DateTime day) {
  return [
    Appointment(
      id: '1',
      clientName: 'Maria Silva',
      serviceName: 'Manicure',
      durationMinutes: 30,
      startTime: DateTime(day.year, day.month, day.day, 9, 0),
      endTime: DateTime(day.year, day.month, day.day, 9, 30),
      status: AppointmentStatus.confirmed,
    ),
    Appointment(
      id: '2',
      clientName: 'Ana Costa',
      serviceName: 'Pedicure',
      durationMinutes: 45,
      startTime: DateTime(day.year, day.month, day.day, 10, 0),
      endTime: DateTime(day.year, day.month, day.day, 10, 45),
      status: AppointmentStatus.confirmed,
    ),
    Appointment(
      id: '3',
      clientName: 'Juliana Mendes',
      serviceName: 'Esmaltação em gel',
      durationMinutes: 60,
      startTime: DateTime(day.year, day.month, day.day, 11, 0),
      endTime: DateTime(day.year, day.month, day.day, 12, 0),
      status: AppointmentStatus.completed,
    ),
    Appointment(
      id: '4',
      clientName: 'Carla Souza',
      serviceName: 'Sobrancelha',
      durationMinutes: 30,
      startTime: DateTime(day.year, day.month, day.day, 14, 0),
      endTime: DateTime(day.year, day.month, day.day, 14, 30),
      status: AppointmentStatus.confirmed,
    ),
  ];
}

List<BlockedSlot> mockBlockedSlots(DateTime day) {
  return [
    BlockedSlot(
      id: 'b1',
      reason: 'Almoço',
      startTime: DateTime(day.year, day.month, day.day, 12, 0),
      endTime: DateTime(day.year, day.month, day.day, 13, 0),
    ),
  ];
}
