import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/financial_summary_model.dart';

/// Expandable section with a ranked list of breakdown items (by professional
/// or by service), showing name, formatted value, and a percentage bar.
class BreakdownSection extends StatelessWidget {
  final String title;
  final List<BreakdownItem> items;
  final bool initiallyExpanded;

  const BreakdownSection({
    super.key,
    required this.title,
    required this.items,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          childrenPadding: EdgeInsets.zero,
          title: Text(
            title,
            style: AppTypography.body.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: items.isEmpty
              ? Text(
                  'Sem dados',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.neutral400,
                    fontSize: 12,
                  ),
                )
              : null,
          children: [
            const Divider(
              height: 1,
              thickness: 1,
              color: AppColors.neutral200,
            ),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  'Nenhum dado no período',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.neutral400,
                  ),
                ),
              )
            else
              ...items.asMap().entries.map(
                    (entry) => _BreakdownRow(
                      item: entry.value,
                      rank: entry.key + 1,
                      isLast: entry.key == items.length - 1,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final BreakdownItem item;
  final int rank;
  final bool isLast;

  const _BreakdownRow({
    required this.item,
    required this.rank,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              // Rank badge
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: rank == 1
                      ? AppColors.accentSoft
                      : AppColors.neutral100,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$rank',
                  style: AppTypography.micro.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: rank == 1
                        ? const Color(0xFF92740A)
                        : AppColors.neutral600,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Name + bar
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: AppTypography.caption.copyWith(
                              fontSize: 13,
                              color: AppColors.neutral900,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          item.formattedAmount,
                          style: AppTypography.caption.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.neutral900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(AppRadius.full),
                            child: LinearProgressIndicator(
                              value: item.percentage / 100.0,
                              backgroundColor: AppColors.neutral200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                rank == 1
                                    ? AppColors.accent
                                    : AppColors.primary.withValues(alpha: 0.5),
                              ),
                              minHeight: 4,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        SizedBox(
                          width: 36,
                          child: Text(
                            '${item.percentage.toStringAsFixed(0)}%',
                            style: AppTypography.micro.copyWith(
                              fontSize: 10,
                              color: AppColors.neutral400,
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(
            height: 1,
            thickness: 1,
            color: AppColors.neutral200,
            indent: AppSpacing.md,
          ),
      ],
    );
  }
}
