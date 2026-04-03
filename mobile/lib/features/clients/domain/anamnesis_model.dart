class AnamnesisModel {
  final String? id;
  final String clientId;
  final String serviceCategoryId;
  final Map<String, dynamic> fields;
  final String? updatedAt;

  const AnamnesisModel({
    this.id,
    required this.clientId,
    required this.serviceCategoryId,
    required this.fields,
    this.updatedAt,
  });

  factory AnamnesisModel.fromJson(Map<String, dynamic> json) => AnamnesisModel(
        id: json['id'] as String?,
        clientId: json['client_id'] as String,
        serviceCategoryId: json['service_category_id'] as String,
        fields: (json['fields'] as Map<String, dynamic>?) ?? {},
        updatedAt: json['updated_at'] as String?,
      );
}

class AnamnesisField {
  final String key;
  final String label;
  final String type; // 'boolean', 'text', 'select'
  final List<String>? options;
  final dynamic value;

  const AnamnesisField({
    required this.key,
    required this.label,
    required this.type,
    this.options,
    this.value,
  });

  AnamnesisField copyWith({dynamic value}) => AnamnesisField(
        key: key,
        label: label,
        type: type,
        options: options,
        value: value ?? this.value,
      );
}
