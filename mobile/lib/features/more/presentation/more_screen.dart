import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mais')),
      body: ListView(
        children: [
          _MenuItem(
            icon: Icons.group_outlined,
            title: 'Equipe',
            onTap: () => context.push('/more/team'),
          ),
          _MenuItem(
            icon: Icons.category_outlined,
            title: 'Categorias',
            subtitle: 'Gerenciar categorias de serviços',
            onTap: () => context.push('/more/categories'),
          ),
          _MenuItem(
            icon: Icons.attach_money_rounded,
            title: 'Financeiro',
            subtitle: 'Em breve',
            enabled: false,
          ),
          const Divider(height: 1),
          _MenuItem(
            icon: Icons.settings_outlined,
            title: 'Configurações',
            onTap: () {}, // placeholder
          ),
          _MenuItem(
            icon: Icons.person_outline,
            title: 'Meu perfil',
            onTap: () {}, // placeholder
          ),
          const Divider(height: 1),
          _MenuItem(
            icon: Icons.logout,
            title: 'Sair',
            titleColor: AppColors.error,
            onTap: () => _showLogoutDialog(context, ref),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authNotifierProvider.notifier).signOut();
            },
            child: const Text('Sair', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final VoidCallback? onTap;
  final bool enabled;

  const _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.titleColor,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: enabled ? null : AppColors.neutral300),
      title: Text(
        title,
        style: TextStyle(
          color: enabled ? (titleColor ?? AppColors.neutral900) : AppColors.neutral300,
        ),
      ),
      subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(color: AppColors.neutral400, fontSize: 12)) : null,
      trailing: enabled ? const Icon(Icons.chevron_right, color: AppColors.neutral300) : null,
      onTap: enabled ? onTap : null,
    );
  }
}
