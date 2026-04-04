import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/appointment_model.dart';

class BlockedSlotCard extends StatelessWidget {
  final BlockedSlot slot;

  /// Called when "Remover todas" (or "Remover ausencia") is selected.
  final VoidCallback? onDelete;

  /// Called when "Remover so este dia" is selected (recurring only).
  final VoidCallback? onRemoveOccurrence;

  const BlockedSlotCard({
    super.key,
    required this.slot,
    this.onDelete,
    this.onRemoveOccurrence,
  });

  void _showOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.neutral300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(slot.displayTitle, style: AppTypography.bodySemibold),
              ),
            ),
            if (slot.isRecurring)
              ListTile(
                leading: const Icon(Icons.event_available_rounded, color: AppColors.neutral900, size: 22),
                title: Text('Remover so este dia', style: AppTypography.body),
                onTap: () {
                  Navigator.pop(ctx);
                  onRemoveOccurrence?.call();
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 22),
              title: Text(
                slot.isRecurring ? 'Remover todas' : 'Remover ausencia',
                style: AppTypography.body.copyWith(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(ctx);
                onDelete?.call();
              },
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            ),
            ListTile(
              leading: const Icon(Icons.close_rounded, color: AppColors.neutral600, size: 22),
              title: Text('Fechar', style: AppTypography.body.copyWith(color: AppColors.neutral600)),
              onTap: () => Navigator.pop(ctx),
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showOptions(context),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.neutral100,
          border: Border.all(color: AppColors.neutral200),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: CustomPaint(
          painter: _DiagonalStripePainter(),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            slot.displayTitle,
                            style: AppTypography.body.copyWith(color: AppColors.neutral600),
                          ),
                        ),
                        if (slot.isRecurring)
                          const Icon(Icons.repeat_rounded, size: 14, color: AppColors.neutral400),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Ausencia',
                      style: AppTypography.caption.copyWith(color: AppColors.neutral400),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
