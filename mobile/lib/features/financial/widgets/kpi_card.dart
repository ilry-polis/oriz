import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// A KPI card displaying a label, formatted value, and comparison to the
/// previous period (arrow + percentage delta).
class KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final double? delta; // positive = up, negative = down, null = no comparison
  final IconData icon;

  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.delta,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.neutral400),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.micro.copyWith(
                    color: AppColors.neutral400,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTypography.title.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          if (delta != null) ...[
            const SizedBox(height: AppSpacing.xs),
            _DeltaBadge(delta: delta!),
          ],
        ],
      ),
    );
  }
}

class _DeltaBadge extends StatelessWidget {
  final double delta;

  const _DeltaBadge({required this.delta});

  @override
  Widget build(BuildContext context) {
    final isUp = delta >= 0;
    final color = isUp ? AppColors.success : AppColors.error;
    final icon = isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
    final sign = isUp ? '+' : '';
    final text = '$sign${delta.toStringAsFixed(1)}%';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 2),
        Text(
          text,
          style: AppTypography.micro.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

/// Skeleton version of KpiCard used during loading state.
class KpiCardSkeleton extends StatelessWidget {
  const KpiCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _Shimmer(width: 60, height: 10),
          const SizedBox(height: AppSpacing.sm),
          _Shimmer(width: 100, height: 20),
          const SizedBox(height: AppSpacing.xs),
          _Shimmer(width: 40, height: 10),
        ],
      ),
    );
  }
}

class _Shimmer extends StatelessWidget {
  final double width;
  final double height;

  const _Shimmer({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.neutral200,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
    );
  }
}
