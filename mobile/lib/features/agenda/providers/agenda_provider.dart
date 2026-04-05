import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/http/api_client.dart';
import '../models/appointment_model.dart';
import '../repositories/appointment_repository.dart';
import '../repositories/blocked_slot_repository.dart';

// ─── Per-professional cached data ─────────────────────────────────────────

class ProfessionalDayData {
  final List<Appointment> appointments;
  final List<BlockedSlot> blockedSlots;
  final int timelineStart;
  final int timelineEnd;
  final bool isLoading;
  final bool hasLoaded;
  final String? error;

  const ProfessionalDayData({
    this.appointments = const [],
    this.blockedSlots = const [],
    this.timelineStart = 8,
    this.timelineEnd = 19,
    this.isLoading = false,
    this.hasLoaded = false,
    this.error,
  });

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

// ─── State ────────────────────────────────────────────────────────────────

class AgendaState {
  final DateTime selectedDate;

  /// Currently active professional (the one whose page is visible).
  final String? selectedProfessionalId;

  /// Cached data per professional. Key = professionalId (or "" for "all").
  final Map<String, ProfessionalDayData> _cache;

  /// Monthly summary per professional, grouped by day.
  /// Outer key = professionalId (or "" for all), inner key = "YYYY-MM-DD",
  /// value = map of status → count.
  final Map<String, Map<String, Map<String, int>>> _monthSummaryCache;

  const AgendaState({
    required this.selectedDate,
    this.selectedProfessionalId,
    Map<String, ProfessionalDayData>? cache,
    Map<String, Map<String, Map<String, int>>>? monthSummaryCache,
  }) : _cache = cache ?? const {},
       _monthSummaryCache = monthSummaryCache ?? const {};

  /// Get month summary for the currently selected professional.
  Map<String, Map<String, int>> get monthSummary =>
      _monthSummaryCache[selectedProfessionalId ?? ''] ?? const {};

  /// Get data for a specific professional (from cache).
  ProfessionalDayData dataFor(String? professionalId) {
    return _cache[professionalId ?? ''] ?? const ProfessionalDayData();
  }

  /// Get data for the currently selected professional.
  ProfessionalDayData get currentData => dataFor(selectedProfessionalId);

  // Convenience getters for backwards compatibility
  List<Appointment> get appointments => currentData.appointments;
  List<BlockedSlot> get blockedSlots => currentData.blockedSlots;
  int get timelineStart => currentData.timelineStart;
  int get timelineEnd => currentData.timelineEnd;
  bool get isLoading => currentData.isLoading;
  String? get error => currentData.error;

  List<Appointment> appointmentsForDay(DateTime day) =>
      currentData.appointmentsForDay(day);
  List<BlockedSlot> blockedSlotsForDay(DateTime day) =>
      currentData.blockedSlotsForDay(day);

  /// Monday of the week containing [selectedDate].
  DateTime get weekStart =>
      selectedDate.subtract(Duration(days: selectedDate.weekday - 1));

  /// Sunday of the week.
  DateTime get weekEnd => weekStart.add(const Duration(days: 6));

  AgendaState _withCache(String? professionalId, ProfessionalDayData data) {
    final key = professionalId ?? '';
    final newCache = Map<String, ProfessionalDayData>.from(_cache);
    newCache[key] = data;
    return AgendaState(
      selectedDate: selectedDate,
      selectedProfessionalId: selectedProfessionalId,
      cache: newCache,
      monthSummaryCache: _monthSummaryCache,
    );
  }

