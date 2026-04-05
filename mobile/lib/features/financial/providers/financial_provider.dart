import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/financial_summary_model.dart';
import '../models/payment_model.dart';
import '../repositories/financial_repository.dart';

// ─── Period ───────────────────────────────────────────────────
enum FinancialPeriod { day, week, month }

extension FinancialPeriodX on FinancialPeriod {
  String get apiValue {
    switch (this) {
      case FinancialPeriod.day:
        return 'day';
      case FinancialPeriod.week:
        return 'week';
      case FinancialPeriod.month:
        return 'month';
    }
  }

  String get label {
    switch (this) {
      case FinancialPeriod.day:
        return 'Dia';
      case FinancialPeriod.week:
        return 'Semana';
      case FinancialPeriod.month:
        return 'Mês';
    }
  }

  /// Returns (dateFrom, dateTo) for the period based on a reference date.
  (String, String) dateRange(DateTime date) {
    final fmt = DateFormat('yyyy-MM-dd');
    switch (this) {
      case FinancialPeriod.day:
        final d = fmt.format(date);
        return (d, d);
      case FinancialPeriod.week:
        final monday = date.subtract(Duration(days: date.weekday - 1));
        final sunday = monday.add(const Duration(days: 6));
        return (fmt.format(monday), fmt.format(sunday));
      case FinancialPeriod.month:
        final start = DateTime(date.year, date.month, 1);
        final end = DateTime(date.year, date.month + 1, 0);
        return (fmt.format(start), fmt.format(end));
    }
  }
}

// ─── State ────────────────────────────────────────────────────
sealed class FinancialDashboardState {
  const FinancialDashboardState();
}

class FinancialDashboardLoading extends FinancialDashboardState {
  const FinancialDashboardLoading();
}

class FinancialDashboardLoaded extends FinancialDashboardState {
  final FinancialSummaryModel summary;
  final List<PaymentListItem> payments;
  final List<BreakdownItem> breakdownByProfessional;
  final List<BreakdownItem> breakdownByService;
  final bool hasMorePayments;
  final String? paymentsCursor;
  final FinancialPeriod period;
  final DateTime date;
  final String? filterMethod;
  final String? filterProfessionalId;

  const FinancialDashboardLoaded({
    required this.summary,
    required this.payments,
    required this.breakdownByProfessional,
    required this.breakdownByService,
    required this.hasMorePayments,
    this.paymentsCursor,
    required this.period,
    required this.date,
    this.filterMethod,
    this.filterProfessionalId,
  });

  FinancialDashboardLoaded copyWith({
    FinancialSummaryModel? summary,
    List<PaymentListItem>? payments,
    List<BreakdownItem>? breakdownByProfessional,
    List<BreakdownItem>? breakdownByService,
    bool? hasMorePayments,
    String? paymentsCursor,
    FinancialPeriod? period,
    DateTime? date,
    String? filterMethod,
    String? filterProfessionalId,
    bool clearFilterMethod = false,
    bool clearFilterProfessionalId = false,
  }) {
    return FinancialDashboardLoaded(
      summary: summary ?? this.summary,
      payments: payments ?? this.payments,
      breakdownByProfessional:
          breakdownByProfessional ?? this.breakdownByProfessional,
      breakdownByService: breakdownByService ?? this.breakdownByService,
      hasMorePayments: hasMorePayments ?? this.hasMorePayments,
      paymentsCursor: paymentsCursor ?? this.paymentsCursor,
      period: period ?? this.period,
      date: date ?? this.date,
      filterMethod: clearFilterMethod ? null : filterMethod ?? this.filterMethod,
      filterProfessionalId: clearFilterProfessionalId
          ? null
          : filterProfessionalId ?? this.filterProfessionalId,
    );
  }
}

class FinancialDashboardError extends FinancialDashboardState {
  final String message;
  const FinancialDashboardError(this.message);
}

