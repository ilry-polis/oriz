class ServiceTemplate {
  final String category;
  final String name;
  final int durationMinutes;
  final int price; // centavos

  const ServiceTemplate({
    required this.category,
    required this.name,
    required this.durationMinutes,
    required this.price,
  });
}

const serviceTemplates = <ServiceTemplate>[
  // Unhas
  ServiceTemplate(category: 'Unhas', name: 'Manicure', durationMinutes: 30, price: 5000),
  ServiceTemplate(category: 'Unhas', name: 'Pedicure', durationMinutes: 45, price: 6000),
  ServiceTemplate(category: 'Unhas', name: 'Esmaltacao em gel', durationMinutes: 60, price: 8000),

  // Cilios
  ServiceTemplate(category: 'Cilios', name: 'Extensao de cilios', durationMinutes: 90, price: 15000),
  ServiceTemplate(category: 'Cilios', name: 'Lash lifting', durationMinutes: 60, price: 10000),

  // Cabelo
  ServiceTemplate(category: 'Cabelo', name: 'Corte feminino', durationMinutes: 45, price: 8000),
  ServiceTemplate(category: 'Cabelo', name: 'Escova', durationMinutes: 30, price: 5000),
  ServiceTemplate(category: 'Cabelo', name: 'Coloracao', durationMinutes: 120, price: 20000),

  // Micropigmentacao
  ServiceTemplate(category: 'Micropigmentacao', name: 'Sobrancelha', durationMinutes: 120, price: 40000),
  ServiceTemplate(category: 'Micropigmentacao', name: 'Labios', durationMinutes: 120, price: 50000),

  // Sobrancelha
  ServiceTemplate(category: 'Sobrancelha', name: 'Design de sobrancelha', durationMinutes: 30, price: 4000),
  ServiceTemplate(category: 'Sobrancelha', name: 'Henna', durationMinutes: 30, price: 5000),

  // Depilacao
  ServiceTemplate(category: 'Depilacao', name: 'Buzzo', durationMinutes: 15, price: 2000),
  ServiceTemplate(category: 'Depilacao', name: 'Meia perna', durationMinutes: 30, price: 4000),
];

const categoryNames = [
  'Unhas',
  'Cilios',
  'Cabelo',
  'Micropigmentacao',
  'Sobrancelha',
  'Depilacao',
  'Outro',
];

List<ServiceTemplate> templatesForCategory(String category) {
  return serviceTemplates.where((t) => t.category == category).toList();
}
