import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/service_model.dart';

class ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleActive;
  final VoidCallback? onDelete;

  const ServiceCard({
    super.key,
    required this.service,
    this.onTap,
    this.onEdit,
    this.onToggleActive,
    this.onDelete,
  });

  void _showContextMenu(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
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
            _menuItem(ctx, Icons.edit_outlined, 'Editar serviço', onTap: () {
              Navigator.pop(ctx);
              onEdit?.call();
            }),
            _menuItem(
              ctx,
              service.isActive
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              service.isActive ? 'Desativar serviço' : 'Ativar serviço',
              onTap: () {
                Navigator.pop(ctx);
                onToggleActive?.call();
              },
            ),
            _menuItem(
              ctx,
              Icons.delete_outline,
              'Excluir serviço',
              color: AppColors.error,
              onTap: () {
                Navigator.pop(ctx);
                onDelete?.call();
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(
    BuildContext context,
    IconData icon,
    String label, {
    Color? color,
    VoidCallback? onTap,
  }) {
    final c = color ?? AppColors.neutral900;
    return ListTile(
      leading: Icon(icon, color: c, size: 22),
      title: Text(label, style: AppTypography.body.copyWith(color: c)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isActive = service.isActive;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.neutral100,
          border: Border.all(color: AppColors.neutral200),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
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
                          service.name,
                          style: AppTypography.bodySemibold.copyWith(
                            color: isActive
                                ? AppColors.neutral900
                                : AppColors.neutral400,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!isActive)
                        Container(
                          margin: const EdgeInsets.only(left: AppSpacing.sm),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.neutral200,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            'Inativo',
                            style: AppTypography.micro.copyWith(
                              color: AppColors.neutral400,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${service.formattedDuration} · ${service.formattedPrice}',
                    style: AppTypography.caption.copyWith(
                      color: isActive
                          ? AppColors.neutral600
                          : AppColors.neutral300,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _showContextMenu(context),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.more_horiz_rounded,
                  color: AppColors.neutral400,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
