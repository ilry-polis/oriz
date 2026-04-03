import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/appointment_model.dart';

class BlockedSlotCard extends StatelessWidget {
  final BlockedSlot slot;

  const BlockedSlotCard({super.key, required this.slot});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        border: Border.all(color: AppColors.neutral200),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: CustomPaint(
        painter: _DiagonalStripePainter(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              slot.reason,
              style: AppTypography.body.copyWith(color: AppColors.neutral400),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Bloqueado',
              style: AppTypography.caption.copyWith(color: AppColors.neutral400),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiagonalStripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.neutral200.withValues(alpha: 0.4)
      ..strokeWidth = 1;

    const spacing = 12.0;
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
