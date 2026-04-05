import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/financial_summary_model.dart';

class MethodDonutChart extends StatefulWidget {
  final List<MethodBreakdown> data;

  const MethodDonutChart({super.key, required this.data});

  @override
  State<MethodDonutChart> createState() => _MethodDonutChartState();
}

class _MethodDonutChartState extends State<MethodDonutChart> {
  int? _touchedIndex;

  static final _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  Color _colorForMethod(String method) {
    switch (method) {
      case 'credit':
        return AppColors.info;
      case 'debit':
        return AppColors.primary;
      case 'pix':
        return AppColors.success;
      case 'cash':
        return AppColors.warning;
      default:
        return AppColors.neutral400;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'Sem dados de métodos no período',
            style: AppTypography.caption.copyWith(color: AppColors.neutral400),
          ),
        ),
      );
    }

    final total = widget.data.fold<int>(0, (sum, e) => sum + e.totalAmount);
    final formattedTotal = _currencyFormat.format(total / 100.0);

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      setState(() {
                        if (response == null ||
                            response.touchedSection == null) {
                          _touchedIndex = null;
                        } else {
                          _touchedIndex = response
                              .touchedSection!.touchedSectionIndex;
                        }
                      });
                    },
                  ),
                  sectionsSpace: 2,
                  centerSpaceRadius: 60,
                  sections: widget.data.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final isTouched = _touchedIndex == index;
                    return PieChartSectionData(
                      value: item.totalAmount.toDouble(),
                      color: _colorForMethod(item.method),
                      radius: isTouched ? 36 : 28,
                      showTitle: false,
                    );
                  }).toList(),
                ),
              ),
              // Center label
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total',
                    style: AppTypography.micro.copyWith(
                      color: AppColors.neutral400,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formattedTotal,
                    style: AppTypography.bodySemibold.copyWith(fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Legend
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xs,
          alignment: WrapAlignment.center,
          children: widget.data.map((item) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _colorForMethod(item.method),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${item.methodLabel} ${item.percentage.toStringAsFixed(0)}%',
                  style: AppTypography.micro.copyWith(
                    fontSize: 11,
                    color: AppColors.neutral600,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

class MethodDonutChartCard extends StatelessWidget {
  final List<MethodBreakdown> data;

  const MethodDonutChartCard({super.key, required this.data});

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
        children: [
          Text(
            'Por método',
            style: AppTypography.body.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          MethodDonutChart(data: data),
        ],
      ),
    );
  }
}
