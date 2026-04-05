import 'package:intl/intl.dart';

enum SubscriptionStatus { active, expired, cancelled, depleted }

class PackageSubscriptionModel {
  final String id;
  final String packageId;
  final String? packageName;
  final String clientId;
  final String? clientName;
  final int sessionsTotal;
  final int sessionsUsed;
  final SubscriptionStatus status;
  final DateTime expiresAt;
  final DateTime createdAt;

  const PackageSubscriptionModel({
    required this.id,
    required this.packageId,
    this.packageName,
    required this.clientId,
    this.clientName,
    required this.sessionsTotal,
    required this.sessionsUsed,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
  });

  int get sessionsRemaining => sessionsTotal - sessionsUsed;

  bool get isExpired =>
      status == SubscriptionStatus.expired ||
      (status == SubscriptionStatus.active &&
          expiresAt.isBefore(DateTime.now()));

  bool get isActive =>
      status == SubscriptionStatus.active && !isExpired && sessionsRemaining > 0;

  double get progressFraction =>
      sessionsTotal > 0 ? sessionsUsed / sessionsTotal : 0.0;

  String get formattedExpiry {
    final fmt = DateFormat('dd/MM/yyyy', 'pt_BR');
    return fmt.format(expiresAt);
  }

  factory PackageSubscriptionModel.fromJson(Map<String, dynamic> json) {
    return PackageSubscriptionModel(
      id: json['id'] as String,
      packageId: json['package_id'] as String,
      packageName: json['package_name'] as String?,
      clientId: json['client_id'] as String,
      clientName: json['client_name'] as String?,
      sessionsTotal: json['sessions_total'] as int,
      sessionsUsed: json['sessions_used'] as int,
      status: _parseStatus(json['status'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static SubscriptionStatus _parseStatus(String value) {
    switch (value) {
      case 'active':
        return SubscriptionStatus.active;
      case 'expired':
        return SubscriptionStatus.expired;
      case 'cancelled':
        return SubscriptionStatus.cancelled;
      case 'depleted':
        return SubscriptionStatus.depleted;
      default:
        return SubscriptionStatus.active;
    }
  }

  String get statusLabel {
    switch (status) {
      case SubscriptionStatus.active:
        return isExpired ? 'Expirado' : 'Ativo';
      case SubscriptionStatus.expired:
        return 'Expirado';
      case SubscriptionStatus.cancelled:
        return 'Cancelado';
      case SubscriptionStatus.depleted:
        return 'Esgotado';
    }
  }
}
