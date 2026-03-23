import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/phone_formatter.dart';
import '../../../auth/presentation/widgets/auth_text_field.dart';
import '../../providers/onboarding_provider.dart';

String _slugify(String input) {
  return input
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
      .replaceAll(RegExp(r'\s+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}

class StudioDataStep extends ConsumerStatefulWidget {
  const StudioDataStep({super.key});

  @override
  ConsumerState<StudioDataStep> createState() => _StudioDataStepState();
}

class _StudioDataStepState extends ConsumerState<StudioDataStep> {
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  String _timezone = 'America/Sao_Paulo';
  bool _slugManuallyEdited = false;

  String? _nameError;
  String? _slugError;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    if (!_slugManuallyEdited) {
      _slugController.text = _slugify(_nameController.text);
    }
  }

  bool _validate() {
    String? nameErr;
    String? slugErr;

    if (_nameController.text.trim().isEmpty) {
      nameErr = 'Nome e obrigatorio';
    }

    final slug = _slugController.text.trim();
    if (!RegExp(r'^[a-z0-9-]{3,50}$').hasMatch(slug)) {
      slugErr = 'URL deve ter 3-50 caracteres (letras, numeros e hifens)';
    }

    setState(() {
      _nameError = nameErr;
      _slugError = slugErr;
    });

    return nameErr == null && slugErr == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;

    await ref.read(onboardingNotifierProvider.notifier).createStudio(
          name: _nameController.text.trim(),
          slug: _slugController.text.trim(),
          phone: stripPhoneMask(_phoneController.text).isEmpty
              ? null
              : '+55${stripPhoneMask(_phoneController.text)}',
          address: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
          timezone: _timezone,
        );
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingNotifierProvider);
    final isSaving = onboardingState is OnboardingStep && onboardingState.isSaving;

    ref.listen(onboardingNotifierProvider, (prev, next) {
      if (next is OnboardingError && next.code == 'SLUG_TAKEN') {
        setState(() {
          _slugError = 'Esta URL ja esta em uso';
        });
      }
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Dados do Estudio',
            style: AppTypography.title,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Passo 1 de 3',
            style: AppTypography.caption,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),

          AuthTextField(
            label: 'Nome do estudio',
            controller: _nameController,
            errorText: _nameError,
            textInputAction: TextInputAction.next,
            enabled: !isSaving,
          ),
          const SizedBox(height: AppSpacing.md),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('URL publica', style: AppTypography.caption),
              const SizedBox(height: AppSpacing.xs),
              SizedBox(
                height: 48,
                key: const Key('slug_field'),
                child: Row(
                  children: [
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      decoration: const BoxDecoration(
                        color: AppColors.neutral200,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(AppRadius.md),
                          bottomLeft: Radius.circular(AppRadius.md),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text('oriz.app/', style: AppTypography.caption),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _slugController,
                        enabled: !isSaving,
                        style: AppTypography.body,
                        onChanged: (_) => _slugManuallyEdited = true,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.neutral100,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          border: OutlineInputBorder(
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(AppRadius.md),
                              bottomRight: Radius.circular(AppRadius.md),
                            ),
                            borderSide: BorderSide(
                              color: _slugError != null
                                  ? AppColors.error
                                  : AppColors.neutral200,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(AppRadius.md),
                              bottomRight: Radius.circular(AppRadius.md),
                            ),
                            borderSide: BorderSide(
                              color: _slugError != null
                                  ? AppColors.error
                                  : AppColors.neutral200,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(AppRadius.md),
                              bottomRight: Radius.circular(AppRadius.md),
                            ),
                            borderSide: BorderSide(
                              color: _slugError != null
                                  ? AppColors.error
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_slugError != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _slugError!,
                  style: AppTypography.caption.copyWith(color: AppColors.error),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          AuthTextField(
            label: 'Telefone',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            enabled: !isSaving,
            inputFormatters: [BrazilPhoneFormatter()],
          ),
          const SizedBox(height: AppSpacing.md),

          AuthTextField(
            label: 'Endereco',
            controller: _addressController,
            textInputAction: TextInputAction.next,
            enabled: !isSaving,
          ),
          const SizedBox(height: AppSpacing.md),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Fuso horario', style: AppTypography.caption),
              const SizedBox(height: AppSpacing.xs),
              DropdownButtonFormField<String>(
                value: _timezone,
                isExpanded: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.neutral100,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(color: AppColors.neutral200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(color: AppColors.neutral200),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'America/Sao_Paulo', child: Text('Sao Paulo / Brasilia (GMT-3)')),
                  DropdownMenuItem(value: 'America/Recife', child: Text('Recife / Nordeste (GMT-3)')),
                  DropdownMenuItem(value: 'America/Fortaleza', child: Text('Fortaleza (GMT-3)')),
                  DropdownMenuItem(value: 'America/Belem', child: Text('Belem (GMT-3)')),
                  DropdownMenuItem(value: 'America/Manaus', child: Text('Manaus (GMT-4)')),
                  DropdownMenuItem(value: 'America/Cuiaba', child: Text('Cuiaba (GMT-4)')),
                ],
                onChanged: isSaving
                    ? null
                    : (value) {
                        if (value != null) setState(() => _timezone = value);
                      },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: isSaving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primary.withAlpha(102),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accent,
                      ),
                    )
                  : Text('Proximo',
                      style: AppTypography.bodySemibold.copyWith(color: Colors.white)),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