  AgendaState copyWith({
    DateTime? selectedDate,
    String? selectedProfessionalId,
    bool clearProfessional = false,
    Map<String, Map<String, Map<String, int>>>? monthSummaryCache,
  }) {
    return AgendaState(
      selectedDate: selectedDate ?? this.selectedDate,
      selectedProfessionalId: clearProfessional
          ? null
          : (selectedProfessionalId ?? this.selectedProfessionalId),
      cache: _cache,
      monthSummaryCache: monthSummaryCache ?? _monthSummaryCache,
    );
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
    // Clear day caches — date changed, day data is stale (keep month cache)
    state = AgendaState(
      selectedDate: date,
      selectedProfessionalId: state.selectedProfessionalId,
      monthSummaryCache: state._monthSummaryCache,
    );
    await _loadDayData(date, state.selectedProfessionalId);
  }

  Future<void> selectProfessional(String? professionalId) async {
    state = state.copyWith(
      selectedProfessionalId: professionalId,
      clearProfessional: professionalId == null,
    );

    // Only fetch if never loaded for this professional
    final cached = state.dataFor(professionalId);
    if (!cached.hasLoaded && !cached.isLoading) {
      await _loadDayData(state.selectedDate, professionalId);
    }
  }

  /// Pre-load data for a professional without switching to them.
  Future<void> preloadProfessional(String professionalId) async {
    final cached = state.dataFor(professionalId);
    if (cached.hasLoaded || cached.isLoading) return;
    await _loadDayData(state.selectedDate, professionalId);
  }

  /// Batch preload all professionals in 1 request (no professional_id filter).
  /// Splits results client-side by professional_id into per-professional caches.
  Future<void> batchPreloadAll(List<String> professionalIds) async {
    final date = state.selectedDate;
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    try {
      final results = await Future.wait([
        _appointments.listByDate(dateStr),
        _blockedSlots.listByDateRange(dateStr, dateStr),
      ]);

      final allAppts = results[0] as List<Appointment>;
      final allSlots = results[1] as List<BlockedSlot>;

      // Group by professional_id
      for (final profId in professionalIds) {
        final profAppts = allAppts
            .where((a) => a.professionalId == profId)
            .toList();
        final profSlots = allSlots
            .where((b) => b.professionalId == profId)
            .toList();

        int tStart = 8;
        int tEnd = 19;
        for (final a in profAppts) {
          if (a.startTime.hour < tStart) tStart = a.startTime.hour;
          if (a.endTime.hour >= tEnd) tEnd = a.endTime.hour + 1;
        }
        for (final s in profSlots) {
          if (s.startTime.hour < tStart) tStart = s.startTime.hour;
          if (s.endTime.hour >= tEnd) tEnd = s.endTime.hour + 1;
        }

        state = state._withCache(
          profId,
          ProfessionalDayData(
            appointments: profAppts,
            blockedSlots: profSlots,
            timelineStart: tStart,
            timelineEnd: tEnd,
            hasLoaded: true,
          ),
        );
      }
    } catch (_) {
      // Fall back to individual loads if batch fails
      for (final profId in professionalIds) {
        preloadProfessional(profId);
      }
    }
  }

  Future<void> refresh() async {
    // Force reload for current professional
    state = state._withCache(
      state.selectedProfessionalId,
      const ProfessionalDayData(isLoading: true),
    );
    await _loadDayData(state.selectedDate, state.selectedProfessionalId);
  }

