double _parseDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

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
        commissionValue: _parseDouble(json['commission_value']),
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

class PendingInvite {
  final String token;
  final String name;
  final String? phone;
  final String commissionType;
  final double commissionValue;
  final String cardFeePolicy;
  final DateTime expiresAt;
  final DateTime createdAt;

  const PendingInvite({
    required this.token,
    required this.name,
    this.phone,
    required this.commissionType,
    required this.commissionValue,
    required this.cardFeePolicy,
    required this.expiresAt,
    required this.createdAt,
  });

  factory PendingInvite.fromJson(Map<String, dynamic> json) => PendingInvite(
        token: json['token'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String?,
        commissionType: (json['commission_type'] as String?) ?? 'percentage',
        commissionValue: _parseDouble(json['commission_value']),
        cardFeePolicy: (json['card_fee_policy'] as String?) ?? 'studio',
        expiresAt: DateTime.parse(json['expires_at'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  bool get isExpired => expiresAt.isBefore(DateTime.now());

  String get formattedCommission {
    if (commissionType == 'percentage') {
      return '${commissionValue.toStringAsFixed(0)}%';
    }
    final reais = commissionValue ~/ 100;
    return 'R\$ $reais';
  }
}
