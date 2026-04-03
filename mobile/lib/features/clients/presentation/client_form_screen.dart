import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/formatters/phone_formatter.dart';
import '../../../core/theme/app_colors.dart';
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
  bool _marketingConsent = false;
  bool _saving = false;

  bool get isEdit => widget.clientId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
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
      if (_emailController.text.isNotEmpty) data['email'] = _emailController.text.trim();
      if (!isEdit) data['marketing_consent'] = _marketingConsent;

      if (isEdit) {
        await repo.updateClient(widget.clientId!, data);
      } else {
        await repo.createClient(data);
      }

      ref.read(clientListProvider.notifier).refresh();
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Telefone',
                hintText: '(11) 99999-9999',
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
                BrazilianPhoneFormatter(),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'E-mail'),
              keyboardType: TextInputType.emailAddress,
            ),
            if (!isEdit) ...[
              const SizedBox(height: 24),
              CheckboxListTile(
                value: _marketingConsent,
                onChanged: (v) => setState(() => _marketingConsent = v ?? false),
                title: const Text(
                  'Aceito receber mensagens de marketing via WhatsApp',
                  style: TextStyle(fontSize: 14),
                ),
                subtitle: const Text(
                  'Você pode revogar este consentimento a qualquer momento',
                  style: TextStyle(fontSize: 11, color: AppColors.neutral400),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(isEdit ? 'Salvar' : 'Cadastrar cliente'),
            ),
          ],
        ),
      ),
    );
  }
}
