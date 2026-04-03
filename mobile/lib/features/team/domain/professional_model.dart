class ProfessionalModel {
  final String id;
  final String name;
  final String commissionType;
  final double commissionValue;
  final String cardFeePolicy;
  final bool isActive;
  final List<String> serviceIds;
  final String? userId;

  const ProfessionalModel({
    required this.id,
    required this.name,
    required this.commissionType,
    required this.commissionValue,
    required this.cardFeePolicy,
    required this.isActive,
    this.serviceIds = const [],
    this.userId,
  });

  factory ProfessionalModel.fromJson(Map<String, dynamic> json) =>
      ProfessionalModel(
        id: json['id'] as String,
        name: json['name'] as String,
        commissionType: (json['commission_type'] as String?) ?? 'percentage',
        commissionValue: (json['commission_value'] as num?)?.toDouble() ?? 0,
        cardFeePolicy: (json['card_fee_policy'] as String?) ?? 'studio',
        isActive: (json['is_active'] as bool?) ?? true,
        serviceIds: (json['service_ids'] as List?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        userId: json['user_id'] as String?,
      );

  String get formattedCommission {
    if (commissionType == 'percentage') {
      return '${commissionValue.toStringAsFixed(0)}%';
    }
    final reais = commissionValue ~/ 100;
    return 'R\$ $reais';
  }
}

class InviteInfo {
  final String studioName;
  final String professionalName;
  final bool expired;
  final bool used;

  const InviteInfo({
    required this.studioName,
    required this.professionalName,
    this.expired = false,
    this.used = false,
  });

  factory InviteInfo.fromJson(Map<String, dynamic> json) => InviteInfo(
        studioName: json['studio_name'] as String,
        professionalName: json['professional_name'] as String,
        expired: (json['expired'] as bool?) ?? false,
        used: (json['used'] as bool?) ?? false,
      );
}
