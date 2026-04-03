import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class _MenuItem {
  final IconData icon;
  final String label;
  final String? route;
  final VoidCallback? onTap;
  final Color? color;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.route,
    this.onTap,
    this.color,
  });
}

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _MenuItem(
        icon: Icons.schedule_outlined,
        label: 'Meu horario',
        route: '/more/working-hours',
      ),
      _MenuItem(
        icon: Icons.settings_outlined,
        label: 'Configuracoes',
        onTap: () {},
      ),
      _MenuItem(
        icon: Icons.help_outline_rounded,
        label: 'Ajuda',
        onTap: () {},
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm,
              ),
              child: const Text('Mais', style: AppTypography.title),
            ),
            const Divider(height: 1, color: AppColors.neutral200),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                itemCount: items.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 56, color: AppColors.neutral200),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final color = item.color ?? AppColors.neutral900;
                  return ListTile(
                    leading: Icon(item.icon, color: color, size: 22),
                    title: Text(item.label, style: AppTypography.body.copyWith(color: color)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.neutral400, size: 20),
                    onTap: item.route != null
                        ? () => context.push(item.route!)
                        : item.onTap,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