  // ─── Appointment CRUD ────────────────────────────────────────────────────

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
      state = state._withCache(
        state.selectedProfessionalId,
        state.currentData._copyWithError(e.message),
      );
    }
  }

  // ─── Appointment status transitions ──────────────────────────────────────

  Future<void> confirmAppointment(String id) async {
    try {
      await _appointments.confirm(id);
      await _loadDayData(state.selectedDate, state.selectedProfessionalId);
    } on ApiException catch (e) {
      state = state._withCache(
        state.selectedProfessionalId,
        state.currentData._copyWithError(e.message),
      );
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
      state = state._withCache(
        state.selectedProfessionalId,
        state.currentData._copyWithError(e.message),
      );
    }
  }

  Future<void> cancelAppointment(String id, {String? reason}) async {
    try {
      await _appointments.cancel(id, reason: reason);
      await _loadDayData(state.selectedDate, state.selectedProfessionalId);
    } on ApiException catch (e) {
      state = state._withCache(
        state.selectedProfessionalId,
        state.currentData._copyWithError(e.message),
      );
    }
  }

  Future<void> markNoShow(String id) async {
    try {
      await _appointments.markNoShow(id);
      await _loadDayData(state.selectedDate, state.selectedProfessionalId);
    } on ApiException catch (e) {
      state = state._withCache(
        state.selectedProfessionalId,
        state.currentData._copyWithError(e.message),
      );
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
      state = state._withCache(
        state.selectedProfessionalId,
        state.currentData._copyWithError(e.message),
      );
    }
  }

  Future<void> deleteAbsence(String id) async {
    try {
      await _blockedSlots.delete(id);
      final current = state.currentData;
      state = state._withCache(
        state.selectedProfessionalId,
        ProfessionalDayData(
          appointments: current.appointments,
          blockedSlots: current.blockedSlots.where((b) => b.id != id).toList(),
          timelineStart: current.timelineStart,
          timelineEnd: current.timelineEnd,
          hasLoaded: true,
        ),
      );
    } on ApiException catch (e) {
      state = state._withCache(
        state.selectedProfessionalId,
        state.currentData._copyWithError(e.message),
      );
    }
  }

  // ─── Month data (for calendar view) ────────────────────────────────────────

  Future<void> loadMonthData(DateTime month, {String? professionalId}) async {
    final profKey = professionalId ?? state.selectedProfessionalId ?? '';
    final monthStr =
        '${month.year}-${month.month.toString().padLeft(2, '0')}';

    try {
      final summaries = await _appointments.monthSummary(
        monthStr,
        professionalId: professionalId ?? state.selectedProfessionalId,
      );

      final grouped = <String, Map<String, int>>{};
      for (final s in summaries) {
        (grouped[s.date] ??= {})[s.status] = s.count;
      }

      // Store under the professional key that was requested (not current)
      final newCache = Map<String, Map<String, Map<String, int>>>.from(
        state._monthSummaryCache,
      );
      newCache[profKey] = grouped;

      state = state.copyWith(monthSummaryCache: newCache);
    } catch (_) {
      // Silently fail — month indicators are non-critical
    }
  }

  // ─── Internal data loading ────────────────────────────────────────────────

  Future<void> _loadDayData(DateTime date, String? professionalId) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    // Mark loading — but keep existing data visible (no skeleton flash)
    final existing = state.dataFor(professionalId);
    if (!existing.hasLoaded) {
      state = state._withCache(
        professionalId,
        const ProfessionalDayData(isLoading: true),
      );
    }

    try {
      final results = await Future.wait([
        _appointments.listByDate(dateStr, professionalId: professionalId),
        _blockedSlots.listByDateRange(dateStr, dateStr, professionalId: professionalId),
      ]);

      final appts = results[0] as List<Appointment>;
      final slots = results[1] as List<BlockedSlot>;

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

      state = state._withCache(
        professionalId,
        ProfessionalDayData(
          appointments: appts,
          blockedSlots: slots,
          timelineStart: tStart,
          timelineEnd: tEnd,
          hasLoaded: true,
        ),
      );
    } on ApiException catch (e) {
      state = state._withCache(
        professionalId,
        state.dataFor(professionalId)._copyWithError(e.message),
      );
    } on Exception catch (e) {
      state = state._withCache(
        professionalId,
        state.dataFor(professionalId)._copyWithError(e.toString()),
      );
    }
  }
}

// ─── Extension for error copy ─────────────────────────────────────────────

extension _ProfessionalDayDataCopy on ProfessionalDayData {
  ProfessionalDayData _copyWithError(String message) {
    return ProfessionalDayData(
      appointments: appointments,
      blockedSlots: blockedSlots,
      timelineStart: timelineStart,
      timelineEnd: timelineEnd,
      error: message,
    );
  }
}
