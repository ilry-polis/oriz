import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/commission_model.dart';
import '../repositories/commission_repository.dart';

// ─── Period helpers ────────────────────────────────────────────
class CommissionPeriod {
  final DateTime start;
  final DateTime end;
  final bool isMonthly; // false = biweekly

  const CommissionPeriod({
    required this.start,
    required this.end,
    required this.isMonthly,
  });

  static final _fmt = DateFormat('yyyy-MM-dd');
  static final _labelFmt = DateFormat('MMMM yyyy', 'pt_BR');
  static final _biweeklyFmt = DateFormat('d MMM', 'pt_BR');

  String get startStr => _fmt.format(start);
  String get endStr => _fmt.format(end);

  String get label {
    if (isMonthly) {
      return _toTitleCase(_labelFmt.format(start));
    } else {
      final startLabel = _biweeklyFmt.format(start);
      final endLabel = _biweeklyFmt.format(end);
      return '$startLabel – $endLabel ${end.year}';
    }
  }

  CommissionPeriod next() {
    if (isMonthly) {
      final nextStart = DateTime(end.year, end.month + 1, 1);
      final nextEnd = DateTime(nextStart.year, nextStart.month + 1, 0);
      return CommissionPeriod(
        start: nextStart,
        end: nextEnd,
        isMonthly: true,
      );
    } else {
      // biweekly: advance by 15 days
      final nextStart = end.add(const Duration(days: 1));
      final nextEnd = nextStart.add(const Duration(days: 14));
      return CommissionPeriod(
        start: nextStart,
        end: nextEnd,
        isMonthly: false,
      );
    }
  }

  CommissionPeriod previous() {
    if (isMonthly) {
      final prevEnd = DateTime(start.year, start.month, 0);
      final prevStart = DateTime(prevEnd.year, prevEnd.month, 1);
      return CommissionPeriod(
        start: prevStart,
        end: prevEnd,
        isMonthly: true,
      );
    } else {
      final prevEnd = start.subtract(const Duration(days: 1));
      final prevStart = prevEnd.subtract(const Duration(days: 14));
      return CommissionPeriod(
        start: prevStart,
        end: prevEnd,
        isMonthly: false,
      );
    }
  }

  static CommissionPeriod currentMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0);
    return CommissionPeriod(start: start, end: end, isMonthly: true);
  }

  static String _toTitleCase(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

// ─── State ────────────────────────────────────────────────────
sealed class CommissionState {
  const CommissionState();
}

class CommissionLoading extends CommissionState {
  const CommissionLoading();
}

class CommissionLoaded extends CommissionState {
  final List<CommissionSummary> summaries;
  final CommissionPeriod period;
  final Set<String> markingPaidIds; // professionalIds being marked

  const CommissionLoaded({
    required this.summaries,
    required this.period,
    this.markingPaidIds = const {},
  });

  CommissionLoaded copyWith({
    List<CommissionSummary>? summaries,
    CommissionPeriod? period,
    Set<String>? markingPaidIds,
  }) {
    return CommissionLoaded(
      summaries: summaries ?? this.summaries,
      period: period ?? this.period,
      markingPaidIds: markingPaidIds ?? this.markingPaidIds,
    );
  }
}

class CommissionError extends CommissionState {
  final String message;
  const CommissionError(this.message);
}

// ─── Detail state ──────────────────────────────────────────────
sealed class CommissionDetailState {
  const CommissionDetailState();
}

class CommissionDetailLoading extends CommissionDetailState {
  const CommissionDetailLoading();
}

class CommissionDetailLoaded extends CommissionDetailState {
  final List<CommissionModel> commissions;
  final String professionalId;

  const CommissionDetailLoaded({
    required this.commissions,
    required this.professionalId,
  });
}

class CommissionDetailError extends CommissionDetailState {
  final String message;
  const CommissionDetailError(this.message);
}

// ─── Detail params ─────────────────────────────────────────────
typedef CommissionDetailParams = ({
  String professionalId,
  CommissionPeriod period
});

// ─── Notifier ─────────────────────────────────────────────────
class CommissionNotifier extends Notifier<CommissionState> {
  @override
  CommissionState build() {
    final period = CommissionPeriod.currentMonth();
    _load(period);
    return const CommissionLoading();
  }

  Future<void> _load(CommissionPeriod period) async {
    state = const CommissionLoading();
    try {
      final repo = ref.read(commissionRepositoryProvider);
      final summaries = await repo.sumByProfessional(
        periodStart: period.startStr,
        periodEnd: period.endStr,
      );
      state = CommissionLoaded(summaries: summaries, period: period);
    } catch (e) {
      state = CommissionError(e.toString());
    }
  }

  void goToNextPeriod() {
    final current = state;
    if (current is! CommissionLoaded) return;
    _load(current.period.next());
  }

  void goToPreviousPeriod() {
    final current = state;
    if (current is! CommissionLoaded) return;
    _load(current.period.previous());
  }

  Future<void> markPaid(
    String professionalId,
    List<String> commissionIds,
  ) async {
    final current = state;
    if (current is! CommissionLoaded) return;

    // Optimistically mark as processing
    state = current.copyWith(
      markingPaidIds: {...current.markingPaidIds, professionalId},
    );

    try {
      final repo = ref.read(commissionRepositoryProvider);
      await repo.markPaid(commissionIds);
      // Refresh to get updated statuses
      await _load(current.period);
    } catch (e) {
      // Remove from markingPaidIds and show error state
      final afterError = state;
      if (afterError is CommissionLoaded) {
        final updated = Set<String>.from(afterError.markingPaidIds)
          ..remove(professionalId);
        state = afterError.copyWith(markingPaidIds: updated);
      }
      state = CommissionError(e.toString());
    }
  }

  Future<void> refresh() async {
    final current = state;
    final period = current is CommissionLoaded
        ? current.period
        : CommissionPeriod.currentMonth();
    await _load(period);
  }
}

final commissionProvider =
    NotifierProvider<CommissionNotifier, CommissionState>(
        CommissionNotifier.new);

// ─── Detail Provider (FutureProvider.family) ──────────────────
/// Loads the individual commissions for one professional in a given period.
/// Using FutureProvider.family for simple read-only async data.
final commissionDetailProvider = FutureProvider.autoDispose
    .family<CommissionDetailLoaded, CommissionDetailParams>(
  (ref, params) async {
    final repo = ref.read(commissionRepositoryProvider);
    final result = await repo.list(
      professionalId: params.professionalId,
      periodStart: params.period.startStr,
      periodEnd: params.period.endStr,
      limit: 100,
    );
    return CommissionDetailLoaded(
      commissions: result.items,
      professionalId: params.professionalId,
    );
  },
);
