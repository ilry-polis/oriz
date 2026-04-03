import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/appointment_model.dart';
import 'status_badge.dart';

class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback? onTap;

  /// Called when the user confirms the appointment (pending only).
  final VoidCallback? onConfirm;

  /// Called when the user completes the appointment (confirmed only).
  final VoidCallback? onComplete;

  /// Called when the user cancels (pending or confirmed).
  final VoidCallback? onCancel;

  /// Called when the user marks as no-show (confirmed only).
  final VoidCallback? onMarkNoShow;

  const AppointmentCard({
    super.key,
    required this.appointment,
    this.onTap,
    this.onConfirm,
    this.onComplete,
    this.onCancel,
    this.onMarkNoShow,
  });

  String get _timeLabel {
    final h = appointment.startTime.hour.toString().padLeft(2, '0');
    final m = appointment.startTime.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// For terminal states (completed, cancelled, noShow), render at 60% opacity.
  bool get _isTerminal => appointment.isTerminal;

  /// Swipe-right action based on status:
  /// - pending → confirm (blue)
  /// - confirmed → complete (green)
  VoidCallback? get _swipeRightAction {
    if (appointment.canConfirm) return onConfirm;
    if (appointment.canComplete) return onComplete;
    return null;
  }

  Color get _swipeRightColor {
    if (appointment.canConfirm) return AppColors.info;
    return AppColors.success;
  }

  IconData get _swipeRightIcon {
    if (appointment.canConfirm) return Icons.check_circle_outline_rounded;
    return Icons.check_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final card = Dismissible(
      key: ValueKey(appointment.id),
      // Only allow swipe if there's an action available
      direction: appointment.isTerminal
          ? DismissDirection.none
          : DismissDirection.horizontal,
      background: _swipeBackground(
        color: _swipeRightColor,
        icon: _swipeRightIcon,
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _swipeBackground(
        color: AppColors.error,
        icon: Icons.close_rounded,
        alignment: Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        HapticFeedback.mediumImpact();
        if (direction == DismissDirection.startToEnd) {
          _swipeRightAction?.call();
        } else {
          onCancel?.call();
        }
        return false; // card stays, state updates via provider
      },
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap?.call();
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.neutral100,
            border: Border.all(color: AppColors.neutral200),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(_timeLabel, style: AppTypography.bodySemibold),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      appointment.clientName,
                      style: AppTypography.body,
                      overflow: TextOverflow.ellipsis,
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
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${appointment.serviceName} · ${appointment.durationMinutes} min',
                style: AppTypography.caption,
              ),
              const SizedBox(height: AppSpacing.sm),
              StatusBadge(status: appointment.status),
            ],
          ),
        ),
      ),
    );

    if (_isTerminal) {
      return Opacity(opacity: 0.6, child: card);
    }
    return card;
  }

  Widget _swipeBackground({
    required Color color,
    required IconData icon,
    required Alignment alignment,
  }) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }

  void _showContextMenu(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
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
            if (!appointment.isTerminal) ...[
              _menuItem(ctx, Icons.edit_outlined, 'Editar agendamento'),
              _menuItem(ctx, Icons.person_outline_rounded, 'Ver cliente'),
              if (appointment.canMarkNoShow)
                _menuItem(
                  ctx,
                  Icons.visibility_off_outlined,
                  'Marcar nao compareceu',
                  onTap: () {
                    Navigator.pop(ctx);
                    onMarkNoShow?.call();
                  },
                ),
              if (appointment.canCancel)
                _menuItem(
                  ctx,
                  Icons.cancel_outlined,
                  'Cancelar',
                  color: AppColors.error,
                  onTap: () {
                    Navigator.pop(ctx);
                    onCancel?.call();
                  },
                ),
            ] else ...[
              _menuItem(ctx, Icons.person_outline_rounded, 'Ver cliente'),
            ],
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
      onTap: onTap ?? () => Navigator.pop(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    );
  }
}
