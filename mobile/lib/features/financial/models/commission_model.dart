import 'package:intl/intl.dart';

class CommissionModel {
  final String id;
  final String professionalId;
  final String professionalName;
  final int amount; // total appointment amount in centavos
  final int professionalAmount; // professional's cut in centavos
  final int studioAmount; // studio's cut in centavos
  final int cardFeeAmount; // card fee deducted in centavos
  final String status; // pending | paid
  final DateTime periodStart;
  final DateTime periodEnd;

  const CommissionModel({
    required this.id,
    required this.professionalId,
    required this.professionalName,
    required this.amount,
    required this.professionalAmount,
    required this.studioAmount,
    required this.cardFeeAmount,
    required this.status,
    required this.periodStart,
    required this.periodEnd,
  });

  factory CommissionModel.fromJson(Map<String, dynamic> json) {
    return CommissionModel(
      id: json['id'] as String,
      professionalId: json['professional_id'] as String? ?? '',
      professionalName: json['professional_name'] as String? ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      professionalAmount: (json['professional_amount'] as num?)?.toInt() ?? 0,
      studioAmount: (json['studio_amount'] as num?)?.toInt() ?? 0,
      cardFeeAmount: (json['card_fee_amount'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'pending',
      periodStart: DateTime.parse(json['period_start'] as String),
      periodEnd: DateTime.parse(json['period_end'] as String),
    );
  }

  static final _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  String get formattedProfessionalAmount =>
      _currencyFormat.format(professionalAmount / 100.0);

  String get formattedAmount =>
      _currencyFormat.format(amount / 100.0);

  String get formattedCardFee =>
      _currencyFormat.format(cardFeeAmount / 100.0);

  bool get isPaid => status == 'paid';
}

class CommissionSummary {
  final String professionalId;
  final String professionalName;
  final int totalProfessionalAmount; // centavos
  final int totalStudioAmount; // centavos
  final int count;
  final String status; // pending | paid | mixed

  const CommissionSummary({
    required this.professionalId,
    required this.professionalName,
    required this.totalProfessionalAmount,
    required this.totalStudioAmount,
    required this.count,
    required this.status,
  });

  factory CommissionSummary.fromJson(Map<String, dynamic> json) {
    return CommissionSummary(
      professionalId: json['professional_id'] as String? ?? '',
      professionalName: json['professional_name'] as String? ?? '',
      totalProfessionalAmount:
          (json['total_professional_amount'] as num?)?.toInt() ?? 0,
      totalStudioAmount:
          (json['total_studio_amount'] as num?)?.toInt() ?? 0,
      count: (json['count'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'pending',
    );
  }

  static final _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  String get formattedTotalAmount =>
      _currencyFormat.format(totalProfessionalAmount / 100.0);

  bool get isPaid => status == 'paid';
}
