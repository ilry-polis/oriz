import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../providers/service_mgmt_provider.dart';
import 'widgets/service_card.dart';

class ServicesManagementScreen extends ConsumerWidget {
  const ServicesManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(serviceMgmtProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Serviços'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/services/new'),
          ),
        ],
      ),
      body: switch (state) {
        ServiceMgmtLoading() => const Center(child: CircularProgressIndicator()),
        ServiceMgmtError(:final message) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.read(serviceMgmtProvider.notifier).refresh(),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ServiceMgmtLoaded(:final grouped, :final all) when all.isEmpty =>
          EmptyStateWidget(
            icon: Icons.content_cut_outlined,
            title: 'Nenhum serviço cadastrado',
            subtitle: 'Adicione seu primeiro serviço para começar',
            ctaLabel: 'Adicionar serviço',
            onCta: () => context.push('/services/new'),
          ),
        ServiceMgmtLoaded(:final grouped) => RefreshIndicator(
            onRefresh: () => ref.read(serviceMgmtProvider.notifier).refresh(),
            child: ListView(
              children: grouped.entries.map((entry) {
                return ExpansionTile(
                  title: Text(
                    '${entry.key} (${entry.value.length})',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  initiallyExpanded: true,
                  children: entry.value
                      .map((s) => ServiceCard(
                            service: s,
                            onTap: () => context.push('/services/${s.id}/edit'),
                          ))
                      .toList(),
                );
              }).toList(),
            ),
          ),
      },
    );
  }
}
