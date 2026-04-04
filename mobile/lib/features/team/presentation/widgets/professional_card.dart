import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/professional_model.dart';

class ProfessionalCard extends StatelessWidget {
  final ProfessionalModel professional;
  final bool isOwner;
  final VoidCallback? onTap;

  const ProfessionalCard({
    super.key,
    required this.professional,
    this.isOwner = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initial = professional.name.isNotEmpty
        ? professional.name[0].toUpperCase()
        : '?';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Material(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(AppRadius.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap != null
              ? () {
                  HapticFeedback.lightImpact();
                  onTap!();
                }
              : null,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.neutral200),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isOwner ? AppColors.primary : AppColors.neutral200,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: AppTypography.bodySemibold.copyWith(
                      color: isOwner ? Colors.white : AppColors.neutral600,
                      fontSize: 17,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // Name + subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        professional.name,
                        style: AppTypography.bodySemibold.copyWith(
                          color: professional.isActive
                              ? AppColors.neutral900
                              : AppColors.neutral400,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isOwner
                            ? 'Proprietário'
                            : 'Comissão: ${professional.formattedCommission}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.neutral400,
                        ),
                      ),
                    ],
                  ),
                ),

                // Trailing
                if (!professional.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.neutral200,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      'Inativa',
                      style: AppTypography.micro.copyWith(
                        color: AppColors.neutral400,
                      ),
                    ),
                  )
                else if (isOwner)
                  const Icon(
                    Icons.star_rounded,
                    size: 18,
                    color: AppColors.accent,
                  )
                else
                  const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppColors.neutral300,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
