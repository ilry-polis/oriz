import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/appointment_model.dart';
import '../providers/agenda_provider.dart';

/// AlertDialog for cancelling an appointment, with optional reason text field.
class CancelDialog extends ConsumerStatefulWidget {
  final Appointment appointment;

  const CancelDialog({super.key, required this.appointment});

  static Future<void> show(
    BuildContext context, {
    required Appointment appointment,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => CancelDialog(appointment: appointment),
    );
  }

  @override
  ConsumerState<CancelDialog> createState() => _CancelDialogState();
}

class _CancelDialogState extends ConsumerState<CancelDialog> {
  final _reasonController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    HapticFeedback.heavyImpact();
    setState(() => _submitting = true);
    try {
      final reason = _reasonController.text.trim();
      await ref.read(agendaNotifierProvider.notifier).cancelAppointment(
            widget.appointment.id,
            reason: reason.isEmpty ? null : reason,
          );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      title: const Text(
        'Cancelar agendamento?',
        style: AppTypography.title,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tem certeza que deseja cancelar o agendamento de '
            '${widget.appointment.clientName} — '
            '${widget.appointment.serviceName}?',
            style: AppTypography.body.copyWith(color: AppColors.neutral600),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _reasonController,
            decoration: InputDecoration(
              hintText: 'Motivo do cancelamento (opcional)',
              hintStyle: AppTypography.body.copyWith(
                color: AppColors.neutral400,
              ),
              filled: true,
              fillColor: AppColors.neutral100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.neutral200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.neutral200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              contentPadding: const EdgeInsets.all(AppSpacing.sm),
            ),
            maxLines: 2,
            style: AppTypography.body,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: Text(
            'Voltar',
            style: AppTypography.body.copyWith(color: AppColors.neutral600),
          ),
        ),
        TextButton(
          onPressed: _submitting ? null : _confirm,
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.error,
                  ),
                )
              : Text(
                  'Cancelar agendamento',
                  style: AppTypography.body.copyWith(color: AppColors.error),
                ),
        ),
      ],
    );
  }
}
