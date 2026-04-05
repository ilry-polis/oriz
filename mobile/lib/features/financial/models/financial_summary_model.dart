import 'package:intl/intl.dart';

class MethodBreakdown {
  final String method;
  final int totalAmount; // centavos
  final int count;
  final double percentage;

  const MethodBreakdown({
    required this.method,
    required this.totalAmount,
    required this.count,
    required this.percentage,
  });

  factory MethodBreakdown.fromJson(Map<String, dynamic> json) {
    return MethodBreakdown(
      method: json['method'] as String? ?? '',
      totalAmount: FinancialSummaryModel._toInt(json['total_amount']),
      count: FinancialSummaryModel._toInt(json['count']),
      percentage: FinancialSummaryModel._toDouble(json['percentage']),
    );
  }

  String get methodLabel {
    switch (method) {
      case 'credit':
        return 'Crédito';
      case 'debit':
        return 'Débito';
      case 'pix':
        return 'Pix';
      case 'cash':
        return 'Dinheiro';
      default:
        return method;
    }
  }

  static final _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  String get formattedAmount => _currencyFormat.format(totalAmount / 100.0);
}

class DailyRevenue {
  final String date; // 'yyyy-MM-dd'
  final int totalAmount; // centavos
  final int appointmentCount;

  const DailyRevenue({
    required this.date,
    required this.totalAmount,
    required this.appointmentCount,
  });

  factory DailyRevenue.fromJson(Map<String, dynamic> json) {
    return DailyRevenue(
      date: json['date'] as String? ?? '',
      totalAmount: FinancialSummaryModel._toInt(json['total_amount']),
      appointmentCount: FinancialSummaryModel._toInt(json['appointment_count']),
    );
  }
}

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
      totalRevenue: _toInt(json['total_revenue']),
      avgTicket: _toInt(json['avg_ticket']),
      totalAppointments: _toInt(json['total_appointments']),
      occupancyRate: _toDouble(json['occupancy_rate']),
      period: json['period'] as String? ?? '',
    );
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
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
      totalAmount: FinancialSummaryModel._toInt(json['total_amount']),
      percentage: FinancialSummaryModel._toDouble(json['percentage']),
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
