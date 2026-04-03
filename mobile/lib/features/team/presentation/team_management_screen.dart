import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../providers/team_provider.dart';
import 'professional_form_screen.dart';
import 'widgets/professional_card.dart';

class TeamManagementScreen extends ConsumerWidget {
  const TeamManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(teamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipe'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => ProfessionalFormSheet.show(context),
          ),
        ],
      ),
      body: switch (state) {
        TeamLoading() => const Center(child: CircularProgressIndicator()),
        TeamError(:final message) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.read(teamProvider.notifier).refresh(),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        TeamLoaded(:final professionals) when professionals.isEmpty =>
          EmptyStateWidget(
            icon: Icons.group_outlined,
            title: 'Nenhuma profissional',
            subtitle: 'Convide sua primeira profissional para a equipe',
            ctaLabel: 'Convidar profissional',
            onCta: () => ProfessionalFormSheet.show(context),
          ),
        TeamLoaded(:final professionals) => RefreshIndicator(
            onRefresh: () => ref.read(teamProvider.notifier).refresh(),
            child: ListView.builder(
              itemCount: professionals.length,
              itemBuilder: (_, i) => ProfessionalCard(
                professional: professionals[i],
              ),
            ),
          ),
      },
    );
  }
}
