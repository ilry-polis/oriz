import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Bottom sheet for quick booking at a specific time slot
class QuickBookSheet extends StatefulWidget {
  final int hour;
  final DateTime date;

  const QuickBookSheet({super.key, required this.hour, required this.date});

  static Future<void> show(BuildContext context, {required int hour, required DateTime date}) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => QuickBookSheet(hour: hour, date: date),
    );
  }

  @override
  State<QuickBookSheet> createState() => _QuickBookSheetState();
}

class _QuickBookSheetState extends State<QuickBookSheet> {
  String? _selectedClient;
  String? _selectedService;

  // Mock data
  static const _clients = [
    'Maria Silva',
    'Ana Costa',
    'Juliana Mendes',
    'Carla Souza',
    'Fernanda Lima',
  ];

  static const _services = [
    ('Manicure', 30, 5000),
    ('Pedicure', 45, 6000),
    ('Esmaltação em gel', 60, 8000),
    ('Sobrancelha', 30, 4000),
    ('Limpeza de pele', 90, 12000),
  ];

  String get _timeLabel => '${widget.hour.toString().padLeft(2, '0')}:00';

  String _formatPrice(int cents) {
    final reais = cents ~/ 100;
    final centavos = cents % 100;
    return 'R\$ $reais,${centavos.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.neutral300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      _timeLabel,
                      style: AppTypography.bodySemibold.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Novo agendamento', style: AppTypography.title),
                ],
              ),
            ),

            const Divider(color: AppColors.neutral200, height: 1),

            // Client selector
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0,
              ),
              child: Text(
                'Cliente',
                style: AppTypography.caption.copyWith(color: AppColors.neutral600),
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                itemCount: _clients.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (_, i) {
                  final client = _clients[i];
                  final selected = _selectedClient == client;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedClient = client);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : AppColors.neutral100,
                        border: Border.all(
                          color: selected ? AppColors.primary : AppColors.neutral200,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        client.split(' ').first,
                        style: AppTypography.caption.copyWith(
                          color: selected ? Colors.white : AppColors.neutral900,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Service selector
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm,
              ),
              child: Text(
                'Serviço',
                style: AppTypography.caption.copyWith(color: AppColors.neutral600),
              ),
            ),
            ...List.generate(_services.length, (i) {
              final (name, duration, price) = _services[i];
              final selected = _selectedService == name;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedService = name);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: 3,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : AppColors.neutral100,
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.neutral200,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: AppTypography.body.copyWith(
                            color: selected ? Colors.white : AppColors.neutral900,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                      Text(
                        '${duration}min',
                        style: AppTypography.caption.copyWith(
                          color: selected ? Colors.white70 : AppColors.neutral400,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        _formatPrice(price),
                        style: AppTypography.caption.copyWith(
                          color: selected ? Colors.white : AppColors.neutral600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            // Confirm button
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _selectedClient != null && _selectedService != null
                      ? () {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '$_selectedClient agendado às $_timeLabel',
                              ),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.neutral200,
                    disabledForegroundColor: AppColors.neutral400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    textStyle: AppTypography.bodySemibold,
                  ),
                  child: const Text('Confirmar'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
