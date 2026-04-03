import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/formatters/currency_formatter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/clearable_text_field.dart';
import '../data/service_mgmt_repository.dart';
import '../providers/service_mgmt_provider.dart';

class ServiceFormScreen extends ConsumerStatefulWidget {
  final String? serviceId;
  const ServiceFormScreen({super.key, this.serviceId});

  @override
  ConsumerState<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends ConsumerState<ServiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _bufferController = TextEditingController(text: '0');
  String? _selectedCategoryId;
  bool _isActive = true;
  bool _saving = false;
  List<Map<String, dynamic>> _categories = [];
  bool _loadingCategories = true;

  bool get isEdit => widget.serviceId != null;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _bufferController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final repo = ref.read(serviceMgmtRepositoryProvider);
      final cats = await repo.listCategories();
      if (mounted) {
        setState(() {
          _categories = cats;
          _loadingCategories = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma categoria')),
      );
      return;
    }
    setState(() => _saving = true);

    try {
      final repo = ref.read(serviceMgmtRepositoryProvider);
      final data = {
        'category_id': _selectedCategoryId,
        'name': _nameController.text.trim(),
        'price': BrazilianCurrencyFormatter.parseCents(_priceController.text),
        'duration_minutes': int.parse(_durationController.text),
        'buffer_minutes': int.tryParse(_bufferController.text) ?? 0,
        'is_active': _isActive,
      };

      if (isEdit) {
        await repo.updateService(widget.serviceId!, data);
      } else {
        await repo.createService(data);
      }

      ref.read(serviceMgmtProvider.notifier).refresh();
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir serviço'),
        content: const Text('Tem certeza? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ref.read(serviceMgmtRepositoryProvider).deleteService(widget.serviceId!);
      ref.read(serviceMgmtProvider.notifier).refresh();
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Editar serviço' : 'Novo serviço'),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Categoria
            _loadingCategories
                ? const LinearProgressIndicator()
                : DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Categoria'),
                    value: _selectedCategoryId,
                    items: _categories
                        .map((c) => DropdownMenuItem<String>(
                              value: c['id'] as String,
                              child: Text(c['name'] as String),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCategoryId = v),
                    validator: (v) => v == null ? 'Selecione uma categoria' : null,
                  ),
            const SizedBox(height: 16),
            ClearableTextField(
              controller: _nameController,
              labelText: 'Nome do serviço',
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 16),
            ClearableTextField(
              controller: _priceController,
              labelText: 'Preço',
              prefixText: 'R\$ ',
              hintText: '0,00',
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                BrazilianCurrencyFormatter(),
              ],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Obrigatório';
                if (BrazilianCurrencyFormatter.parseCents(v) <= 0) return 'Valor inválido';
                return null;
              },
            ),
            const SizedBox(height: 16),
            ClearableTextField(
              controller: _durationController,
              labelText: 'Duração',
              suffixText: 'min',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) => (v == null || int.tryParse(v) == null) ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 16),
            ClearableTextField(
              controller: _bufferController,
              labelText: 'Intervalo após atendimento',
              suffixText: 'min',
              helperText: 'Tempo de preparo antes do próximo cliente',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),
            if (isEdit)
              SwitchListTile(
                title: const Text('Serviço ativo'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(isEdit ? 'Salvar' : 'Criar serviço'),
            ),
          ],
        ),
      ),
    );
  }
}
