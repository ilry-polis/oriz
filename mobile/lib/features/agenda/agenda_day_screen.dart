import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'models/appointment_model.dart';
import 'providers/agenda_provider.dart';
import 'widgets/appointment_card.dart';
import 'widgets/blocked_slot_card.dart';
import 'widgets/day_selector.dart';
import 'widgets/appointment_detail_sheet.dart';
import 'widgets/cancel_dialog.dart';
import 'widgets/payment_sheet.dart';
import 'widgets/quick_book_sheet.dart';
import 'widgets/skeleton_timeline.dart';

class AgendaDayScreen extends ConsumerStatefulWidget {
  const AgendaDayScreen({super.key});

  @override
  ConsumerState<AgendaDayScreen> createState() => _AgendaDayScreenState();
}

class _AgendaDayScreenState extends ConsumerState<AgendaDayScreen> {
  int? _dragOverHour;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profId = ref.read(currentProfessionalIdProvider);
      final notifier = ref.read(agendaNotifierProvider.notifier);
      if (profId != null && profId.isNotEmpty) {
        notifier.selectProfessional(profId);
      } else {
        notifier.selectDate(DateTime.now());
      }
    });
  }

  String _dateLabel(DateTime d) {
    const weekdays = [
      'Segunda', 'Terca', 'Quarta', 'Quinta', 'Sexta', 'Sabado', 'Domingo',
    ];
    const months = [
      'janeiro', 'fevereiro', 'marco', 'abril', 'maio', 'junho',
      'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
    ];
    return '${weekdays[d.weekday - 1]}, ${d.day} de ${months[d.month - 1]}';
  }

  Future<void> _pickDate(DateTime current) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2024),
      lastDate: DateTime(2028),
    );
    if (picked != null && mounted) {
      ref.read(agendaNotifierProvider.notifier).selectDate(picked);
    }
  }

  void _moveAppointment(Appointment appointment, int newHour) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${appointment.clientName} movido para ${newHour.toString().padLeft(2, '0')}:00',
        ),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
    setState(() => _dragOverHour = null);
  }

  bool _canDropAt(int hour, List<BlockedSlot> blockedSlots) {
    return !blockedSlots.any((b) => b.startTime.hour == hour);
  }

  void _showCancelDialog(Appointment appointment) {
    CancelDialog.show(context, appointment: appointment);
  }

  @override
  Widget build(BuildContext context) {
    final agendaState = ref.watch(agendaNotifierProvider);
    final selectedDate = agendaState.selectedDate;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildDateSection(agendaState),
            const Divider(height: 1, color: AppColors.neutral200),
            Expanded(child: _buildContent(agendaState, selectedDate)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md, AppSpacing.sm, AppSpacing.sm, 0,
      ),
      child: Row(
        children: [
          const Text('Agenda', style: AppTypography.title),
          const Spacer(),
          IconButton(
            icon: const Icon(
              Icons.filter_list_rounded,
              color: AppColors.neutral600,
              size: 24,
            ),
            onPressed: () {},
            tooltip: 'Filtrar por profissional',
          ),
          const SizedBox(width: AppSpacing.xs),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              HapticFeedback.lightImpact();
              final agendaState = ref.read(agendaNotifierProvider);
              final profId =
                  agendaState.selectedProfessionalId ?? ref.read(currentProfessionalIdProvider) ?? '';
              QuickBookSheet.show(
                context,
                date: agendaState.selectedDate,
                professionalId: profId,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateSection(AgendaState agendaState) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _pickDate(agendaState.selectedDate),
            child: Text(
              _dateLabel(agendaState.selectedDate),
              style: AppTypography.body.copyWith(color: AppColors.neutral600),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          DaySelector(
            selectedDate: agendaState.selectedDate,
            onDateSelected: (date) =>
                ref.read(agendaNotifierProvider.notifier).selectDate(date),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AgendaState agendaState, DateTime selectedDate) {
    if (agendaState.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: SkeletonTimeline(),
      );
    }

    if (agendaState.error != null) {
      return _buildError(agendaState.error!);
    }

    final appointments = agendaState.appointmentsForDay(selectedDate);
    final blockedSlots = agendaState.blockedSlotsForDay(selectedDate);

    return _buildTimeline(
      agendaState: agendaState,
      appointments: appointments,
      blockedSlots: blockedSlots,
    );
  }

  Widget _buildTimeline({
    required AgendaState agendaState,
    required List<Appointment> appointments,
    required List<BlockedSlot> blockedSlots,
  }) {
    final startHour = agendaState.timelineStart;
    final endHour = agendaState.timelineEnd;

    return RefreshIndicator(
      onRefresh: () => ref.read(agendaNotifierProvider.notifier).refresh(),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        itemCount: endHour - startHour,
        itemBuilder: (context, index) {
          final hour = startHour + index;
          return _buildTimeSlot(hour, appointments, blockedSlots, agendaState);
        },
      ),
    );
  }

  Widget _buildTimeSlot(
    int hour,
    List<Appointment> appointments,
    List<BlockedSlot> blockedSlots,
    AgendaState agendaState,
  ) {
    final hourLabel = '${hour.toString().padLeft(2, '0')}:00';
    final appointment =
        appointments.where((a) => a.startTime.hour == hour).firstOrNull;
    final blocked =
        blockedSlots.where((b) => b.startTime.hour == hour).firstOrNull;
    final isDragOver = _dragOverHour == hour;
    final canDrop = _canDropAt(hour, blockedSlots);

    return DragTarget<Appointment>(
      onWillAcceptWithDetails: (details) {
        if (!canDrop) return false;
        if (details.data.startTime.hour == hour) return false;
        setState(() => _dragOverHour = hour);
        return true;
      },
      onAcceptWithDetails: (details) => _moveAppointment(details.data, hour),
      onLeave: (_) => setState(() => _dragOverHour = null),
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: AppSpacing.xs),
          padding: isDragOver
              ? const EdgeInsets.symmetric(vertical: AppSpacing.xs)
              : EdgeInsets.zero,
          decoration: isDragOver
              ? BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.accent, width: 2),
                )
              : null,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 48,
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    hourLabel,
                    textAlign: TextAlign.right,
                    style: AppTypography.caption.copyWith(
                      color: isDragOver
                          ? AppColors.primary
                          : AppColors.neutral400,
                      fontWeight: isDragOver
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: appointment != null
                    ? _buildDraggableAppointment(appointment)
                    : blocked != null
                        ? Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: BlockedSlotCard(
                              slot: blocked,
                              onDelete: () => ref
                                  .read(agendaNotifierProvider.notifier)
                                  .deleteAbsence(blocked.id),
                            ),
                          )
                        : _buildEmptySlot(hour, agendaState),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDraggableAppointment(Appointment appointment) {
    return LongPressDraggable<Appointment>(
      data: appointment,
      hapticFeedbackOnStart: true,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(AppRadius.md),
        shadowColor: AppColors.primary.withValues(alpha: 0.3),
        child: SizedBox(
          width: MediaQuery.of(context).size.width - 48 - AppSpacing.md * 3,
          child: Opacity(
            opacity: 0.9,
            child: AppointmentCard(appointment: appointment),
          ),
        ),
      ),
      childWhenDragging: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.neutral200.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.neutral300),
          ),
          child: Center(
            child: Text(
              'Solte em outro horario',
              style: AppTypography.caption.copyWith(
                color: AppColors.neutral400,
              ),
            ),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: AppointmentCard(
          appointment: appointment,
          onTap: () => AppointmentDetailSheet.show(
                context,
                appointment: appointment,
              ),
          onConfirm: appointment.canConfirm
              ? () => ref
                    .read(agendaNotifierProvider.notifier)
                    .confirmAppointment(appointment.id)
              : null,
          onComplete: appointment.canComplete
              ? () => PaymentSheet.show(context, appointment: appointment)
              : null,
          onCancel: appointment.canCancel
              ? () => _showCancelDialog(appointment)
              : null,
          onMarkNoShow: appointment.canMarkNoShow
              ? () => ref
                    .read(agendaNotifierProvider.notifier)
                    .markNoShow(appointment.id)
              : null,
        ),
      ),
    );
  }

  Widget _buildEmptySlot(int hour, AgendaState agendaState) {
    return GestureDetector(
      onTap: () => QuickBookSheet.show(
        context,
        date: agendaState.selectedDate,
        professionalId:
            agendaState.selectedProfessionalId ?? ref.read(currentProfessionalIdProvider) ?? '',
        hour: hour,
        minute: 0,
      ),
      child: Container(
        height: 44,
        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(height: 1, color: AppColors.neutral200),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(
              Icons.add_circle_outline_rounded,
              size: 18,
              color: AppColors.neutral300,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: AppColors.neutral400,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Erro ao carregar agenda',
              style: AppTypography.title.copyWith(color: AppColors.neutral900),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: AppTypography.body.copyWith(color: AppColors.neutral600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: () =>
                    ref.read(agendaNotifierProvider.notifier).refresh(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.neutral200),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: Text(
                  'Tentar novamente',
                  style: AppTypography.bodySemibold.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
