import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/appointment_model.dart';
import '../providers/agenda_provider.dart';

/// Monthly calendar with colored status bars per day (same visual as the old week view).
class AgendaMonthView extends ConsumerStatefulWidget {
  final void Function(DateTime date) onDayTap;

  const AgendaMonthView({super.key, required this.onDayTap});

  @override
  ConsumerState<AgendaMonthView> createState() => _AgendaMonthViewState();
}

class _AgendaMonthViewState extends ConsumerState<AgendaMonthView> {
  late DateTime _displayedMonth;

  static const _dayLabels = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
  static const _monthNames = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
  ];

  @override
  void initState() {
    super.initState();
    final selected = ref.read(agendaNotifierProvider).selectedDate;
    _displayedMonth = DateTime(selected.year, selected.month);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(agendaNotifierProvider.notifier).loadMonthData(_displayedMonth);
    });
  }

  void _changeMonth(int delta) {
    HapticFeedback.selectionClick();
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + delta,
      );
    });
    ref.read(agendaNotifierProvider.notifier).loadMonthData(_displayedMonth);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final agendaState = ref.watch(agendaNotifierProvider);
    final today = DateTime.now();
    final selectedDate = agendaState.selectedDate;
    final monthAppts = agendaState.monthAppointments;

    final firstOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final daysInMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    final leadingBlanks = firstOfMonth.weekday - 1; // Mon=1 → 0 blanks

    return Column(
      children: [
        // Month navigation
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _changeMonth(-1),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(Icons.chevron_left, color: AppColors.neutral600),
                ),
              ),
              Expanded(
                child: Text(
                  '${_monthNames[_displayedMonth.month - 1]} ${_displayedMonth.year}',
                  style: AppTypography.bodySemibold,
                  textAlign: TextAlign.center,
                ),
              ),
              GestureDetector(
                onTap: () => _changeMonth(1),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(Icons.chevron_right, color: AppColors.neutral600),
                ),
              ),
            ],
          ),
        ),

        // Day-of-week header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            children: _dayLabels
                .map(
                  (label) => Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: AppTypography.micro.copyWith(
                          color: AppColors.neutral400,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),

        const SizedBox(height: AppSpacing.xs),

        // Calendar grid
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 0.72,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: leadingBlanks + daysInMonth,
              itemBuilder: (context, index) {
                if (index < leadingBlanks) {
                  return const SizedBox.shrink();
                }

                final dayNum = index - leadingBlanks + 1;
                final date = DateTime(
                  _displayedMonth.year,
                  _displayedMonth.month,
                  dayNum,
                );
                final isToday = _isSameDay(date, today);
                final isSelected = _isSameDay(date, selectedDate);
                final dayAppts = monthAppts[_fmtDate(date)] ?? [];

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onDayTap(date);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.neutral100,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: isSelected
                          ? Border.all(color: AppColors.primary, width: 1.5)
                          : isToday
                              ? Border.all(color: AppColors.neutral300, width: 1)
                              : null,
                    ),
                    child: Column(
                      children: [
                        // Day number
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            '$dayNum',
                            style: AppTypography.micro.copyWith(
                              fontSize: 10,
                              color: isSelected
                                  ? AppColors.primary
                                  : isToday
                                      ? AppColors.primary
                                      : AppColors.neutral600,
                              fontWeight: isSelected || isToday
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),

                        // Mini status bars
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 3,
                              vertical: 2,
                            ),
                            child: _DayColumn(appointments: dayAppts),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // Legend
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              _LegendItem(color: AppColors.warning, label: 'Pendente'),
              SizedBox(width: AppSpacing.md),
              _LegendItem(color: AppColors.info, label: 'Confirmado'),
              SizedBox(width: AppSpacing.md),
              _LegendItem(color: AppColors.success, label: 'Concluído'),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Day column with mini bars ──────────────────────────────────────────────

class _DayColumn extends StatelessWidget {
  final List<Appointment> appointments;

  const _DayColumn({required this.appointments});

  Color _statusColor(AppointmentStatus status) {
    return switch (status) {
      AppointmentStatus.pending => AppColors.warning,
      AppointmentStatus.confirmed => AppColors.info,
      AppointmentStatus.completed => AppColors.success,
      AppointmentStatus.cancelled => AppColors.error,
      AppointmentStatus.noShow => AppColors.neutral400,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) return const SizedBox.expand();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...appointments.take(4).map((a) {
          final color = _statusColor(a.status);
          final dimmed = a.status == AppointmentStatus.cancelled ||
              a.status == AppointmentStatus.noShow;
          return Opacity(
            opacity: dimmed ? 0.4 : 1.0,
            child: Container(
              height: 6,
              margin: const EdgeInsets.only(bottom: 1.5),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          );
        }),
        if (appointments.length > 4)
          Text(
            '+${appointments.length - 4}',
            style: AppTypography.micro.copyWith(
              fontSize: 8,
              color: AppColors.neutral400,
            ),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}

// ─── Legend ──────────────────────────────────────────────────────────────────

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.micro.copyWith(color: AppColors.neutral600),
        ),
      ],
    );
  }
}
