import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
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
  Map<String, dynamic> _initialValues = {};
  bool _loading = true;
  bool _saving = false;
  int _customFieldCounter = 0;

  static const _labels = {
    'lash': 'Cílios / Lash',
    'micropig': 'Micropigmentação',
    'unhas': 'Unhas',
    'estetica': 'Estética',
    'cabelo': 'Cabelo',
  };

  bool get _isDirty {
    for (final f in _fields) {
      final initial = _initialValues[f.key];
      if (f.value != initial) return true;
    }
    if (_fields.length != _initialValues.length) return true;
    return false;
  }

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
      if (!mounted) return;
      final fields = getTemplateFields(widget.category, savedValues);
      setState(() {
        _fields = fields;
        _initialValues = {for (final f in fields) f.key: f.value};
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      final fields = getTemplateFields(widget.category);
      setState(() {
        _fields = fields;
        _initialValues = {for (final f in fields) f.key: f.value};
        _loading = false;
      });
    }
  }

  void _updateField(int index, dynamic value) {
    setState(() {
      _fields = [
        for (int i = 0; i < _fields.length; i++)
          if (i == index) _fields[i].copyWith(value: value) else _fields[i],
      ];
    });
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
    _customFieldCounter++;
    setState(() {
      _fields = [
        ..._fields,
        AnamnesisField(
          key: 'custom_${DateTime.now().millisecondsSinceEpoch}_$_customFieldCounter',
          label: 'Campo personalizado $_customFieldCounter',
          type: 'text',
          value: '',
        ),
      ];
    });
  }

  Future<bool> _onWillPop() async {
    if (!_isDirty) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Descartar alterações?'),
        content: const Text('Você tem alterações não salvas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continuar editando'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Descartar',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
            title: Text(
                'Anamnese - ${_labels[widget.category] ?? widget.category}')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (int i = 0; i < _fields.length; i++)
                    _buildField(i, _fields[i]),
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
      ),
    );
  }

  Widget _buildField(int index, AnamnesisField field) {
    if (field.type == 'boolean') {
      return SwitchListTile(
        title: Text(field.label),
        value: field.value == true,
        onChanged: (v) => _updateField(index, v),
      );
    }
    if (field.type == 'select' && field.options != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: DropdownButtonFormField<String>(
          decoration: InputDecoration(labelText: field.label),
          value: field.value is String ? field.value as String : null,
          items: field.options!
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: (v) => _updateField(index, v),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        decoration: InputDecoration(labelText: field.label),
        initialValue: field.value?.toString() ?? '',
        onChanged: (v) => _updateField(index, v),
        maxLines: field.key == 'observacoes' ? 3 : 1,
      ),
    );
  }
}
