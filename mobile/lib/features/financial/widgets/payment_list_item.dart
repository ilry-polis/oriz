import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/payment_model.dart';

class PaymentListItemWidget extends StatelessWidget {
  final PaymentListItem payment;

  const PaymentListItemWidget({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          _MethodIcon(method: payment.method),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.clientName,
                  style: AppTypography.body.copyWith(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${payment.serviceName} · ${payment.professionalName}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.neutral400,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (payment.hasDiscount) ...[
                Text(
                  payment.formattedOriginalAmount,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.neutral400,
                    fontSize: 12,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(height: 2),
              ],
              Text(
                payment.formattedAmount,
                style: AppTypography.bodySemibold.copyWith(
                  fontSize: 14,
                  color: AppColors.neutral900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatTime(payment.createdAt),
                style: AppTypography.micro.copyWith(
                  color: AppColors.neutral400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);

    if (date == today) {
      return DateFormat.Hm('pt_BR').format(dt);
    } else {
      return DateFormat('d/MM', 'pt_BR').format(dt);
    }
  }
}

class _MethodIcon extends StatelessWidget {
  final String method;

  const _MethodIcon({required this.method});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _iconAndColor();
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 18, color: color),
    );
  }

  (IconData, Color) _iconAndColor() {
    switch (method) {
      case 'credit_card':
        return (Icons.credit_card_rounded, AppColors.info);
      case 'debit_card':
        return (Icons.credit_card_rounded, AppColors.primary);
      case 'pix':
        return (Icons.qr_code_rounded, AppColors.success);
      case 'cash':
        return (Icons.payments_outlined, AppColors.warning);
      case 'voucher':
        return (Icons.loyalty_rounded, AppColors.accent);
      default:
        return (Icons.attach_money, AppColors.neutral600);
    }
  }
}

/// Skeleton item for loading state
class PaymentListItemSkeleton extends StatelessWidget {
  const PaymentListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.neutral200,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.neutral200,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 160,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.neutral200,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 64,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.neutral200,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 32,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.neutral200,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
