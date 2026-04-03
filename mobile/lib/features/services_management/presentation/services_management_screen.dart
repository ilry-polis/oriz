import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../data/service_mgmt_repository.dart';
import '../domain/service_model.dart';
import '../providers/service_mgmt_provider.dart';
import 'service_form_sheet.dart';
import 'widgets/service_card.dart';

class ServicesManagementScreen extends ConsumerWidget {
  const ServicesManagementScreen({super.key});

  Future<void> _toggleActive(
    BuildContext context,
    WidgetRef ref,
    ServiceModel service,
  ) async {
    try {
      final repo = ref.read(serviceMgmtRepositoryProvider);
      final updated = await repo.toggleActive(service.id, !service.isActive);
      ref.read(serviceMgmtProvider.notifier).refresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updated.isActive ? 'Serviço ativado' : 'Serviço desativado',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    ServiceModel service,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Text('Excluir serviço?', style: AppTypography.title),
        content: Text(
          'Tem certeza que deseja excluir "${service.name}"? Esta ação não pode ser desfeita.',
          style: AppTypography.body.copyWith(color: AppColors.neutral600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Voltar',
              style: AppTypography.body.copyWith(color: AppColors.neutral600),
            ),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.heavyImpact();
              Navigator.pop(ctx, true);
            },
            child: Text(
              'Excluir',
              style: AppTypography.body.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ref.read(serviceMgmtRepositoryProvider).deleteService(service.id);
      ref.read(serviceMgmtProvider.notifier).refresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Serviço excluído'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(serviceMgmtProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Serviços'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => ServiceFormSheet.show(context),
          ),
        ],
      ),
      body: switch (state) {
        ServiceMgmtLoading() =>
          const Center(child: CircularProgressIndicator()),
        ServiceMgmtError(:final message) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      ref.read(serviceMgmtProvider.notifier).refresh(),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ServiceMgmtLoaded(:final grouped, :final all) when all.isEmpty =>
          EmptyStateWidget(
            icon: Icons.auto_awesome_mosaic_outlined,
            title: 'Nenhum serviço cadastrado',
            subtitle: 'Adicione seu primeiro serviço para começar',
            ctaLabel: 'Adicionar serviço',
            onCta: () => ServiceFormSheet.show(context),
          ),
        ServiceMgmtLoaded(:final grouped) => RefreshIndicator(
            onRefresh: () => ref.read(serviceMgmtProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              children: grouped.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.sm,
                      ),
                      child: Text(
                        '${entry.key} (${entry.value.length})',
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.neutral600,
                        ),
                      ),
                    ),
                    ...entry.value.map(
                      (s) => ServiceCard(
                        service: s,
                        onTap: () => context.push('/services/${s.id}'),
                        onEdit: () => context.push('/services/${s.id}/edit'),
                        onToggleActive: () => _toggleActive(context, ref, s),
                        onDelete: () => _delete(context, ref, s),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
      },
    );
  }
}
