import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/professional_model.dart';

class PendingInviteCard extends StatelessWidget {
  final PendingInvite invite;
  final VoidCallback? onResend;
  final VoidCallback? onCancel;

  const PendingInviteCard({
    super.key,
    required this.invite,
    this.onResend,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isExpired = invite.isExpired;
    final daysLeft = invite.expiresAt.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: isExpired ? AppColors.error.withValues(alpha: 0.3) : AppColors.neutral200,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: avatar + name + status
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: isExpired
                      ? AppColors.errorSoft
                      : AppColors.accentSoft,
                  child: Text(
                    invite.name.isNotEmpty
                        ? invite.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: isExpired ? AppColors.error : AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(invite.name, style: AppTypography.bodySemibold),
                      const SizedBox(height: 2),
                      Text(
                        'Comissão: ${invite.formattedCommission}',
                        style: AppTypography.caption
                            .copyWith(color: AppColors.neutral600),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: isExpired ? AppColors.errorSoft : AppColors.warningSoft,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    isExpired
                        ? 'Expirado'
                        : daysLeft == 0
                            ? 'Expira hoje'
                            : 'Expira em ${daysLeft}d',
                    style: AppTypography.caption.copyWith(
                      color: isExpired ? AppColors.error : AppColors.warning,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1, color: AppColors.neutral100),
            const SizedBox(height: AppSpacing.sm),
            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      onResend?.call();
                    },
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: const Text('Reenviar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF25D366),
                      side: const BorderSide(color: Color(0xFF25D366)),
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      textStyle: AppTypography.caption
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      onCancel?.call();
                    },
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Cancelar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.neutral600,
                      side: const BorderSide(color: AppColors.neutral200),
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      textStyle: AppTypography.caption
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
