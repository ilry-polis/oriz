import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/package_model.dart';
import '../providers/package_provider.dart';
import '../widgets/create_package_sheet.dart';

class PackagesManagementScreen extends ConsumerWidget {
  const PackagesManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(packageProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pacotes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Atualizar',
            onPressed: () => ref.read(packageProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo pacote'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _buildError(context, ref, e.toString()),
        data: (listState) {
          if (listState is PackageListError) {
            return _buildError(context, ref, listState.message);
          }
          if (listState is PackageListLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (listState is PackageListLoaded) {
            if (listState.items.isEmpty) {
              return _buildEmpty(context, ref);
            }
            return _buildList(context, ref, listState.items);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text('Erro ao carregar pacotes', style: AppTypography.bodySemibold),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              style:
                  AppTypography.caption.copyWith(color: AppColors.neutral600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: () => ref.read(packageProvider.notifier).refresh(),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: const Icon(
                Icons.card_giftcard_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Nenhum pacote criado', style: AppTypography.title),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Crie pacotes de sessoes para vender a clientes',
              style:
                  AppTypography.body.copyWith(color: AppColors.neutral600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: () => _showCreateSheet(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Criar primeiro pacote'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    List<PackageModel> packages,
  ) {
    // Group packages by combined service names label
    final grouped = <String, List<PackageModel>>{};
    for (final pkg in packages) {
      final key = pkg.serviceLabel;
      (grouped[key] ??= []).add(pkg);
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        for (final entry in grouped.entries) ...[
          Padding(
            padding: const EdgeInsets.only(
              bottom: AppSpacing.xs,
              top: AppSpacing.sm,
            ),
            child: Text(
              entry.key.toUpperCase(),
              style: AppTypography.micro.copyWith(
                color: AppColors.neutral400,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.neutral100,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.neutral200),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < entry.value.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      color: AppColors.neutral200,
                      height: 1,
                      indent: AppSpacing.md,
                    ),
                  _PackageRow(
                    package: entry.value[i],
                    onDelete: () =>
                        _confirmDelete(context, ref, entry.value[i]),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: 80), // FAB clearance
      ],
    );
  }

  Future<void> _showCreateSheet(BuildContext context, WidgetRef ref) async {
    HapticFeedback.lightImpact();
    final created = await CreatePackageSheet.show(context);
    if (created == true) {
      ref.read(packageProvider.notifier).refresh();
    }
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    PackageModel package,
  ) {
    HapticFeedback.mediumImpact();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Text('Excluir pacote', style: AppTypography.bodySemibold),
        content: Text(
          'Excluir "${package.name}"? Assinaturas ativas nao serao afetadas.',
          style: AppTypography.body.copyWith(color: AppColors.neutral600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: AppTypography.body
                  .copyWith(color: AppColors.neutral600),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(packageProvider.notifier).delete(package.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Pacote "${package.name}" excluido'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao excluir: $e'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: Text(
              'Excluir',
              style: AppTypography.body.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Package Row ──────────────────────────────────────────────────────────────

class _PackageRow extends StatelessWidget {
  final PackageModel package;
  final VoidCallback onDelete;

  const _PackageRow({required this.package, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onLongPress: () {
        HapticFeedback.mediumImpact();
        showModalBottomSheet<void>(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
          ),
          builder: (_) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.error),
                    title: Text(
                      'Excluir pacote',
                      style:
                          AppTypography.body.copyWith(color: AppColors.error),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      onDelete();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(package.name, style: AppTypography.bodySemibold),
                  const SizedBox(height: 2),
                  Text(
                    '${package.totalSessions} sessoes · ${package.validityLabel}',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.neutral600),
                  ),
                ],
              ),
            ),
            Text(
              package.formattedPrice,
              style: AppTypography.bodySemibold
                  .copyWith(color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
