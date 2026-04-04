class ServiceModel {
  final String id;
  final String name;
  final int price;
  final int durationMinutes;
  final int bufferMinutes;
  final String? categoryId;
  final String? categoryName;
  final bool isActive;

  const ServiceModel({
    required this.id,
    required this.name,
    required this.price,
    required this.durationMinutes,
    this.bufferMinutes = 0,
    this.categoryId,
    this.categoryName,
    this.isActive = true,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) => ServiceModel(
        id: json['id'] as String,
        name: json['name'] as String,
        price: json['price'] as int,
        durationMinutes: json['duration_minutes'] as int,
        bufferMinutes: (json['buffer_minutes'] as int?) ?? 0,
        categoryId: json['category_id'] as String?,
        categoryName: json['category_name'] as String?,
        isActive: (json['is_active'] as bool?) ?? true,
      );

  String get formattedPrice {
    final reais = price ~/ 100;
    final centavos = price % 100;
    return 'R\$ $reais,${centavos.toString().padLeft(2, '0')}';
  }

  String get formattedDuration => '$durationMinutes min';
}
