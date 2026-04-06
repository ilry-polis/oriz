import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/formatters/currency_formatter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/clearable_text_field.dart';
import '../../services_management/data/service_mgmt_repository.dart';
import '../../services_management/domain/service_model.dart';
import '../providers/package_provider.dart';

/// Bottom sheet for creating a new session package.
/// If [preselectedServiceIds] and [preselectedServiceNames] are provided,
/// the service picker is hidden and the services are pre-filled.
class CreatePackageSheet extends ConsumerStatefulWidget {
  final List<String>? preselectedServiceIds;
  final List<String>? preselectedServiceNames;

  const CreatePackageSheet({
    super.key,
    this.preselectedServiceIds,
    this.preselectedServiceNames,
  });

  static Future<bool?> show(
    BuildContext context, {
    List<String>? serviceIds,
    List<String>? serviceNames,
    // Legacy single-service convenience
    String? serviceId,
    String? serviceName,
  }) {
    HapticFeedback.lightImpact();
    final ids = serviceIds ?? (serviceId != null ? [serviceId] : null);
    final names = serviceNames ?? (serviceName != null ? [serviceName] : null);
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => CreatePackageSheet(
        preselectedServiceIds: ids,
        preselectedServiceNames: names,
      ),
    );
  }

  @override
  ConsumerState<CreatePackageSheet> createState() => _CreatePackageSheetState();
}

class _CreatePackageSheetState extends ConsumerState<CreatePackageSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _sessionsController = TextEditingController();
  final _validityController = TextEditingController();

  final Set<String> _selectedServiceIds = {};
  bool _saving = false;
  List<ServiceModel> _services = [];
  bool _loadingServices = true;

  bool get _hasPreselectedServices =>
      widget.preselectedServiceIds != null &&
      widget.preselectedServiceIds!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_hasPreselectedServices) {
      _selectedServiceIds.addAll(widget.preselectedServiceIds!);
      setState(() => _loadingServices = false);
    } else {
      _loadServices();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _sessionsController.dispose();
    _validityController.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    try {
      final repo = ref.read(serviceMgmtRepositoryProvider);
      final services = await repo.listServices();
      if (mounted) {
        setState(() {
          _services = services.where((s) => s.isActive).toList();
          _loadingServices = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingServices = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedServiceIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione ao menos um serviço')),
      );
      return;
    }
    setState(() => _saving = true);

    try {
      await ref.read(packageProvider.notifier).create(
            serviceIds: _selectedServiceIds.toList(),
            name: _nameController.text.trim(),
            totalSessions: int.parse(_sessionsController.text.trim()),
            price: BrazilianCurrencyFormatter.parseCents(_priceController.text),
            validityDays: int.tryParse(_validityController.text.trim()) ?? 30,
          );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Pacote criado'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.neutral300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('Novo Pacote', style: AppTypography.title),
                  const SizedBox(height: AppSpacing.md),

                  // Service picker (hidden if preselected)
                  if (!_hasPreselectedServices) ...[
                    Text('Serviços',
                        style: AppTypography.caption
                            .copyWith(color: AppColors.neutral600)),
                    const SizedBox(height: AppSpacing.xs),
                    if (_loadingServices)
                      const Center(child: CircularProgressIndicator())
                    else
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: 4,
                        children: _services.map((s) {
                          final selected = _selectedServiceIds.contains(s.id);
                          return FilterChip(
                            label: Text(s.name),
                            selected: selected,
                            onSelected: (val) {
                              setState(() {
                                if (val) {
                                  _selectedServiceIds.add(s.id);
                                } else {
                                  _selectedServiceIds.remove(s.id);
                                }
                              });
                            },
                            selectedColor: AppColors.accentSoft,
                            checkmarkColor: AppColors.primary,
                            labelStyle: AppTypography.caption.copyWith(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.neutral600,
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: AppSpacing.md),
                  ] else ...[
                    // Show preselected services as read-only chips
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: 4,
                      children: [
                        const Icon(Icons.category_outlined,
                            size: 16, color: AppColors.neutral400),
                        const SizedBox(width: AppSpacing.xs),
                        for (final name
                            in widget.preselectedServiceNames ?? <String>[])
                          Chip(
                            label: Text(name, style: AppTypography.caption),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Package name
                  ClearableTextField(
                    controller: _nameController,
                    labelText: 'Nome do pacote',
                    hintText: 'Ex: Pacote 10 sessões Lash',
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Sessions count
                  TextFormField(
                    controller: _sessionsController,
                    decoration: InputDecoration(
                      labelText: 'Total de sessões',
                      hintText: 'Ex: 10',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Informe o total de sessões';
                      final n = int.tryParse(v);
                      if (n == null || n < 1) return 'Mínimo 1 sessão';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Price
                  TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(
                      labelText: 'Preço total',
                      prefixText: 'R\$ ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [BrazilianCurrencyFormatter()],
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Informe o preço';
                      final cents = BrazilianCurrencyFormatter.parseCents(v);
                      if (cents <= 0) return 'Preço deve ser maior que zero';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Validity days
                  TextFormField(
                    controller: _validityController,
                    decoration: InputDecoration(
                      labelText: 'Validade (dias)',
                      hintText: 'Ex: 30',
                      suffixText: 'dias',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Informe a validade';
                      final n = int.tryParse(v);
                      if (n == null || n < 1) return 'Mínimo 1 dia';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
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
                          : const Text('Criar pacote',
                              style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