// ─── Notifier ─────────────────────────────────────────────────
class FinancialDashboardNotifier
    extends Notifier<FinancialDashboardState> {
  @override
  FinancialDashboardState build() {
    _load(period: FinancialPeriod.month, date: DateTime.now());
    return const FinancialDashboardLoading();
  }

  Future<void> _load({
    required FinancialPeriod period,
    required DateTime date,
    String? filterMethod,
    String? filterProfessionalId,
  }) async {
    state = const FinancialDashboardLoading();
    try {
      final repo = ref.read(financialRepositoryProvider);
      final fmt = DateFormat('yyyy-MM-dd');
      final dateStr = fmt.format(date);
      final (dateFrom, dateTo) = period.dateRange(date);

      final summaryFuture =
          repo.getSummary(period: period.apiValue, date: dateStr);
      final paymentsFuture = repo.listPayments(
        dateFrom: dateFrom,
        dateTo: dateTo,
        method: filterMethod,
        professionalId: filterProfessionalId,
      );
      final breakdownProFuture =
          repo.getBreakdownByProfessional(dateFrom: dateFrom, dateTo: dateTo);
      final breakdownSvcFuture =
          repo.getBreakdownByService(dateFrom: dateFrom, dateTo: dateTo);

      final results = await (
        summaryFuture,
        paymentsFuture,
        breakdownProFuture,
        breakdownSvcFuture,
      ).wait;

      final summary = results.$1;
      final paymentsResult = results.$2;
      final breakdownPro = results.$3;
      final breakdownSvc = results.$4;

      state = FinancialDashboardLoaded(
        summary: summary,
        payments: paymentsResult.items,
        breakdownByProfessional: breakdownPro,
        breakdownByService: breakdownSvc,
        hasMorePayments: paymentsResult.hasMore,
        paymentsCursor: paymentsResult.cursor,
        period: period,
        date: date,
        filterMethod: filterMethod,
        filterProfessionalId: filterProfessionalId,
      );
    } catch (e) {
      state = FinancialDashboardError(e.toString());
    }
  }

  Future<void> changePeriod(FinancialPeriod period) async {
    final current = state;
    final date = current is FinancialDashboardLoaded ? current.date : DateTime.now();
    final filterMethod =
        current is FinancialDashboardLoaded ? current.filterMethod : null;
    final filterPro =
        current is FinancialDashboardLoaded ? current.filterProfessionalId : null;
    await _load(
      period: period,
      date: date,
      filterMethod: filterMethod,
      filterProfessionalId: filterPro,
    );
  }

  Future<void> changeDate(DateTime date) async {
    final current = state;
    final period = current is FinancialDashboardLoaded
        ? current.period
        : FinancialPeriod.month;
    final filterMethod =
        current is FinancialDashboardLoaded ? current.filterMethod : null;
    final filterPro =
        current is FinancialDashboardLoaded ? current.filterProfessionalId : null;
    await _load(
      period: period,
      date: date,
      filterMethod: filterMethod,
      filterProfessionalId: filterPro,
    );
  }

  Future<void> applyFilters({
    String? method,
    String? professionalId,
  }) async {
    final current = state;
    if (current is! FinancialDashboardLoaded) return;
    await _load(
      period: current.period,
      date: current.date,
      filterMethod: method,
      filterProfessionalId: professionalId,
    );
  }

  Future<void> loadMorePayments() async {
    final current = state;
    if (current is! FinancialDashboardLoaded) return;
    if (!current.hasMorePayments || current.paymentsCursor == null) return;

    try {
      final repo = ref.read(financialRepositoryProvider);
      final (dateFrom, dateTo) = current.period.dateRange(current.date);

      final result = await repo.listPayments(
        dateFrom: dateFrom,
        dateTo: dateTo,
        method: current.filterMethod,
        professionalId: current.filterProfessionalId,
        cursor: current.paymentsCursor,
      );

      state = current.copyWith(
        payments: [...current.payments, ...result.items],
        hasMorePayments: result.hasMore,
        paymentsCursor: result.cursor,
      );
    } catch (_) {
      // Silently ignore load-more failures — user can retry by scrolling again
    }
  }

  Future<void> refresh() async {
    final current = state;
    final period = current is FinancialDashboardLoaded
        ? current.period
        : FinancialPeriod.month;
    final date =
        current is FinancialDashboardLoaded ? current.date : DateTime.now();
    final filterMethod =
        current is FinancialDashboardLoaded ? current.filterMethod : null;
    final filterPro =
        current is FinancialDashboardLoaded ? current.filterProfessionalId : null;
    await _load(
      period: period,
      date: date,
      filterMethod: filterMethod,
      filterProfessionalId: filterPro,
    );
  }
}

final financialDashboardProvider =
    NotifierProvider<FinancialDashboardNotifier, FinancialDashboardState>(
        FinancialDashboardNotifier.new);
