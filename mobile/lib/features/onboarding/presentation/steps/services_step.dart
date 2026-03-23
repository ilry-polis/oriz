import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/onboarding_repository.dart';
import '../../data/service_templates.dart';
import '../../providers/onboarding_provider.dart';
import '../widgets/service_template_card.dart';

class _EditableService {
  String categoryId;
  String name;
  int durationMinutes;
  int price;

  _EditableService({
    required this.categoryId,
    required this.name,
    required this.durationMinutes,
    required this.price,
  });
}

class ServicesStep extends ConsumerStatefulWidget {
  const ServicesStep({super.key});

  @override
  ConsumerState<ServicesStep> createState() => _ServicesStepState();
}

class _ServicesStepState extends ConsumerState<ServicesStep> {
  final Set<String> _selectedCategories = {};
  final List<_EditableService> _services = [];
  Map<String, String> _categoryIdMap = {};
  bool _categoriesLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final repo = ref.read(onboardingRepositoryProvider);
      final categories = await repo.getServiceCategories();
      if (mounted) {
        setState(() {
          _categoryIdMap = {for (final c in categories) c.name: c.id};
          _categoriesLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _categoriesLoaded = true);
    }
  }

  void _toggleCategory(String category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
        _services.removeWhere((s) => s.categoryId == category);
      } else {
        _selectedCategories.add(category);
        final templates = templatesForCategory(category);
        for (final t in templates) {
          _services.add(_EditableService(
            categoryId: _categoryIdMap[t.category] ?? category,
            name: t.name,
            durationMinutes: t.durationMinutes,
            price: t.price,
          ));
        }
      }
    });
  }

  void _addCustomService() {
    setState(() {
      _services.add(_EditableService(
        categoryId: _categoryIdMap['Outro'] ?? 'custom',
        name: '',
        durationMinutes: 30,
        price: 0,
      ));
    });
  }

  void _removeService(int index) {
    setState(() => _services.removeAt(index));
  }

  void _updateService(int index, String name, int duration, int price) {
    _services[index]
      ..name = name
      ..durationMinutes = duration
      ..price = price;
  }

  Future<void> _submit() async {
    final validServices = _services.where((s) => s.name.trim().isNotEmpty).toList();
    if (validServices.isEmpty) {
      await _skip();
      return;
    }

    final notifier = ref.read(onboardingNotifierProvider.notifier);
    await notifier.addServices(
      validServices
          .map((s) => ServiceInput(
                categoryId: s.categoryId,
                name: s.name,
                durationMinutes: s.durationMinutes,
                price: s.price,
              ))
          .toList(),
    );
  }

  Future<void> _skip() async {
    await ref.read(onboardingNotifierProvider.notifier).skipServices();
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingNotifierProvider);
    final isSaving = onboardingState is OnboardingStep && onboardingState.isSaving;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.lg),
          Text('Servicos', style: AppTypography.title, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xs),
          Text('Passo 2 de 3', style: AppTypography.caption, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xl),

          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: categoryNames.map((cat) {
              final selected = _selectedCategories.contains(cat);
              return FilterChip(
                label: Text(cat),
                selected: selected,
                onSelected: isSaving ? null : (_) => _toggleCategory(cat),
                selectedColor: AppColors.accentSoft,
                checkmarkColor: AppColors.primary,
                labelStyle: AppTypography.caption.copyWith(
                  color: selected ? AppColors.primary : AppColors.neutral600,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),

          ...List.generate(_services.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ServiceTemplateCard(
                name: _services[i].name,
                durationMinutes: _services[i].durationMinutes,
                price: _services[i].price,
                onRemove: () => _removeService(i),
                onChanged: (name, dur, price) => _updateService(i, name, dur, price),
              ),
            );
          }),

          TextButton.icon(
            onPressed: isSaving ? null : _addCustomService,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('+ Servico personalizado'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              minimumSize: const Size(44, 44),
            ),
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
          const SizedBox(height: AppSpacing.sm),

          Center(
            child: TextButton(
              onPressed: isSaving ? null : _skip,
              style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
              child: Text(
                'Pular por agora',
                style: AppTypography.caption.copyWith(color: AppColors.neutral600),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
