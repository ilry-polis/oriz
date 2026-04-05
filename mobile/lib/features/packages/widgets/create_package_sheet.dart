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
/// If [preselectedServiceId] and [preselectedServiceName] are provided,
/// the service picker is hidden and the service is pre-filled.
class CreatePackageSheet extends ConsumerStatefulWidget {
  final String? preselectedServiceId;
  final String? preselectedServiceName;

  const CreatePackageSheet({
    super.key,
    this.preselectedServiceId,
    this.preselectedServiceName,
  });

  static Future<bool?> show(
    BuildContext context, {
    String? serviceId,
    String? serviceName,
  }) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => CreatePackageSheet(
        preselectedServiceId: serviceId,
        preselectedServiceName: serviceName,
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
  final _validityController = TextEditingController(text: '30');

  String? _selectedServiceId;
  bool _saving = false;
  List<ServiceModel> _services = [];
  bool _loadingServices = true;

  bool get _hasPreselectedService => widget.preselectedServiceId != null;

  @override
  void initState() {
    super.initState();
    _selectedServiceId = widget.preselectedServiceId;
    if (!_hasPreselectedService) {
      _loadServices();
    } else {
      setState(() => _loadingServices = false);
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
    if (_selectedServiceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um serviço')),
      );
      return;
    }
    setState(() => _saving = true);

    try {
      await ref.read(packageProvider.notifier).create(
            serviceId: _selectedServiceId!,
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
                  if (!_hasPreselectedService) ...[
                    Text('Serviço',
                        style: AppTypography.caption
                            .copyWith(color: AppColors.neutral600)),
                    const SizedBox(height: AppSpacing.xs),
                    _loadingServices
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<String>(
                            value: _selectedServiceId,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 14),
                              hintText: 'Selecionar serviço',
                            ),
                            items: _services
                                .map((s) => DropdownMenuItem(
                                      value: s.id,
                                      child: Text(s.name,
                                          style: AppTypography.body),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedServiceId = val;
                              });
                            },
                            validator: (v) =>
                                v == null ? 'Selecione um serviço' : null,
                          ),
                    const SizedBox(height: AppSpacing.md),
                  ] else ...[
                    // Show preselected service as read-only chip
                    Row(
                      children: [
                        const Icon(Icons.category_outlined,
                            size: 16, color: AppColors.neutral400),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          widget.preselectedServiceName ?? 'Serviço selecionado',
                          style: AppTypography.caption
                              .copyWith(color: AppColors.neutral600),
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
