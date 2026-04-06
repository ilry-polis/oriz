import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/appointment_model.dart';
import '../providers/agenda_provider.dart';
import 'cancel_dialog.dart';
import 'payment_sheet.dart';
import 'status_badge.dart';
import '../../packages/repositories/package_repository.dart';

/// Bottom sheet showing appointment details and contextual action buttons.
///
/// Opened by tapping on an appointment card.
class AppointmentDetailSheet extends ConsumerStatefulWidget {
  final Appointment appointment;

  const AppointmentDetailSheet({super.key, required this.appointment});

  static Future<void> show(
    BuildContext context, {
    required Appointment appointment,
  }) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => AppointmentDetailSheet(appointment: appointment),
    );
  }

  @override
  ConsumerState<AppointmentDetailSheet> createState() =>
      _AppointmentDetailSheetState();
}

class _AppointmentDetailSheetState
    extends ConsumerState<AppointmentDetailSheet> {
  bool _completingWithPackage = false;

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatDate(DateTime dt) {
    const months = [
      'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
      'jul', 'ago', 'set', 'out', 'nov', 'dez',
    ];
    return '${dt.day} de ${months[dt.month - 1]}';
  }

  /// Complete appointment: auto-detect active package or show PaymentSheet
  Future<void> _completeAppointment(BuildContext ctx) async {
    final appt = widget.appointment;
    Navigator.pop(ctx);

    // Check for active package subscription for this client+service
    try {
      final repo = ref.read(packageRepositoryProvider);
      final sub = await repo.getActiveForClientService(
        clientId: appt.clientId,
        serviceId: appt.serviceId,
      );

      if (!mounted) return;

      if (sub != null) {
        // Package path: skip payment sheet, complete directly
        setState(() => _completingWithPackage = true);
        try {
          final result =
              await ref.read(agendaNotifierProvider.notifier).completeAppointmentFull(
                    appt.id,
                    packageSubscriptionId: sub.id,
                  );

          if (!mounted) return;

          // Show toast feedback
          final sessionsRemaining = result['data']?['sessionsRemaining'] as int?;
          final lastSession = result['data']?['lastSession'] as bool? ?? false;
          final packageName = sub.packageName ?? 'Pacote';

          if (lastSession) {
            _showLastSessionDialog(ctx, appt, sub.packageId, packageName, appt.clientName);
          } else {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text(
                  sessionsRemaining != null
                      ? 'Sessao deduzida — $packageName: $sessionsRemaining restante(s)'
                      : 'Sessao deduzida do pacote $packageName',
                ),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            );
          }
        } finally {
          if (mounted) setState(() => _completingWithPackage = false);
        }
      } else {
        // No package: show payment sheet
        if (mounted) {
          PaymentSheet.show(ctx, appointment: appt);
        }
      }
    } catch (_) {
      // On error checking package, fall back to payment sheet
      if (mounted) {
        PaymentSheet.show(ctx, appointment: appt);
      }
    }
  }

  void _showLastSessionDialog(
    BuildContext ctx,
    Appointment appt,
    String packageId,
    String packageName,
    String clientName,
  ) {
    showDialog<void>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          'Ultima sessao do pacote',
          style: AppTypography.title,
        ),
        content: Text(
          'Ultima sessao do pacote "$packageName" de $clientName foi concluida.',
          style: AppTypography.body.copyWith(color: AppColors.neutral600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Fechar',
              style: AppTypography.body.copyWith(color: AppColors.neutral600),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              // TODO: implement renewal (creates new subscription for same package)
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(
                  content: Text('Funcionalidade de renovacao em breve'),
                ),
              );
            },
            child: Text(
              'Renovar pacote',
              style: AppTypography.body.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appt = widget.appointment;
    // ref is available from ConsumerState

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.neutral300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header: client name + status
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(appt.clientName, style: AppTypography.title),
                ),
                StatusBadge(status: appt.status),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.neutral200, height: 1),
          // Detail rows
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0,
            ),
            child: Column(
              children: [
                _detailRow(
                  Icons.cut_rounded,
                  appt.serviceName,
                  '${appt.durationMinutes}min',
                ),
                const SizedBox(height: AppSpacing.sm),
                _detailRow(
                  Icons.access_time_rounded,
                  '${_formatDate(appt.startTime)} • ${_formatTime(appt.startTime)} – ${_formatTime(appt.endTime)}',
                  null,
                ),
                const SizedBox(height: AppSpacing.sm),
                _detailRow(
                  Icons.person_outline_rounded,
                  appt.professionalName,
                  null,
                ),
                if (appt.notes != null && appt.notes!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _detailRow(
                    Icons.notes_rounded,
                    appt.notes!,
                    null,
                  ),
                ],
                if (appt.cancellationReason != null &&
                    appt.cancellationReason!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _detailRow(
                    Icons.info_outline_rounded,
                    'Motivo: ${appt.cancellationReason}',
                    null,
                    color: AppColors.neutral600,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Action buttons
          if (!appt.isTerminal) ...[
            const Divider(color: AppColors.neutral200, height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: _buildActionButtons(context, ref, appt),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.neutral200),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: Text(
                    'Fechar',
                    style: AppTypography.bodySemibold.copyWith(
                      color: AppColors.neutral600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(
    IconData icon,
    String text,
    String? trailing, {
    Color? color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: color ?? AppColors.neutral400,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: AppTypography.body.copyWith(
              color: color ?? AppColors.neutral900,
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.xs),
          Text(
            trailing,
            style: AppTypography.caption,
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    Appointment appt,
  ) {
    final notifier = ref.read(agendaNotifierProvider.notifier);

    if (appt.canConfirm) {
      // Pending: Confirm (primary) + Cancel (destructive)
      return Row(
        children: [
          Expanded(
            child: _primaryButton(
              label: 'Confirmar',
              color: AppColors.info,
              onPressed: () async {
                Navigator.pop(context);
                await notifier.confirmAppointment(appt.id);
              },
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _destructiveButton(
              label: 'Cancelar',
              onPressed: () {
                Navigator.pop(context);
                CancelDialog.show(context, appointment: appt);
              },
            ),
          ),
        ],
      );
    }

    if (appt.canComplete) {
      // Confirmed: Complete (primary) + Cancel + No show
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: _primaryButton(
              label: _completingWithPackage ? 'Concluindo...' : 'Concluir',
              color: AppColors.success,
              onPressed: _completingWithPackage
                  ? () {}
                  : () => _completeAppointment(context),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _destructiveButton(
                  label: 'Cancelar',
                  onPressed: () {
                    Navigator.pop(context);
                    CancelDialog.show(context, appointment: appt);
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _warningButton(
                  label: 'Nao compareceu',
                  onPressed: () async {
                    Navigator.pop(context);
                    await notifier.markNoShow(appt.id);
                  },
                ),
              ),
            ],
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _primaryButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: AppTypography.bodySemibold,
        ),
        child: Text(label),
      ),
    );
  }

  Widget _destructiveButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: AppTypography.bodySemibold,
        ),
        child: Text(label),
      ),
    );
  }

  Widget _warningButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.warning,
          side: const BorderSide(color: AppColors.warning),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: AppTypography.bodySemibold,
        ),
        child: Text(label),
      ),
    );
  }
}
