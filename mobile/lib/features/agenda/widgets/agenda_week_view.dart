import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/appointment_model.dart';
import '../providers/agenda_provider.dart';

/// Week overview showing mini colored blocks per day.
/// Tap on a day column navigates to that day's detail view.
class AgendaWeekView extends ConsumerWidget {
  /// Called when the user taps a day column.
  final void Function(DateTime date) onDayTap;

  const AgendaWeekView({super.key, required this.onDayTap});

  static const _dayLabels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab', 'Dom'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agendaState = ref.watch(agendaNotifierProvider);
    final weekStart = agendaState.weekStart;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: day labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: List.generate(7, (i) {
              final day = weekStart.add(Duration(days: i));
              final isSelected = _isSameDay(day, agendaState.selectedDate);
              final isToday = _isSameDay(day, DateTime.now());
              return Expanded(
                child: GestureDetector(
                  onTap: () => onDayTap(day),
                  child: Column(
                    children: [
                      Text(
                        _dayLabels[i],
                        style: AppTypography.micro.copyWith(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.neutral400,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          shape: BoxShape.circle,
                          border: isToday && !isSelected
                              ? Border.all(color: AppColors.neutral300)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: AppTypography.micro.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : isToday
                                      ? AppColors.primary
                                      : AppColors.neutral600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: AppSpacing.sm),
        const Divider(height: 1, color: AppColors.neutral200),
        const SizedBox(height: AppSpacing.sm),

        // Day columns with mini blocks
        SizedBox(
          height: 120,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(7, (i) {
                final day = weekStart.add(Duration(days: i));
                final appointments = agendaState.appointmentsForDay(day);
                final blocked = agendaState.blockedSlotsForDay(day);

                return Expanded(
                  child: GestureDetector(
                    onTap: () => onDayTap(day),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: AppColors.neutral100,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: agendaState.isLoading
                          ? const _LoadingColumn()
                          : _DayColumn(
                              appointments: appointments,
                              blockedSlots: blocked,
                            ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),

        // Legend
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0,
          ),
          child: Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: const [
              _LegendItem(color: AppColors.warning, label: 'Pendente'),
              _LegendItem(color: AppColors.info, label: 'Confirmado'),
              _LegendItem(color: AppColors.success, label: 'Concluido'),
              _LegendItem(color: AppColors.neutral400, label: 'Ausencia'),
            ],
          ),
        ),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DayColumn extends StatelessWidget {
  final List<Appointment> appointments;
  final List<BlockedSlot> blockedSlots;

  const _DayColumn({
    required this.appointments,
    required this.blockedSlots,
  });

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
    if (appointments.isEmpty && blockedSlots.isEmpty) {
      return const SizedBox.expand();
    }

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...appointments.take(5).map((a) {
            final color = _statusColor(a.status);
            final opacity = (a.status == AppointmentStatus.cancelled ||
                    a.status == AppointmentStatus.noShow)
                ? 0.4
                : 1.0;
            return Opacity(
              opacity: opacity,
              child: Container(
                height: 12,
                margin: const EdgeInsets.only(bottom: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
          ...blockedSlots.take(2).map(
                (b) => Container(
                  height: 10,
                  margin: const EdgeInsets.only(bottom: 2),
                  decoration: BoxDecoration(
                    color: AppColors.neutral300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
          if (appointments.length > 5)
            Text(
              '+${appointments.length - 5}',
              style: AppTypography.micro.copyWith(
                fontSize: 9,
                color: AppColors.neutral400,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}

class _LoadingColumn extends StatelessWidget {
  const _LoadingColumn();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Column(
        children: List.generate(
          3,
          (_) => Container(
            height: 10,
            margin: const EdgeInsets.only(bottom: 3),
            decoration: BoxDecoration(
              color: AppColors.neutral200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}

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
          width: 10,
          height: 10,
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
