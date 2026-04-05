import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/financial_summary_model.dart';

enum ChartPeriod { day, week, month }

class RevenueBarChart extends StatefulWidget {
  final List<DailyRevenue> data;
  final ChartPeriod period;

  const RevenueBarChart({super.key, required this.data, this.period = ChartPeriod.month});

  @override
  State<RevenueBarChart> createState() => _RevenueBarChartState();
}

class _RevenueBarChartState extends State<RevenueBarChart> {
  int? _touchedIndex;

  static const _weekdayLabels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

  static final _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  String? _labelForIndex(int index, String dateStr) {
    switch (widget.period) {
      case ChartPeriod.day:
        // Single bar — show "Hoje" or the date
        return dateStr.length >= 10 ? dateStr.substring(8, 10) : dateStr;
      case ChartPeriod.week:
        // 7 bars — show weekday abbreviation
        if (dateStr.length >= 10) {
          final parsed = DateTime.tryParse(dateStr);
          if (parsed != null) {
            return _weekdayLabels[(parsed.weekday - 1) % 7];
          }
        }
        return dateStr;
      case ChartPeriod.month:
        // ~30 bars — show day number, skip to avoid crowding
        final day = dateStr.length >= 10 ? dateStr.substring(8, 10) : dateStr;
        final step = (widget.data.length / 7).ceil().clamp(1, 99);
        if (index % step != 0 && index != widget.data.length - 1) {
          return null;
        }
        return day;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'Sem dados de faturamento no período',
            style: AppTypography.caption.copyWith(color: AppColors.neutral400),
          ),
        ),
      );
    }

    final maxAmount = widget.data
        .map((e) => e.totalAmount)
        .reduce((a, b) => a > b ? a : b);

    final maxY = maxAmount == 0 ? 100.0 : (maxAmount * 1.2).toDouble();

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.primary,
              tooltipBorderRadius: BorderRadius.circular(AppRadius.sm),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final item = widget.data[group.x];
                return BarTooltipItem(
                  _currencyFormat.format(item.totalAmount / 100.0),
                  AppTypography.micro.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
            touchCallback: (event, response) {
              setState(() {
                if (response == null || response.spot == null) {
                  _touchedIndex = null;
                } else {
                  _touchedIndex = response.spot!.touchedBarGroupIndex;
                }
              });
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= widget.data.length) {
                    return const SizedBox.shrink();
                  }
                  final dateStr = widget.data[index].date;
                  final label = _labelForIndex(index, dateStr);
                  if (label == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      label,
                      style: AppTypography.micro.copyWith(
                        fontSize: 10,
                        color: AppColors.neutral400,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (value, meta) {
                  if (value == 0) {
                    return Text(
                      'R\$0',
                      style: AppTypography.micro.copyWith(
                        fontSize: 10,
                        color: AppColors.neutral400,
                      ),
                    );
                  }
                  if (value == meta.max) return const SizedBox.shrink();
                  final formatted = value >= 100000
                      ? 'R\$${(value / 100000).toStringAsFixed(1)}k'
                      : 'R\$${(value / 100).toStringAsFixed(0)}';
                  return Text(
                    formatted,
                    style: AppTypography.micro.copyWith(
                      fontSize: 9,
                      color: AppColors.neutral400,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppColors.neutral200,
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ),
          barGroups: widget.data.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isTouched = _touchedIndex == index;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: item.totalAmount.toDouble(),
                  color: isTouched
                      ? AppColors.accent
                      : AppColors.primary.withValues(alpha: 0.8),
                  width: widget.data.length > 20 ? 6 : 10,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.sm),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class RevenueBarChartCard extends StatelessWidget {
  final List<DailyRevenue> data;
  final ChartPeriod period;

  const RevenueBarChartCard({super.key, required this.data, this.period = ChartPeriod.month});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: RevenueBarChart(data: data, period: period),
    );
  }
}
