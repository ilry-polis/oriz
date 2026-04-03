import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/clearable_text_field.dart';
import '../data/team_repository.dart';
import '../providers/team_provider.dart';

/// Bottom sheet for inviting a new professional — follows app pattern.
class ProfessionalFormSheet extends ConsumerStatefulWidget {
  const ProfessionalFormSheet({super.key});

  static Future<void> show(BuildContext context) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => const ProfessionalFormSheet(),
    );
  }

  @override
  ConsumerState<ProfessionalFormSheet> createState() =>
      _ProfessionalFormSheetState();
}

class _ProfessionalFormSheetState
    extends ConsumerState<ProfessionalFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _commissionController = TextEditingController(text: '30');
  String _commissionType = 'percentage';
  String _cardFeePolicy = 'studio';
  bool _saving = false;

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
        'commission_type': _commissionType,
        'commission_value': double.parse(_commissionController.text),
        'card_fee_policy': _cardFeePolicy,
      });

      ref.read(teamProvider.notifier).refresh();

      final data = result['data'] as Map<String, dynamic>?;
      final whatsappLink = data?['whatsapp_link'] as String?;
      final inviteToken = data?['invite_token'] as String?;

      if (mounted) {
        Navigator.pop(context);
        _showSuccessSheet(context, whatsappLink, inviteToken);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSuccessSheet(
      BuildContext context, String? whatsappLink, String? inviteToken) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.neutral300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Icon(Icons.check_circle_outline,
                  size: 56, color: AppColors.success),
              const SizedBox(height: AppSpacing.md),
              Text('Profissional cadastrada!', style: AppTypography.title),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Envie o convite via WhatsApp para ela criar a conta e ativar o acesso.',
                style: AppTypography.body.copyWith(color: AppColors.neutral600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              // WhatsApp button
              if (whatsappLink != null)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      HapticFeedback.mediumImpact();
                      final uri = Uri.parse(whatsappLink);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.send_rounded, size: 20),
                    label: const Text('Enviar via WhatsApp'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      textStyle: AppTypography.bodySemibold,
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
              // Copy link fallback
              if (inviteToken != null)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final link = 'oriz://invite/$inviteToken';
                      Clipboard.setData(ClipboardData(text: link));
                      HapticFeedback.selectionClick();
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: const Text('Link copiado!'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 20),
                    label: const Text('Copiar link'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Fechar',
                  style:
                      AppTypography.body.copyWith(color: AppColors.neutral600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(top: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.neutral300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.accentSoft,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Icon(Icons.person_add_rounded,
                            color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text('Convidar profissional',
                          style: AppTypography.title),
                    ],
                  ),
                ),

                const Divider(color: AppColors.neutral200, height: 1),

                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClearableTextField(
                        controller: _nameController,
                        labelText: 'Nome da profissional',
                        autofocus: true,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Obrigatório'
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Comissão: tipo + valor lado a lado
                      Row(
                        children: [
                          // Tipo
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                  labelText: 'Tipo comissão'),
                              value: _commissionType,
                              items: const [
                                DropdownMenuItem(
                                    value: 'percentage',
                                    child: Text('Percentual')),
                                DropdownMenuItem(
                                    value: 'fixed', child: Text('Fixo (R\$)')),
                              ],
                              onChanged: (v) =>
                                  setState(() => _commissionType = v!),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          // Valor
                          Expanded(
                            child: ClearableTextField(
                              controller: _commissionController,
                              labelText: 'Valor',
                              suffixText:
                                  _commissionType == 'percentage' ? '%' : 'R\$',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[\d.]')),
                              ],
                              validator: (v) =>
                                  (v == null || double.tryParse(v) == null)
                                      ? 'Inválido'
                                      : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Taxa do cartão
                      Text('Taxa do cartão',
                          style: AppTypography.caption
                              .copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        children: [
                          _policyChip('studio', 'Estúdio absorve'),
                          _policyChip('professional', 'Profissional absorve'),
                          _policyChip('split', 'Dividir'),
                        ],
                      ),
                    ],
                  ),
                ),

                // Confirm button
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg,
                  ),
                  child: SizedBox(
                    width: double.infinity,
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
                          : const Text('Cadastrar e enviar convite'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _policyChip(String value, String label) {
    final selected = _cardFeePolicy == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _cardFeePolicy = value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.neutral100,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.neutral200,
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: selected ? Colors.white : AppColors.neutral900,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

/// Legacy screen kept for router compatibility — redirects to bottom sheet.
class ProfessionalFormScreen extends StatelessWidget {
  const ProfessionalFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Open bottom sheet and pop this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.pop();
      ProfessionalFormSheet.show(context);
    });
    return const Scaffold();
  }
}
