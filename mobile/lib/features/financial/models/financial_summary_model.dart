import 'package:intl/intl.dart';

class FinancialSummaryModel {
  final int totalRevenue; // centavos
  final int avgTicket; // centavos
  final int totalAppointments;
  final double occupancyRate; // 0-100
  final String period;

  const FinancialSummaryModel({
    required this.totalRevenue,
    required this.avgTicket,
    required this.totalAppointments,
    required this.occupancyRate,
    required this.period,
  });

  factory FinancialSummaryModel.fromJson(Map<String, dynamic> json) {
    return FinancialSummaryModel(
      totalRevenue: (json['total_revenue'] as num?)?.toInt() ?? 0,
      avgTicket: (json['avg_ticket'] as num?)?.toInt() ?? 0,
      totalAppointments: (json['total_appointments'] as num?)?.toInt() ?? 0,
      occupancyRate: (json['occupancy_rate'] as num?)?.toDouble() ?? 0.0,
      period: json['period'] as String? ?? '',
    );
  }

  static final _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  String get formattedRevenue =>
      _currencyFormat.format(totalRevenue / 100.0);

  String get formattedAvgTicket =>
      _currencyFormat.format(avgTicket / 100.0);

  String get formattedOccupancy =>
      '${occupancyRate.toStringAsFixed(0)}%';

  String get formattedAppointments => totalAppointments.toString();
}

class BreakdownItem {
  final String id;
  final String name;
  final int totalAmount; // centavos
  final double percentage;

  const BreakdownItem({
    required this.id,
    required this.name,
    required this.totalAmount,
    required this.percentage,
  });

  factory BreakdownItem.fromJson(Map<String, dynamic> json) {
    return BreakdownItem(
      id: json['professional_id'] as String? ??
          json['service_id'] as String? ??
          '',
      name: json['professional_name'] as String? ??
          json['service_name'] as String? ??
          '',
      totalAmount: (json['total_amount'] as num?)?.toInt() ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  static final _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  String get formattedAmount =>
      _currencyFormat.format(totalAmount / 100.0);
}
