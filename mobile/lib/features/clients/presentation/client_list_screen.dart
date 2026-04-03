import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../providers/client_provider.dart';
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
            onPressed: () => context.push('/clients/new'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar cliente...',
                prefixIcon: const Icon(Icons.search, color: AppColors.neutral400),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (v) => ref.read(clientListProvider.notifier).search(v),
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
                  onCta: () => context.push('/clients/new'),
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
                      itemBuilder: (_, i) => ClientListItem(
                        client: clients[i],
                        onTap: () => context.push('/clients/${clients[i].id}'),
                      ),
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
