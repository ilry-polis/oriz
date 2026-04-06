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

// ─── Payment Entry ────────────────────────────────────────────────────────────

class _PaymentEntry {
  PaymentMethod? method;
  final TextEditingController amountController;

  _PaymentEntry({this.method, String? initialAmount})
      : amountController = TextEditingController(text: initialAmount ?? '');

  void dispose() => amountController.dispose();

  int get amountCents {
    final raw = amountController.text
        .replaceAll('R\$', '')
        .replaceAll(' ', '')
        .trim();
    final normalized = raw.replaceAll(',', '.');
    final value = double.tryParse(normalized) ?? 0.0;
    return (value * 100).round();
  }

  bool get isValid => method != null && amountCents > 0;
}

/// Bottom sheet for recording payment when completing an appointment.
///
/// Supports:
/// - Discount (R$ or %) with reason and quick-suggestion chips
/// - Split payment (2 methods)
/// - Credit installments
class PaymentSheet extends ConsumerStatefulWidget {
  final Appointment appointment;

  const PaymentSheet({super.key, required this.appointment});

  static Future<void> show(
    BuildContext context, {
    required Appointment appointment,
  }) {
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
  // ─── Payment entries (primary + optional split) ───────────────────────────
  late final List<_PaymentEntry> _entries;
  bool _splitEnabled = false;
  int _installments = 1;

  // ─── Discount ─────────────────────────────────────────────────────────────
  bool _discountExpanded = false;
  bool _discountIsPercent = false;
  final _discountController = TextEditingController();
  final _discountReasonController = TextEditingController();

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final price = widget.appointment.price;
    final reais = price ~/ 100;
    final centavos = price % 100;
    final initial = '$reais,${centavos.toString().padLeft(2, '0')}';
    _entries = [_PaymentEntry(initialAmount: initial)];
  }

  @override
  void dispose() {
    for (final e in _entries) {
      e.dispose();
    }
    _discountController.dispose();
    _discountReasonController.dispose();
    super.dispose();
  }

  // ─── Computed values ──────────────────────────────────────────────────────

  int get _originalPrice => widget.appointment.price;

  int get _discountCents {
    if (!_discountExpanded) return 0;
    final raw = _discountController.text.trim();
    if (raw.isEmpty) return 0;
    if (_discountIsPercent) {
      final pct = double.tryParse(raw.replaceAll(',', '.')) ?? 0.0;
      return ((_originalPrice * pct) / 100).round();
    } else {
      final normalized = raw.replaceAll(',', '.');
      final value = double.tryParse(normalized) ?? 0.0;
      return (value * 100).round();
    }
  }

  int get _finalPrice => (_originalPrice - _discountCents).clamp(0, _originalPrice);

  String _formatCents(int cents) {
    final reais = cents ~/ 100;
    final centavos = cents % 100;
    return 'R\$ $reais,${centavos.toString().padLeft(2, '0')}';
  }

  bool get _canSubmit {
    if (_submitting) return false;
    if (!_entries.first.isValid) return false;
    if (_splitEnabled && _entries.length > 1) {
      if (!_entries[1].isValid) return false;
    }
    return true;
  }

  void _addSplit() {
    final remaining = _finalPrice - _entries.first.amountCents;
    final remainingReais = remaining ~/ 100;
    final remainingCentavos = remaining % 100;
    setState(() {
      _splitEnabled = true;
      _entries.add(
        _PaymentEntry(
          initialAmount:
              '$remainingReais,${remainingCentavos.toString().padLeft(2, '0')}',
        ),
      );
    });
  }

  void _removeSplit() {
    setState(() {
      _splitEnabled = false;
      if (_entries.length > 1) {
        _entries.removeLast().dispose();
      }
    });
  }

