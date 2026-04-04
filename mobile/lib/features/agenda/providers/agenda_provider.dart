import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/http/api_client.dart';
import '../models/appointment_model.dart';
import '../repositories/appointment_repository.dart';
import '../repositories/blocked_slot_repository.dart';

// ─── State ────────────────────────────────────────────────────────────────

class AgendaState {
  final DateTime selectedDate;

  /// null = all professionals (owner default), set = single professional
  final String? selectedProfessionalId;

  final List<Appointment> appointments;
  final List<BlockedSlot> blockedSlots;

  /// Start hour of the timeline (from working_hours; defaults to 8)
  final int timelineStart;

  /// End hour of the timeline (from working_hours; defaults to 19)
  final int timelineEnd;

  final bool isLoading;
  final String? error;

  const AgendaState({
    required this.selectedDate,
    this.selectedProfessionalId,
    this.appointments = const [],
    this.blockedSlots = const [],
    this.timelineStart = 8,
    this.timelineEnd = 19,
    this.isLoading = false,
    this.error,
  });

  AgendaState copyWith({
    DateTime? selectedDate,
    String? selectedProfessionalId,
    bool clearProfessional = false,
    List<Appointment>? appointments,
    List<BlockedSlot>? blockedSlots,
    int? timelineStart,
    int? timelineEnd,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AgendaState(
      selectedDate: selectedDate ?? this.selectedDate,
      selectedProfessionalId: clearProfessional
          ? null
          : (selectedProfessionalId ?? this.selectedProfessionalId),
      appointments: appointments ?? this.appointments,
      blockedSlots: blockedSlots ?? this.blockedSlots,
      timelineStart: timelineStart ?? this.timelineStart,
      timelineEnd: timelineEnd ?? this.timelineEnd,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  /// Monday of the week containing [selectedDate].
  DateTime get weekStart =>
      selectedDate.subtract(Duration(days: selectedDate.weekday - 1));

  /// Sunday of the week.
  DateTime get weekEnd => weekStart.add(const Duration(days: 6));

  /// Appointments for a specific day.
  List<Appointment> appointmentsForDay(DateTime day) {
    return appointments
        .where(
          (a) =>
              a.startTime.year == day.year &&
              a.startTime.month == day.month &&
              a.startTime.day == day.day,
        )
        .toList();
  }

  /// Blocked slots for a specific day.
  List<BlockedSlot> blockedSlotsForDay(DateTime day) {
    return blockedSlots
        .where(
          (b) =>
              b.startTime.year == day.year &&
              b.startTime.month == day.month &&
              b.startTime.day == day.day,
        )
        .toList();
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────

final agendaNotifierProvider =
    NotifierProvider<AgendaNotifier, AgendaState>(AgendaNotifier.new);

class AgendaNotifier extends Notifier<AgendaState> {
  @override
  AgendaState build() {
    return AgendaState(selectedDate: DateTime.now());
  }

  AppointmentRepository get _appointments =>
      ref.read(appointmentRepositoryProvider);
  BlockedSlotRepository get _blockedSlots =>
      ref.read(blockedSlotRepositoryProvider);

  // ─── Date & Professional selection ──────────────────────────────────────

  Future<void> selectDate(DateTime date) async {
    state = state.copyWith(selectedDate: date, isLoading: true, clearError: true);
    await _loadDayData(date, state.selectedProfessionalId);
  }

  Future<void> selectProfessional(String? professionalId) async {
    state = state.copyWith(
      selectedProfessionalId: professionalId,
      clearProfessional: professionalId == null,
      isLoading: true,
      clearError: true,
    );
    await _loadDayData(state.selectedDate, professionalId);
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    await _loadDayData(state.selectedDate, state.selectedProfessionalId);
  }

  // ─── Appointment CRUD ────────────────────────────────────────────────────

  /// Create a new appointment. Throws [ApiException] on conflict so the UI can
  /// show a specific error (e.g. TIME_SLOT_TAKEN).
  Future<void> createAppointment({
    required String clientId,
    required String professionalId,
    required String serviceId,
    required String date,
    required String startTime,
    String? notes,
  }) async {
    await _appointments.create(
      clientId: clientId,
      professionalId: professionalId,
      serviceId: serviceId,
      date: date,
      startTime: startTime,
      notes: notes,
    );
    await _loadDayData(state.selectedDate, state.selectedProfessionalId);
  }

  Future<void> rescheduleAppointment(String id, {required String date, required String startTime}) async {
    try {
      await _appointments.reschedule(id, date: date, startTime: startTime);
      await _loadDayData(state.selectedDate, state.selectedProfessionalId);
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
    }
  }

  // ─── Appointment status transitions ──────────────────────────────────────

  Future<void> confirmAppointment(String id) async {
    try {
      await _appointments.confirm(id);
      await _loadDayData(state.selectedDate, state.selectedProfessionalId);
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
    }
  }

  Future<void> completeAppointment(
    String id, {
    int? amountCents,
    String? method,
  }) async {
    try {
      await _appointments.complete(
        id,
        payment: (amountCents != null || method != null)
            ? {
                if (amountCents != null) 'amount': amountCents,
                if (method != null) 'method': method,
              }
            : null,
      );
      await _loadDayData(state.selectedDate, state.selectedProfessionalId);
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
    }
  }

  Future<void> cancelAppointment(String id, {String? reason}) async {
    try {
      await _appointments.cancel(id, reason: reason);
      await _loadDayData(state.selectedDate, state.selectedProfessionalId);
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
    }
  }

  Future<void> markNoShow(String id) async {
    try {
      await _appointments.markNoShow(id);
      await _loadDayData(state.selectedDate, state.selectedProfessionalId);
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
    }
  }

  // ─── Absence (blocked slot) management ───────────────────────────────────

  Future<void> createAbsence({
    required String professionalId,
    required String date,
    required String startTime,
    required String endTime,
    String? title,
    RecurrenceRule? recurrenceRule,
  }) async {
    try {
      await _blockedSlots.create(
        professionalId: professionalId,
        date: date,
        startTime: startTime,
        endTime: endTime,
        title: title,
        recurrenceRule: recurrenceRule,
      );
      await refresh();
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
    }
  }

  Future<void> deleteAbsence(String id) async {
    try {
      await _blockedSlots.delete(id);
      state = state.copyWith(
        blockedSlots: state.blockedSlots.where((b) => b.id != id).toList(),
      );
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
    }
  }

  // ─── Internal data loading ────────────────────────────────────────────────

  Future<void> _loadDayData(DateTime date, String? professionalId) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    try {
      final results = await Future.wait([
        _appointments.listByDate(dateStr, professionalId: professionalId),
        _blockedSlots.listByDateRange(dateStr, dateStr, professionalId: professionalId),
      ]);

      final appts = results[0] as List<Appointment>;
      final slots = results[1] as List<BlockedSlot>;

      // Derive timeline bounds from appointment data (best-effort).
      // Full working_hours derivation deferred until professionals/me endpoint
      // is implemented. Fallback: 8-19 or expand to fit existing appointments.
      int tStart = 8;
      int tEnd = 19;
      for (final a in appts) {
        if (a.startTime.hour < tStart) tStart = a.startTime.hour;
        if (a.endTime.hour >= tEnd) tEnd = a.endTime.hour + 1;
      }
      for (final s in slots) {
        if (s.startTime.hour < tStart) tStart = s.startTime.hour;
        if (s.endTime.hour >= tEnd) tEnd = s.endTime.hour + 1;
      }

      state = state.copyWith(
        appointments: appts,
        blockedSlots: slots,
        timelineStart: tStart,
        timelineEnd: tEnd,
        isLoading: false,
        clearError: true,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
