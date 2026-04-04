import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/formatters/phone_formatter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/clearable_text_field.dart';
import '../data/client_repository.dart';
import '../providers/client_provider.dart';

class ClientFormScreen extends ConsumerStatefulWidget {
  final String? clientId;
  const ClientFormScreen({super.key, this.clientId});

  @override
  ConsumerState<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends ConsumerState<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _birthDateController = TextEditingController();
  DateTime? _birthDate;
  bool _saving = false;
  bool _loadingData = true;

  bool get isEdit => widget.clientId != null;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!isEdit) {
      setState(() => _loadingData = false);
      return;
    }
    try {
      final repo = ref.read(clientRepositoryProvider);
      final client = await repo.getClientById(widget.clientId!);
      _nameController.text = client.name;
      if (client.phone != null) {
        final digits = client.phone!.replaceAll(RegExp(r'\D'), '');
        final local =
            digits.startsWith('55') ? digits.substring(2) : digits;
        _phoneController.text = BrazilianPhoneFormatter.format(local);
      }
      if (client.email != null) _emailController.text = client.email!;
      if (client.birthDate != null) {
        _birthDate = DateTime.tryParse(client.birthDate!);
        if (_birthDate != null) {
          _birthDateController.text =
              '${_birthDate!.day.toString().padLeft(2, '0')}/${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.year}';
        }
      }
      if (mounted) setState(() => _loadingData = false);
    } catch (_) {
      if (mounted) setState(() => _loadingData = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final repo = ref.read(clientRepositoryProvider);
      final data = <String, dynamic>{
        'name': _nameController.text.trim(),
      };
      if (_phoneController.text.isNotEmpty) {
        data['phone'] = phoneToE164(_phoneController.text);
      }
      if (_emailController.text.isNotEmpty) {
        data['email'] = _emailController.text.trim();
      }
      if (_birthDate != null) {
        data['birth_date'] =
            '${_birthDate!.year}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}';
      }

      await repo.updateClient(widget.clientId!, data);

      ref.read(clientListProvider.notifier).refresh();
      ref.invalidate(clientDetailProvider(widget.clientId!));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Editar cliente' : 'Novo cliente')),
      body: _loadingData
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  ClearableTextField(
                    controller: _nameController,
                    labelText: 'Nome',
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ClearableTextField(
                    controller: _phoneController,
                    labelText: 'Telefone',
                    hintText: '(11) 99999-9999',
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                      BrazilianPhoneFormatter(),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ClearableTextField(
                    controller: _emailController,
                    labelText: 'E-mail',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _birthDate ?? DateTime(1990),
                        firstDate: DateTime(1920),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          _birthDate = picked;
                          _birthDateController.text =
                              '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                        });
                      }
                    },
                    child: AbsorbPointer(
                      child: ClearableTextField(
                        controller: _birthDateController,
                        labelText: 'Aniversário',
                        hintText: 'dd/mm/aaaa',
                      ),
                    ),
                  ),
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
                          : const Text('Salvar'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
