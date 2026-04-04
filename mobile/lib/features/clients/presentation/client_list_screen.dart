import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../data/client_repository.dart';
import '../providers/client_provider.dart';
import 'client_form_sheet.dart';
import 'widgets/client_list_item.dart';
import 'widgets/client_list_item_skeleton.dart';
import 'widgets/tag_chip.dart';

class ClientListScreen extends ConsumerStatefulWidget {
  const ClientListScreen({super.key});

  @override
  ConsumerState<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends ConsumerState<ClientListScreen> {
  final _searchController = TextEditingController();
  String? _activeTag;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleVip(
      BuildContext context, WidgetRef ref, dynamic client) async {
    final isVip = (client.tags as List).contains('vip');
    final newTags = isVip
        ? (client.tags as List<String>).where((t) => t != 'vip').toList()
        : [...client.tags as List<String>, 'vip'];
    try {
      final repo = ref.read(clientRepositoryProvider);
      await repo.updateTags(client.id as String, newTags);
      ref.read(clientListProvider.notifier).refresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isVip ? 'VIP removido' : 'Marcado como VIP'),
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

  Future<void> _anonymize(
      BuildContext context, WidgetRef ref, dynamic client) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Text('Excluir cliente?', style: AppTypography.title),
        content: Text(
          'Os dados de "${client.name}" serão anonimizados permanentemente.',
          style: AppTypography.body.copyWith(color: AppColors.neutral600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Voltar',
                style:
                    AppTypography.body.copyWith(color: AppColors.neutral600)),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.heavyImpact();
              Navigator.pop(ctx, true);
            },
            child: Text('Excluir',
                style: AppTypography.body.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ref
          .read(clientRepositoryProvider)
          .anonymize(client.id as String);
      ref.read(clientListProvider.notifier).refresh();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  void _onTagTap(String? tag) {
    setState(() {
      _activeTag = _activeTag == tag ? null : tag;
      _searchController.clear();
    });
    ref.read(clientListProvider.notifier).filterByTag(_activeTag);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(clientListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => ClientFormSheet.show(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchController,
              builder: (context, value, _) => TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar cliente...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.neutral400),
                  suffixIcon: value.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18, color: AppColors.neutral400),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(clientListProvider.notifier).search('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (v) => ref.read(clientListProvider.notifier).search(v),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                TagChip(
                  label: 'Todos',
                  selected: _activeTag == null,
                  onTap: () => _onTagTap(null),
                ),
                const SizedBox(width: 8),
                for (final tag in ['VIP', 'Novo', 'Inativo'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: TagChip(
                      label: tag,
                      selected: _activeTag == tag.toLowerCase(),
                      onTap: () => _onTagTap(tag.toLowerCase()),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: switch (state) {
              ClientListLoading() => ListView.builder(
                  itemCount: 6,
                  itemBuilder: (_, __) => const ClientListItemSkeleton(),
                ),
              ClientListError(:final message) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(message),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () =>
                            ref.read(clientListProvider.notifier).refresh(),
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              ClientListLoaded(:final clients) when clients.isEmpty =>
                EmptyStateWidget(
                  icon: Icons.people_outline,
                  title: 'Nenhum cliente',
                  subtitle: 'Adicione seu primeiro cliente',
                  ctaLabel: 'Adicionar cliente',
                  onCta: () => ClientFormSheet.show(context),
                ),
              ClientListLoaded(:final clients, :final hasMore) =>
                NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollEndNotification &&
                        notification.metrics.extentAfter < 200 &&
                        hasMore) {
                      ref.read(clientListProvider.notifier).loadMore();
                    }
                    return false;
                  },
                  child: RefreshIndicator(
                    onRefresh: () =>
                        ref.read(clientListProvider.notifier).refresh(),
                    child: ListView.builder(
                      itemCount: clients.length,
                      itemBuilder: (_, i) {
                        final c = clients[i];
                        return ClientListItem(
                          client: c,
                          onTap: () => context.push('/clients/${c.id}'),
                          onEdit: () => context.push('/clients/${c.id}/edit'),
                          onToggleVip: () => _toggleVip(context, ref, c),
                          onDelete: () => _anonymize(context, ref, c),
                        );
                      },
                    ),
                  ),
                ),
            },
          ),
        ],
      ),
    );
  }
}
