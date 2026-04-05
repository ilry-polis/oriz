import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/providers/auth_provider.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studioName = ref.watch(currentStudioNameProvider) ?? 'Meu Estúdio';
    final authState = ref.watch(authNotifierProvider);
    final userEmail = authState is AuthAuthenticated
        ? authState.session.user.email ?? ''
        : '';
    final initials = _getInitials(studioName);

    return Scaffold(
      appBar: AppBar(title: const Text('Mais')),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        children: [
          // ── Studio header ──
          _ProfileHeader(
            initials: initials,
            name: studioName,
            email: userEmail,
            onTap: () {}, // TODO: navigate to profile
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Studio section ──
          _SectionLabel(label: 'Estúdio'),
          const SizedBox(height: AppSpacing.sm),
          _SectionCard(
            children: [
              _MenuRow(
                icon: Icons.group_outlined,
                title: 'Equipe',
                onTap: () => context.push('/more/team'),
              ),
              const _MenuDivider(),
              _MenuRow(
                icon: Icons.category_outlined,
                title: 'Categorias',
                subtitle: 'Gerenciar categorias de serviços',
                onTap: () => context.push('/more/categories'),
              ),
              const _MenuDivider(),
              _MenuRow(
                icon: Icons.schedule_outlined,
                title: 'Meus horários',
                subtitle: 'Configurar horários de trabalho',
                onTap: () => context.push('/more/working-hours'),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Financial section ──
          _SectionLabel(label: 'Financeiro'),
          const SizedBox(height: AppSpacing.sm),
          _SectionCard(
            children: [
              _MenuRow(
                icon: Icons.attach_money_rounded,
                title: 'Financeiro',
                subtitle: 'Receitas, pagamentos e comissões',
                onTap: () => context.push('/more/financial'),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── App section ──
          _SectionLabel(label: 'Aplicativo'),
          const SizedBox(height: AppSpacing.sm),
          _SectionCard(
            children: [
              _MenuRow(
                icon: Icons.settings_outlined,
                title: 'Configurações',
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Logout ──
          _LogoutButton(
            onTap: () => _showLogoutDialog(context, ref),
          ),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?';
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Text('Sair da conta', style: AppTypography.bodySemibold),
        content: Text(
          'Tem certeza que deseja sair?',
          style: AppTypography.body.copyWith(color: AppColors.neutral600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: AppTypography.bodySemibold.copyWith(color: AppColors.neutral600),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authNotifierProvider.notifier).signOut();
            },
            child: Text(
              'Sair',
              style: AppTypography.bodySemibold.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Profile Header ──────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  final String initials;
  final String name;
  final String email;
  final VoidCallback onTap;

  const _ProfileHeader({
    required this.initials,
    required this.name,
    required this.email,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.neutral100,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.neutral200),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: AppTypography.bodySemibold.copyWith(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTypography.bodySemibold),
                  if (email.isNotEmpty)
                    Text(
                      email,
                      style: AppTypography.caption,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.neutral300,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section Label ───────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.micro.copyWith(
          color: AppColors.neutral400,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ─── Section Card ────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.neutral200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

// ─── Menu Divider ────────────────────────────────────────────
class _MenuDivider extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: AppColors.neutral200,
      indent: AppSpacing.md + 24 + AppSpacing.md, // icon area
    );
  }
}

// ─── Menu Row ────────────────────────────────────────────────
class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool enabled;

  const _MenuRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled
            ? () {
                HapticFeedback.lightImpact();
                onTap?.call();
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 24,
                color: enabled ? AppColors.neutral600 : AppColors.neutral300,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.body.copyWith(
                        color: enabled
                            ? AppColors.neutral900
                            : AppColors.neutral300,
                      ),
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle!,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.neutral400,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (enabled)
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.neutral300,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Logout Button ───────────────────────────────────────────
class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.errorSoft),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.logout, size: 20, color: AppColors.error),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Sair da conta',
                style: AppTypography.bodySemibold.copyWith(
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
