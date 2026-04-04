import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/http/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/appointment_model.dart';
import '../providers/agenda_provider.dart';

enum PaymentMethod { dinheiro, pix, debito, credito }

extension PaymentMethodX on PaymentMethod {
  String get label => switch (this) {
        PaymentMethod.dinheiro => 'Dinheiro',
        PaymentMethod.pix => 'PIX',
        PaymentMethod.debito => 'Debito',
        PaymentMethod.credito => 'Credito',
      };

  IconData get icon => switch (this) {
        PaymentMethod.dinheiro => Icons.attach_money_rounded,
        PaymentMethod.pix => Icons.qr_code_rounded,
        PaymentMethod.debito => Icons.credit_card_rounded,
        PaymentMethod.credito => Icons.credit_score_rounded,
      };

  String get apiValue => switch (this) {
        PaymentMethod.dinheiro => 'cash',
        PaymentMethod.pix => 'pix',
        PaymentMethod.debito => 'debit',
        PaymentMethod.credito => 'credit',
      };
}

/// Bottom sheet for recording payment when completing an appointment.
///
/// Opened via swipe-right on a confirmed appointment.
class PaymentSheet extends ConsumerStatefulWidget {
  final Appointment appointment;

  const PaymentSheet({super.key, required this.appointment});

  static Future<void> show(BuildContext context, {required Appointment appointment}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => PaymentSheet(appointment: appointment),
    );
  }

  @override
  ConsumerState<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<PaymentSheet> {
  PaymentMethod? _selectedMethod;
  int _installments = 1;
  late final TextEditingController _amountController;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final price = widget.appointment.price;
    final reais = price ~/ 100;
    final centavos = price % 100;
    _amountController = TextEditingController(
      text: '$reais,${centavos.toString().padLeft(2, '0')}',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  int get _amountCents {
    final raw = _amountController.text
        .replaceAll('R\$', '')
        .replaceAll(' ', '')
        .trim();
    // Parse "XX,YY" or "XX.YY" format
    final normalized = raw.replaceAll(',', '.');
    final value = double.tryParse(normalized) ?? 0.0;
    return (value * 100).round();
  }

  bool get _canSubmit => _selectedMethod != null && !_submitting;

  Future<void> _confirm() async {
    if (!_canSubmit) return;
    HapticFeedback.mediumImpact();
    setState(() => _submitting = true);
    try {
      await ref.read(agendaNotifierProvider.notifier).completeAppointment(
            widget.appointment.id,
            amountCents: _amountCents,
            method: _selectedMethod!.apiValue,
          );
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _submitting = false);
    }
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
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Concluir atendimento', style: AppTypography.title),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${widget.appointment.serviceName} · ${widget.appointment.clientName}',
                    style: AppTypography.body.copyWith(
                      color: AppColors.neutral600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(color: AppColors.neutral200, height: 1),
            // Amount field
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Valor (R\$)',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.neutral600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: AppTypography.bodySemibold,
                    decoration: InputDecoration(
                      prefixText: 'R\$ ',
                      prefixStyle: AppTypography.body.copyWith(
                        color: AppColors.neutral600,
                      ),
                      filled: true,
                      fillColor: AppColors.neutral100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide:
                            const BorderSide(color: AppColors.neutral200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide:
                            const BorderSide(color: AppColors.neutral200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Payment method grid
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Forma de pagamento',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.neutral600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 2.5,
                    physics: const NeverScrollableScrollPhysics(),
                    children: PaymentMethod.values
                        .map((method) => _buildMethodCard(method))
                        .toList(),
                  ),
                ],
              ),
            ),
            // Installments selector (credit only)
            if (_selectedMethod == PaymentMethod.credito)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Parcelas',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.neutral600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: 12,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: AppSpacing.xs),
                        itemBuilder: (_, i) {
                          final n = i + 1;
                          final selected = _installments == n;
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _installments = n);
                            },
                            child: Container(
                              width: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.neutral100,
                                border: Border.all(
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.neutral200,
                                ),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.full),
                              ),
                              child: Text(
                                '${n}x',
                                style: AppTypography.caption.copyWith(
                                  color: selected
                                      ? Colors.white
                                      : AppColors.neutral900,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            // Confirm button
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _canSubmit ? _confirm : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.neutral200,
                    disabledForegroundColor: AppColors.neutral400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    textStyle: AppTypography.bodySemibold,
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Concluir'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodCard(PaymentMethod method) {
    final selected = _selectedMethod == method;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedMethod = method;
          if (method != PaymentMethod.credito) _installments = 1;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : AppColors.neutral100,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.neutral200,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Icon(
              method.icon,
              size: 20,
              color: selected ? AppColors.primary : AppColors.neutral600,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              method.label,
              style: AppTypography.body.copyWith(
                color: selected ? AppColors.primary : AppColors.neutral900,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