  Future<void> _confirm() async {
    if (!_canSubmit) return;
    HapticFeedback.mediumImpact();
    setState(() => _submitting = true);

    try {
      // Build payments array
      final payments = <Map<String, dynamic>>[
        {
          'amount': _entries.first.amountCents,
          'method': _entries.first.method!.apiValue,
          if (_entries.first.method == PaymentMethod.credito &&
              _installments > 1)
            'installments': _installments,
        },
        if (_splitEnabled && _entries.length > 1)
          {
            'amount': _entries[1].amountCents,
            'method': _entries[1].method!.apiValue,
          },
      ];

      await ref.read(agendaNotifierProvider.notifier).completeAppointmentFull(
            widget.appointment.id,
            payments: payments,
            discountAmount: _discountExpanded ? _discountCents : null,
            discountReason: (_discountExpanded &&
                    _discountReasonController.text.trim().isNotEmpty)
                ? _discountReasonController.text.trim()
                : null,
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

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: SingleChildScrollView(
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
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Concluir atendimento', style: AppTypography.title),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${widget.appointment.serviceName} · ${widget.appointment.clientName}',
                      style:
                          AppTypography.body.copyWith(color: AppColors.neutral600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(color: AppColors.neutral200, height: 1),

              // Discount section
              _buildDiscountSection(),

              const Divider(color: AppColors.neutral200, height: 1),

              // Payment entry 1
              _buildPaymentEntry(0, label: _splitEnabled ? 'Valor 1' : 'Valor'),
              if (_entries.first.method == PaymentMethod.credito)
                _buildInstallments(),

              // Split section
              if (_splitEnabled && _entries.length > 1) ...[
                const Divider(
                    color: AppColors.neutral200, height: 1, indent: AppSpacing.lg),
                _buildPaymentEntry(1, label: 'Valor 2'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
                  child: TextButton(
                    onPressed: _removeSplit,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.neutral400,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('- Remover segundo metodo'),
                  ),
                ),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.sm),
                  child: TextButton.icon(
                    onPressed: _addSplit,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Adicionar metodo'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],

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
                        : Text(
                            _discountCents > 0
                                ? 'Concluir (${_formatCents(_finalPrice)})'
                                : 'Concluir',
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiscountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _discountExpanded = !_discountExpanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                const Icon(Icons.discount_outlined,
                    size: 18, color: AppColors.neutral600),
                const SizedBox(width: AppSpacing.sm),
                Text('Desconto', style: AppTypography.body),
                const Spacer(),
                if (_discountCents > 0)
                  Text(
                    '- ${_formatCents(_discountCents)}',
                    style: AppTypography.body.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                Icon(
                  _discountExpanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: AppColors.neutral400,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (_discountExpanded) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // R$ or % toggle
                Row(
                  children: [
                    _discountTypeChip(
                      label: 'R\$',
                      selected: !_discountIsPercent,
                      onTap: () =>
                          setState(() => _discountIsPercent = false),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _discountTypeChip(
                      label: '%',
                      selected: _discountIsPercent,
                      onTap: () =>
                          setState(() => _discountIsPercent = true),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextField(
                        controller: _discountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          prefixText: _discountIsPercent ? null : 'R\$ ',
                          suffixText: _discountIsPercent ? '%' : null,
                          hintText: _discountIsPercent ? '10' : '50,00',
                          filled: true,
                          fillColor: AppColors.neutral100,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                            borderSide: const BorderSide(
                                color: AppColors.neutral200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                            borderSide: const BorderSide(
                                color: AppColors.neutral200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                            borderSide:
                                const BorderSide(color: AppColors.primary),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          isDense: true,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                // Final amount preview
                if (_discountCents > 0) ...[
                  Row(
                    children: [
                      Text(
                        _formatCents(_originalPrice),
                        style: AppTypography.body.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: AppColors.neutral400,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        _formatCents(_finalPrice),
                        style: AppTypography.bodySemibold
                            .copyWith(color: AppColors.success),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                // Reason quick chips
                Text(
                  'Motivo do desconto',
                  style: AppTypography.caption
                      .copyWith(color: AppColors.neutral600),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  children: [
                    'Cortesia',
                    'Fidelidade',
                    'Pacote',
                  ]
                      .map(
                        (label) => ActionChip(
                          label: Text(label, style: AppTypography.micro),
                          onPressed: () {
                            _discountReasonController.text = label;
                            setState(() {});
                          },
                          backgroundColor:
                              _discountReasonController.text == label
                                  ? AppColors.accentSoft
                                  : AppColors.neutral100,
                          side: BorderSide(
                            color: _discountReasonController.text == label
                                ? AppColors.primary
                                : AppColors.neutral200,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextField(
                  controller: _discountReasonController,
                  decoration: InputDecoration(
                    hintText: 'Ou descrever motivo...',
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
                    isDense: true,
                  ),
                  style: AppTypography.body,
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _discountTypeChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.neutral100,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.neutral200,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.bodySemibold.copyWith(
            color: selected ? Colors.white : AppColors.neutral900,
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentEntry(int index, {required String label}) {
    final entry = _entries[index];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Amount field
          Text(
            '$label (R\$)',
            style: AppTypography.caption.copyWith(color: AppColors.neutral600),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: entry.amountController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: AppTypography.bodySemibold,
            decoration: InputDecoration(
              prefixText: 'R\$ ',
              prefixStyle:
                  AppTypography.body.copyWith(color: AppColors.neutral600),
              filled: true,
              fillColor: AppColors.neutral100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.neutral200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.neutral200),
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
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          // Payment method grid
          Text(
            'Forma de pagamento',
            style: AppTypography.caption.copyWith(color: AppColors.neutral600),
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
                .map((method) => _buildMethodCard(entry, method))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallments() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Parcelas',
            style: AppTypography.caption.copyWith(color: AppColors.neutral600),
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
                      color:
                          selected ? AppColors.primary : AppColors.neutral100,
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.neutral200,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.full),
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
    );
  }

  Widget _buildMethodCard(_PaymentEntry entry, PaymentMethod method) {
    final selected = entry.method == method;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          entry.method = method;
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
              color:
                  selected ? AppColors.primary : AppColors.neutral600,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              method.label,
              style: AppTypography.body.copyWith(
                color:
                    selected ? AppColors.primary : AppColors.neutral900,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
