import 'package:intl/intl.dart';

class PackageModel {
  final String id;
  final List<String> serviceIds;
  final List<String> serviceNames;
  final String name;
  final int totalSessions;
  final int price; // in centavos
  final int validityDays;
  final DateTime createdAt;

  const PackageModel({
    required this.id,
    this.serviceIds = const [],
    this.serviceNames = const [],
    required this.name,
    required this.totalSessions,
    required this.price,
    required this.validityDays,
    required this.createdAt,
  });

  factory PackageModel.fromJson(Map<String, dynamic> json) {
    return PackageModel(
      id: json['id'] as String,
      serviceIds: (json['service_ids'] as List?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      serviceNames: (json['service_names'] as List?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      name: json['name'] as String,
      totalSessions: json['total_sessions'] as int,
      price: json['price'] as int,
      validityDays: json['validity_days'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Comma-separated service names for display.
  String get serviceLabel =>
      serviceNames.isNotEmpty ? serviceNames.join(', ') : 'Sem serviço';

  String get formattedPrice {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return fmt.format(price / 100.0);
  }

  String get validityLabel {
    if (validityDays == 30) return '1 mês';
    if (validityDays == 60) return '2 meses';
    if (validityDays == 90) return '3 meses';
    if (validityDays == 180) return '6 meses';
    if (validityDays == 365) return '1 ano';
    return '$validityDays dias';
  }
}
