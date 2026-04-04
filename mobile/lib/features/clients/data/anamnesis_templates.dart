import '../domain/anamnesis_model.dart';

const _lash = [
  {'key': 'alergia_cola', 'label': 'Alergia a cola de cílios', 'type': 'boolean'},
  {'key': 'lentes_contato', 'label': 'Usa lentes de contato', 'type': 'boolean'},
  {'key': 'lagrima_artificial', 'label': 'Usa lágrima artificial', 'type': 'boolean'},
  {'key': 'observacoes', 'label': 'Observações', 'type': 'text'},
];

const _micropig = [
  {'key': 'gravidez', 'label': 'Gestante ou lactante', 'type': 'boolean'},
  {'key': 'anticoagulante', 'label': 'Usa anticoagulante', 'type': 'boolean'},
  {'key': 'queloides', 'label': 'Tendência a queloides', 'type': 'boolean'},
  {'key': 'observacoes', 'label': 'Observações', 'type': 'text'},
];

const _unhas = [
  {'key': 'alergia_acetona', 'label': 'Alergia a acetona ou produtos químicos', 'type': 'boolean'},
  {'key': 'fungos', 'label': 'Histórico de fungos/micose', 'type': 'boolean'},
  {'key': 'observacoes', 'label': 'Observações', 'type': 'text'},
];

const _estetica = [
  {'key': 'alergias', 'label': 'Alergias conhecidas', 'type': 'text'},
  {'key': 'medicamentos', 'label': 'Medicamentos em uso', 'type': 'text'},
  {'key': 'observacoes', 'label': 'Observações', 'type': 'text'},
];

const _cabelo = [
  {'key': 'alergias', 'label': 'Alergias a produtos capilares', 'type': 'text'},
  {'key': 'tratamentos_quimicos', 'label': 'Tratamentos químicos recentes', 'type': 'text'},
  {'key': 'observacoes', 'label': 'Observações', 'type': 'text'},
];

const Map<String, List<Map<String, String>>> anamnesisTemplates = {
  'lash': _lash,
  'micropig': _micropig,
  'unhas': _unhas,
  'estetica': _estetica,
  'cabelo': _cabelo,
};

List<AnamnesisField> getTemplateFields(String category, [Map<String, dynamic>? savedValues]) {
  final template = anamnesisTemplates[category] ?? [];
  return template.map((t) {
    final key = t['key']!;
    final type = t['type']!;
    dynamic defaultValue = type == 'boolean' ? false : '';
    return AnamnesisField(
      key: key,
      label: t['label']!,
      type: type,
      value: savedValues?[key] ?? defaultValue,
    );
  }).toList();
}
