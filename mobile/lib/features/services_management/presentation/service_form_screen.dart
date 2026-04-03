import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/formatters/currency_formatter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
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
  bool _loadingData = true;

  bool get isEdit => widget.serviceId != null;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _bufferController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final repo = ref.read(serviceMgmtRepositoryProvider);

      // Load categories and service data in parallel
      final futures = <Future>[repo.listCategories()];
      if (isEdit) futures.add(repo.getService(widget.serviceId!));

      final results = await Future.wait(futures);

      final cats = results[0] as List<Map<String, dynamic>>;

      if (isEdit && results.length > 1) {
        final service = results[1] as dynamic;
        _nameController.text = service.name;
        _priceController.text = BrazilianCurrencyFormatter.formatCents(service.price);
        _durationController.text = service.durationMinutes.toString();
        _bufferController.text = service.bufferMinutes.toString();
        _selectedCategoryId = service.categoryId;
        _isActive = service.isActive;
      }

      if (mounted) {
        setState(() {
          _categories = cats;
          _loadingData = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingData = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Editar serviço' : 'Novo serviço'),
      ),
      body: _loadingData
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  // Categoria
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Categoria'),
                    value: _selectedCategoryId,
                    items: _categories
                        .map((c) => DropdownMenuItem<String>(
                              value: c['id'] as String,
                              child: Text(c['name'] as String),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCategoryId = v),
                    validator: (v) =>
                        v == null ? 'Selecione uma categoria' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ClearableTextField(
                    controller: _nameController,
                    labelText: 'Nome do serviço',
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
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
                      if (BrazilianCurrencyFormatter.parseCents(v) <= 0) {
                        return 'Valor inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ClearableTextField(
                    controller: _durationController,
                    labelText: 'Duração',
                    suffixText: 'min',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) =>
                        (v == null || int.tryParse(v) == null)
                            ? 'Obrigatório'
                            : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ClearableTextField(
                    controller: _bufferController,
                    labelText: 'Intervalo após atendimento',
                    suffixText: 'min',
                    helperText: 'Tempo de preparo antes do próximo cliente',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  if (isEdit) ...[
                    const SizedBox(height: AppSpacing.md),
                    SwitchListTile(
                      title: const Text('Serviço ativo'),
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.neutral200,
                        disabledForegroundColor: AppColors.neutral400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        textStyle: AppTypography.bodySemibold,
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(isEdit ? 'Salvar' : 'Criar serviço'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
