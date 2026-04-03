import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'models/appointment_model.dart';
import 'widgets/appointment_card.dart';
import 'widgets/blocked_slot_card.dart';
import 'widgets/day_selector.dart';
import 'widgets/empty_agenda.dart';
import 'widgets/quick_book_sheet.dart';
import 'widgets/skeleton_timeline.dart';

enum _ViewState { loading, data, empty, error }

class AgendaDayScreen extends StatefulWidget {
  const AgendaDayScreen({super.key});

  @override
  State<AgendaDayScreen> createState() => _AgendaDayScreenState();
}

class _AgendaDayScreenState extends State<AgendaDayScreen> {
  DateTime _selectedDate = DateTime.now();
  _ViewState _state = _ViewState.loading;
  List<Appointment> _appointments = [];
  List<BlockedSlot> _blockedSlots = [];
  int? _dragOverHour;

  // Working hours from studio config
  static const _startHour = 8;
  static const _endHour = 19;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _state = _ViewState.loading);

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    final appointments = mockAppointments(_selectedDate);
    final blockedSlots = mockBlockedSlots(_selectedDate);

    setState(() {
      _appointments = appointments;
      _blockedSlots = blockedSlots;
      _state = appointments.isEmpty && blockedSlots.isEmpty
          ? _ViewState.empty
          : _ViewState.data;
    });
  }

  void _onDateSelected(DateTime date) {
    setState(() => _selectedDate = date);
    _loadData();
  }

  void _moveAppointment(Appointment appointment, int newHour) {
    final duration = appointment.endTime.difference(appointment.startTime);
    final newStart = DateTime(
      _selectedDate.year, _selectedDate.month, _selectedDate.day, newHour,
    );
    final newEnd = newStart.add(duration);

    setState(() {
      _appointments = _appointments.map((a) {
        if (a.id == appointment.id) {
          return Appointment(
            id: a.id,
            clientName: a.clientName,
            serviceName: a.serviceName,
            durationMinutes: a.durationMinutes,
            startTime: newStart,
            endTime: newEnd,
            status: a.status,
          );
        }
        return a;
      }).toList();
      _dragOverHour = null;
    });

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
  }

  bool _canDropAt(int hour) {
    // Can't drop on a blocked slot
    final blocked = _blockedSlots.any((b) => b.startTime.hour == hour);
    return !blocked;
  }

  String get _dateLabel {
    const weekdays = [
      'Segunda', 'Terça', 'Quarta', 'Quinta',
      'Sexta', 'Sábado', 'Domingo',
    ];
    const months = [
      'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
      'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
    ];
    final wd = weekdays[_selectedDate.weekday - 1];
    final m = months[_selectedDate.month - 1];
    return '$wd, ${_selectedDate.day} de $m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildDateSection(),
            const Divider(height: 1, color: AppColors.neutral200),
            Expanded(child: _buildContent()),
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
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => HapticFeedback.lightImpact(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _dateLabel,
            style: AppTypography.body.copyWith(color: AppColors.neutral600),
          ),
          const SizedBox(height: AppSpacing.md),
          DaySelector(
            selectedDate: _selectedDate,
            onDateSelected: _onDateSelected,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return switch (_state) {
      _ViewState.loading => const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: SkeletonTimeline(),
      ),
      _ViewState.empty => EmptyAgenda(
        onCreateAppointment: () => QuickBookSheet.show(
          context, hour: 9, date: _selectedDate,
        ),
      ),
      _ViewState.error => _buildError(),
      _ViewState.data => _buildTimeline(),
    };
  }

  Widget _buildTimeline() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        itemCount: _endHour - _startHour,
        itemBuilder: (context, index) {
          final hour = _startHour + index;
          return _buildTimeSlot(hour);
        },
      ),
    );
  }

  Widget _buildTimeSlot(int hour) {
    final hourLabel = '${hour.toString().padLeft(2, '0')}:00';

    final appointment = _appointments.where(
      (a) => a.startTime.hour == hour,
    ).firstOrNull;

    final blocked = _blockedSlots.where(
      (b) => b.startTime.hour == hour,
    ).firstOrNull;

    final isDragOver = _dragOverHour == hour;
    final canDrop = _canDropAt(hour);

    // Wrap each slot in a DragTarget for appointment reordering
    return DragTarget<Appointment>(
      onWillAcceptWithDetails: (details) {
        if (!canDrop) return false;
        // Don't accept on its own slot
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
                  border: Border.all(
                    color: AppColors.accent,
                    width: 2,
                  ),
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
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: BlockedSlotCard(slot: blocked),
                          )
                        : _buildEmptySlot(hour),
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
            border: Border.all(
              color: AppColors.neutral300,
              style: BorderStyle.solid,
            ),
          ),
          child: Center(
            child: Text(
              'Solte em outro horário',
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
          onTap: () {},
          onComplete: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${appointment.clientName} concluído!'),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            );
          },
          onCancel: () {},
        ),
      ),
    );
  }

  Widget _buildEmptySlot(int hour) {
    return GestureDetector(
      onTap: () => QuickBookSheet.show(
        context, hour: hour, date: _selectedDate,
      ),
      child: Container(
        height: 44, // minimum touch target
        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                color: AppColors.neutral200,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.add_circle_outline_rounded,
              size: 18,
              color: AppColors.neutral300,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
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
              'Verifique sua conexão e tente novamente.',
              style: AppTypography.body.copyWith(color: AppColors.neutral600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: _loadData,
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
