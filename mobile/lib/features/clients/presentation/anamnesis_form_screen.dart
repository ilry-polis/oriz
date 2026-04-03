import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/anamnesis_templates.dart';
import '../data/client_repository.dart';
import '../domain/anamnesis_model.dart';

class AnamnesisFormScreen extends ConsumerStatefulWidget {
  final String clientId;
  final String category;

  const AnamnesisFormScreen({
    super.key,
    required this.clientId,
    required this.category,
  });

  @override
  ConsumerState<AnamnesisFormScreen> createState() =>
      _AnamnesisFormScreenState();
}

class _AnamnesisFormScreenState extends ConsumerState<AnamnesisFormScreen> {
  List<AnamnesisField> _fields = [];
  bool _loading = true;
  bool _saving = false;

  static const _labels = {
    'lash': 'Cílios / Lash',
    'micropig': 'Micropigmentação',
    'unhas': 'Unhas',
    'estetica': 'Estética',
    'cabelo': 'Cabelo',
  };

  @override
  void initState() {
    super.initState();
    _loadAnamnesis();
  }

  Future<void> _loadAnamnesis() async {
    try {
      final repo = ref.read(clientRepositoryProvider);
      final existing =
          await repo.getAnamnesis(widget.clientId, widget.category);
      final savedValues = existing?.fields ?? {};
      setState(() {
        _fields = getTemplateFields(widget.category, savedValues);
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _fields = getTemplateFields(widget.category);
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final repo = ref.read(clientRepositoryProvider);
      final fieldsMap = <String, dynamic>{};
      for (final f in _fields) {
        fieldsMap[f.key] = f.value;
      }
      await repo.upsertAnamnesis(widget.clientId, widget.category, fieldsMap);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _addCustomField() {
    setState(() {
      final index = _fields.length + 1;
      _fields.add(AnamnesisField(
        key: 'custom_$index',
        label: 'Campo personalizado $index',
        type: 'text',
        value: '',
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('Anamnese - ${_labels[widget.category] ?? widget.category}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ..._fields.map((field) {
                  if (field.type == 'boolean') {
                    return SwitchListTile(
                      title: Text(field.label),
                      value: field.value == true,
                      onChanged: (v) => setState(() => field.value = v),
                    );
                  }
                  if (field.type == 'select' && field.options != null) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(labelText: field.label),
                        value: field.value as String?,
                        items: field.options!
                            .map((o) =>
                                DropdownMenuItem(value: o, child: Text(o)))
                            .toList(),
                        onChanged: (v) => setState(() => field.value = v),
                      ),
                    );
                  }
                  // text
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextFormField(
                      decoration: InputDecoration(labelText: field.label),
                      initialValue: field.value?.toString() ?? '',
                      onChanged: (v) => field.value = v,
                      maxLines: field.key == 'observacoes' ? 3 : 1,
                    ),
                  );
                }),
                TextButton.icon(
                  onPressed: _addCustomField,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar campo'),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Salvar anamnese'),
                ),
              ],
            ),
    );
  }
}
