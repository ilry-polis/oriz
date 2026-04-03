import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../data/team_repository.dart';
import '../providers/team_provider.dart';

class ProfessionalFormScreen extends ConsumerStatefulWidget {
  const ProfessionalFormScreen({super.key});

  @override
  ConsumerState<ProfessionalFormScreen> createState() =>
      _ProfessionalFormScreenState();
}

class _ProfessionalFormScreenState
    extends ConsumerState<ProfessionalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _commissionController = TextEditingController(text: '30');
  String _cardFeePolicy = 'studio';
  bool _saving = false;
  String? _inviteLink;

  @override
  void dispose() {
    _nameController.dispose();
    _commissionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final repo = ref.read(teamRepositoryProvider);
      final result = await repo.createInvite({
        'name': _nameController.text.trim(),
        'commission_type': 'percentage',
        'commission_value': double.parse(_commissionController.text),
        'card_fee_policy': _cardFeePolicy,
      });

      ref.read(teamProvider.notifier).refresh();

      final link = result['data']?['invite_link'] as String?;
      setState(() => _inviteLink = link);
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
    if (_inviteLink != null) {
      return _InviteSuccessView(
        link: _inviteLink!,
        onDone: () => context.pop(),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Convidar profissional')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome da profissional'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _commissionController,
              decoration: const InputDecoration(
                  labelText: 'Comissão (%)', suffixText: '%'),
              keyboardType: TextInputType.number,
              validator: (v) =>
                  (v == null || double.tryParse(v) == null) ? 'Inválido' : null,
            ),
            const SizedBox(height: 16),
            const Text('Taxa do cartão',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...['studio', 'professional', 'split'].map((policy) {
              final labels = {
                'studio': 'Estúdio absorve',
                'professional': 'Profissional absorve',
                'split': 'Dividir',
              };
              return RadioListTile<String>(
                title: Text(labels[policy]!),
                value: policy,
                groupValue: _cardFeePolicy,
                onChanged: (v) => setState(() => _cardFeePolicy = v!),
              );
            }),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Gerar convite'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteSuccessView extends StatelessWidget {
  final String link;
  final VoidCallback onDone;

  const _InviteSuccessView({required this.link, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Convite criado')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline,
                size: 64, color: AppColors.success),
            const SizedBox(height: 24),
            const Text(
              'Convite gerado com sucesso!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Compartilhe o link abaixo com a profissional.',
              style: TextStyle(color: AppColors.neutral600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(link,
                  style: const TextStyle(fontSize: 13),
                  textAlign: TextAlign.center),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        Clipboard.setData(ClipboardData(text: link)).then((_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link copiado!')),
                      );
                    }),
                    icon: const Icon(Icons.copy),
                    label: const Text('Copiar link'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            TextButton(onPressed: onDone, child: const Text('Voltar')),
          ],
        ),
      ),
    );
  }
}
