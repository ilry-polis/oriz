import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../team/domain/professional_model.dart';
import '../team/providers/team_provider.dart';
import 'models/appointment_model.dart';
import 'providers/agenda_provider.dart';
import 'widgets/appointment_card.dart';
import 'widgets/blocked_slot_card.dart';
import 'widgets/day_selector.dart';
import 'widgets/appointment_detail_sheet.dart';
import 'widgets/cancel_dialog.dart';
import 'widgets/create_absence_sheet.dart';
import 'widgets/payment_sheet.dart';
import 'widgets/quick_book_sheet.dart';
import 'widgets/agenda_month_view.dart';
import 'widgets/skeleton_timeline.dart';

class AgendaDayScreen extends ConsumerStatefulWidget {
  const AgendaDayScreen({super.key});

  @override
  ConsumerState<AgendaDayScreen> createState() => _AgendaDayScreenState();
}

class _AgendaDayScreenState extends ConsumerState<AgendaDayScreen> {
  int? _dragOverHour;
  bool _showMonthView = false;
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAgenda();
    });
  }

  void _initAgenda() {
    final myId = ref.read(currentProfessionalIdProvider);
    final notifier = ref.read(agendaNotifierProvider.notifier);

    // Owner is always page 0
    if (myId != null && myId.isNotEmpty) {
      notifier.selectProfessional(myId);
    } else {
      notifier.selectDate(DateTime.now());
    }

    // Batch preload ALL professionals in 1 request (2 API calls total)
    final teamState = ref.read(teamProvider);
    if (teamState is TeamLoaded) {
      final ids = teamState.professionals
          .where((p) => p.isActive)
          .map((p) => p.id)
          .toList();
      if (ids.length > 1) {
        notifier.batchPreloadAll(ids);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
    setState(() => _dragOverHour = null);

    final agendaState = ref.read(agendaNotifierProvider);
    final d = agendaState.selectedDate;
    final dateStr =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final timeStr = '${newHour.toString().padLeft(2, '0')}:00';

    ref
        .read(agendaNotifierProvider.notifier)
        .rescheduleAppointment(appointment.id, date: dateStr, startTime: timeStr)
        .then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${appointment.clientName} movido para $timeStr',
            ),
            backgroundColor: AppColors.info,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        );
      }
    });
  }

  bool _canDropAt(int hour, List<BlockedSlot> blockedSlots) {
    return !blockedSlots.any((b) => b.startTime.hour == hour);
  }

  void _showCancelDialog(Appointment appointment) {
    CancelDialog.show(context, appointment: appointment);
  }

  void _onPageChanged(int page, List<ProfessionalModel> professionals) {
    HapticFeedback.selectionClick();
    setState(() => _currentPage = page);
    final prof = professionals[page];
    ref.read(agendaNotifierProvider.notifier).selectProfessional(prof.id);

    // Pre-load adjacent pages
    final notifier = ref.read(agendaNotifierProvider.notifier);
    if (page + 1 < professionals.length) {
      notifier.preloadProfessional(professionals[page + 1].id);
    }
    if (page - 1 >= 0) {
      notifier.preloadProfessional(professionals[page - 1].id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final agendaState = ref.watch(agendaNotifierProvider);
    final selectedDate = agendaState.selectedDate;
    final teamState = ref.watch(teamProvider);

    // Get active professionals list, owner always first
    final myId = ref.watch(currentProfessionalIdProvider);
    final professionals = teamState is TeamLoaded
        ? (teamState.professionals.where((p) => p.isActive).toList()
          ..sort((a, b) {
            if (a.id == myId) return -1;
            if (b.id == myId) return 1;
            return 0;
          }))
        : <ProfessionalModel>[];
    final hasTeam = professionals.length > 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            if (!_showMonthView) _buildDateSection(agendaState),

            // Professional tabs (only when team has >1 member)
            if (hasTeam) ...[
              _buildProfessionalTabs(professionals),
            ],

            if (!_showMonthView)
              const Divider(height: 1, color: AppColors.neutral200),
            Expanded(
              child: hasTeam
                  ? _buildPageView(agendaState, selectedDate, professionals)
                  : _buildContent(agendaState, selectedDate),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalTabs(List<ProfessionalModel> professionals) {
    final myId = ref.read(currentProfessionalIdProvider);

    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: professionals.length,
        itemBuilder: (context, i) {
          final prof = professionals[i];
          final isSelected = i == _currentPage;
          final isMe = prof.id == myId;
          final label = isMe ? 'Minha agenda' : prof.name.split(' ').first;

          return GestureDetector(
            onTap: () {
              _pageController.animateToPage(
                i,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              child: IntrinsicWidth(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      label,
                      style: AppTypography.body.copyWith(
                        fontSize: 14,
                        color: isSelected
                            ? AppColors.neutral900
                            : AppColors.neutral400,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      height: isSelected ? 2 : 0,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPageView(
    AgendaState agendaState,
    DateTime selectedDate,
    List<ProfessionalModel> professionals,
  ) {
    return PageView.builder(
      controller: _pageController,
      itemCount: professionals.length,
      onPageChanged: (page) => _onPageChanged(page, professionals),
      itemBuilder: (context, index) {
        final profId = professionals[index].id;
        final profData = agendaState.dataFor(profId);
        return _buildContentForProfessional(profData, selectedDate);
      },
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
            icon: Icon(
              _showMonthView
                  ? Icons.view_day_rounded
                  : Icons.calendar_month_rounded,
              color: AppColors.neutral600,
              size: 24,
            ),
            onPressed: () => setState(() => _showMonthView = !_showMonthView),
            tooltip: _showMonthView ? 'Visão diária' : 'Visão mensal',
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

    if (_showMonthView) {
      return AgendaMonthView(
        onDayTap: (date) {
          ref.read(agendaNotifierProvider.notifier).selectDate(date);
          setState(() => _showMonthView = false);
        },
      );
    }

    final appointments = agendaState.appointmentsForDay(selectedDate);
    final blockedSlots = agendaState.blockedSlotsForDay(selectedDate);

    return _buildTimeline(
      agendaState: agendaState,
      appointments: appointments,
      blockedSlots: blockedSlots,
    );
  }

  /// Build content from per-professional cached data (used by PageView pages).
  Widget _buildContentForProfessional(
    ProfessionalDayData profData,
    DateTime selectedDate,
  ) {
    final agendaState = ref.read(agendaNotifierProvider);

    // Only show skeleton on very first load (never loaded before)
    if (!profData.hasLoaded && profData.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: SkeletonTimeline(),
      );
    }

    if (profData.error != null && !profData.hasLoaded) {
      return _buildError(profData.error!);
    }

    if (_showMonthView) {
      return AgendaMonthView(
        onDayTap: (date) {
          ref.read(agendaNotifierProvider.notifier).selectDate(date);
          setState(() => _showMonthView = false);
        },
      );
    }

    final appointments = profData.appointmentsForDay(selectedDate);
    final blockedSlots = profData.blockedSlotsForDay(selectedDate);

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
    final profId = agendaState.selectedProfessionalId ??
        ref.read(currentProfessionalIdProvider) ?? '';
    return GestureDetector(
      onTap: () => QuickBookSheet.show(
        context,
        date: agendaState.selectedDate,
        professionalId: profId,
        hour: hour,
        minute: 0,
      ),
      onLongPress: () {
        HapticFeedback.mediumImpact();
        CreateAbsenceSheet.show(
          context,
          initialDate: agendaState.selectedDate,
          initialStartTime: '${hour.toString().padLeft(2, '0')}:00',
          initialEndTime: '${(hour + 1).toString().padLeft(2, '0')}:00',
          onCreated: () => ref.read(agendaNotifierProvider.notifier).refresh(),
        );
      },
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
