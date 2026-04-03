import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/client_model.dart';
import 'tag_chip.dart';

class ClientListItem extends StatelessWidget {
  final ClientModel client;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleVip;
  final VoidCallback? onDelete;

  const ClientListItem({
    super.key,
    required this.client,
    this.onTap,
    this.onEdit,
    this.onToggleVip,
    this.onDelete,
  });

  String get _lastVisitText {
    if (client.lastAppointmentAt == null) return '';
    try {
      final date = DateTime.parse(client.lastAppointmentAt!);
      final months = [
        'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
        'jul', 'ago', 'set', 'out', 'nov', 'dez'
      ];
      return 'Última visita: ${date.day} ${months[date.month - 1]}';
    } catch (_) {
      return '';
    }
  }

  void _showContextMenu(BuildContext context) {
    final isVip = client.tags.contains('vip');
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.neutral300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _menuItem(ctx, Icons.edit_outlined, 'Editar cliente', onTap: () {
              Navigator.pop(ctx);
              onEdit?.call();
            }),
            _menuItem(
              ctx,
              isVip ? Icons.star_rounded : Icons.star_outline_rounded,
              isVip ? 'Remover VIP' : 'Marcar como VIP',
              color: isVip ? AppColors.accent : null,
              onTap: () {
                Navigator.pop(ctx);
                onToggleVip?.call();
              },
            ),
            _menuItem(
              ctx,
              Icons.delete_outline,
              'Excluir cliente',
              color: AppColors.error,
              onTap: () {
                Navigator.pop(ctx);
                onDelete?.call();
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(
    BuildContext context,
    IconData icon,
    String label, {
    Color? color,
    VoidCallback? onTap,
  }) {
    final c = color ?? AppColors.neutral900;
    return ListTile(
      leading: Icon(icon, color: c, size: 22),
      title: Text(label, style: AppTypography.body.copyWith(color: c)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.neutral100,
          border: Border.all(color: AppColors.neutral200),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.neutral200,
              child: Text(
                client.initials,
                style: const TextStyle(
                  color: AppColors.neutral600,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(client.name, style: AppTypography.bodySemibold),
                  if (_lastVisitText.isNotEmpty)
                    Text(
                      _lastVisitText,
                      style: AppTypography.caption
                          .copyWith(color: AppColors.neutral400),
                    ),
                  if (client.allTags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Wrap(
                        spacing: 4,
                        children: client.allTags
                            .map((t) => TagChip(label: t, readOnly: true))
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _showContextMenu(context),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.more_horiz_rounded,
                  color: AppColors.neutral400,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
