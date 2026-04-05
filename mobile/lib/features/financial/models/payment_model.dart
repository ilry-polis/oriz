import 'package:intl/intl.dart';

class PaymentListItem {
  final String id;
  final int amount; // centavos
  final int discountAmount; // centavos
  final String method;
  final String clientName;
  final String professionalName;
  final String serviceName;
  final DateTime createdAt;

  const PaymentListItem({
    required this.id,
    required this.amount,
    required this.discountAmount,
    required this.method,
    required this.clientName,
    required this.professionalName,
    required this.serviceName,
    required this.createdAt,
  });

  factory PaymentListItem.fromJson(Map<String, dynamic> json) {
    return PaymentListItem(
      id: json['id'] as String,
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      discountAmount: (json['discount_amount'] as num?)?.toInt() ?? 0,
      method: json['method'] as String? ?? '',
      clientName: json['client_name'] as String? ?? '',
      professionalName: json['professional_name'] as String? ?? '',
      serviceName: json['service_name'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static final _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  String get formattedAmount =>
      _currencyFormat.format(amount / 100.0);

  String get formattedOriginalAmount {
    final originalAmount = amount + discountAmount;
    return _currencyFormat.format(originalAmount / 100.0);
  }

  bool get hasDiscount => discountAmount > 0;

  String get methodLabel {
    switch (method) {
      case 'credit_card':
        return 'Crédito';
      case 'debit_card':
        return 'Débito';
      case 'pix':
        return 'Pix';
      case 'cash':
        return 'Dinheiro';
      case 'voucher':
        return 'Voucher';
      default:
        return method;
    }
  }
}
