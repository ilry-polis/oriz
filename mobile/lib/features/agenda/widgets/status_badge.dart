import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/appointment_model.dart';

class StatusBadge extends StatelessWidget {
  final AppointmentStatus status;

  const StatusBadge({super.key, required this.status});

  (Color, Color, String) get _config => switch (status) {
    AppointmentStatus.confirmed => (AppColors.infoSoft, AppColors.info, 'Confirmado'),
    AppointmentStatus.completed => (AppColors.successSoft, AppColors.success, 'Concluído'),
    AppointmentStatus.cancelled => (AppColors.errorSoft, AppColors.error, 'Cancelado'),
    AppointmentStatus.noShow => (AppColors.warningSoft, AppColors.warning, 'Não compareceu'),
  };

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = _config;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(label, style: AppTypography.micro.copyWith(color: fg)),
    );
  }
}
