import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../data/team_repository.dart';
import '../domain/professional_model.dart';
import '../providers/invites_provider.dart';
import '../providers/team_provider.dart';
import 'professional_form_screen.dart';
import 'widgets/pending_invite_card.dart';
import 'widgets/professional_card.dart';

class TeamManagementScreen extends ConsumerWidget {
  const TeamManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Equipe'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => ProfessionalFormSheet.show(context),
            ),
          ],
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.neutral400,
            indicatorColor: AppColors.primary,
            indicatorWeight: 2.5,
            labelStyle:
                AppTypography.bodySemibold.copyWith(fontSize: 14),
            unselectedLabelStyle:
                AppTypography.body.copyWith(fontSize: 14),
            tabs: const [
              Tab(text: 'Equipe'),
              Tab(text: 'Convites'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _TeamTab(),
            _InvitesTab(),
          ],
        ),
      ),
    );
  }
}

// ─── Team tab ───────────────────────────────────────────────

class _TeamTab extends ConsumerWidget {
  const _TeamTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(teamProvider);

    return switch (state) {
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
    };
  }
}

// ─── Invites tab ────────────────────────────────────────────

class _InvitesTab extends ConsumerWidget {
  const _InvitesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(invitesProvider);

    return switch (state) {
      InvitesLoading() => const Center(child: CircularProgressIndicator()),
      InvitesError(:final message) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    ref.read(invitesProvider.notifier).refresh(),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      InvitesLoaded(:final invites) when invites.isEmpty =>
        EmptyStateWidget(
          icon: Icons.mail_outline_rounded,
          title: 'Nenhum convite pendente',
          subtitle: 'Convites enviados aparecerão aqui até serem aceitos',
          ctaLabel: 'Convidar profissional',
          onCta: () => ProfessionalFormSheet.show(context),
        ),
      InvitesLoaded(:final invites) => RefreshIndicator(
          onRefresh: () => ref.read(invitesProvider.notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            itemCount: invites.length,
            itemBuilder: (_, i) => PendingInviteCard(
              invite: invites[i],
              onResend: () => _resendInvite(context, ref, invites[i]),
              onCancel: () => _cancelInvite(context, ref, invites[i].token),
            ),
          ),
        ),
    };
  }

  Future<void> _resendInvite(
      BuildContext context, WidgetRef ref, PendingInvite invite) async {
    try {
      final repo = ref.read(teamRepositoryProvider);
      await repo.resendInvite(invite.token);

      // Build WhatsApp link with the phone from invite
      if (invite.phone != null && invite.phone!.isNotEmpty && context.mounted) {
        final phoneDigits = invite.phone!.replaceAll(RegExp(r'[^\d]'), '');
        final inviteLink = 'oriz://invite/${invite.token}';
        final message = Uri.encodeComponent(
          'Você foi convidada para usar o Oriz! Clique para aceitar: $inviteLink',
        );
        final whatsappUrl = 'https://wa.me/$phoneDigits?text=$message';
        final uri = Uri.parse(whatsappUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }

      ref.read(invitesProvider.notifier).refresh();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Convite reenviado!'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao reenviar: $e')),
        );
      }
    }
  }

  Future<void> _cancelInvite(
      BuildContext context, WidgetRef ref, String token) async {
    // Confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar convite?'),
        content: const Text(
            'O link enviado deixará de funcionar. Você poderá convidar novamente depois.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Não'),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(ctx, true);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cancelar convite'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repo = ref.read(teamRepositoryProvider);
      await repo.cancelInvite(token);
      ref.read(invitesProvider.notifier).refresh();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Convite cancelado'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao cancelar: $e')),
        );
      }
    }
  }
}
