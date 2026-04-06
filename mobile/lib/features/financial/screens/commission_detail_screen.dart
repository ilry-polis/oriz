import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/commission_model.dart';
import '../providers/commission_provider.dart';

class CommissionDetailScreen extends ConsumerWidget {
  final String professionalId;
  final CommissionPeriod period;

  const CommissionDetailScreen({
    super.key,
    required this.professionalId,
    required this.period,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(commissionDetailProvider(
      (professionalId: professionalId, period: period),
    ));

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        title: const Text('Comissões'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.sm,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: AppColors.neutral400,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  period.label,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.neutral400,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppColors.error),
                const SizedBox(height: AppSpacing.md),
                Text('Erro ao carregar', style: AppTypography.bodySemibold),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  error.toString(),
                  style: AppTypography.caption,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        data: (loaded) => _buildLoaded(context, loaded.commissions),
      ),
    );
  }

  Widget _buildLoaded(
      BuildContext context, List<CommissionModel> commissions) {
    if (commissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.account_balance_wallet_outlined,
              size: 48,
              color: AppColors.neutral300,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Nenhuma comissão no período',
              style: AppTypography.body.copyWith(color: AppColors.neutral400),
            ),
          ],
        ),
      );
    }

    final totalProfessional = commissions.fold<int>(
      0,
      (sum, c) => sum + c.professionalAmount,
    );
    final totalCardFee = commissions.fold<int>(
      0,
      (sum, c) => sum + c.cardFeeAmount,
    );

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text(
                'COMISSÕES POR ATENDIMENTO',
                style: AppTypography.micro.copyWith(
                  color: AppColors.neutral400,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.neutral200),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: commissions.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.neutral200,
                    indent: AppSpacing.md,
                  ),
                  itemBuilder: (context, index) =>
                      _CommissionEntry(commission: commissions[index]),
                ),
              ),
            ],
          ),
        ),
        // ── Summary footer ──
        _SummaryFooter(
          totalProfessional: totalProfessional,
          totalCardFee: totalCardFee,
        ),
      ],
    );
  }
}

// ─── Commission Entry Row ────────────────────────────────────
class _CommissionEntry extends StatelessWidget {
  final CommissionModel commission;

  const _CommissionEntry({required this.commission});

  static final _dateFmt = DateFormat('d MMM · HH:mm', 'pt_BR');
  static final _currFmt = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _dateFmt.format(commission.periodStart),
                  style: AppTypography.caption.copyWith(
                    fontSize: 13,
                    color: AppColors.neutral900,
                  ),
                ),
                if (commission.cardFeeAmount > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Taxa cartão: −${commission.formattedCardFee}',
                    style: AppTypography.micro.copyWith(
                      color: AppColors.neutral400,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Gross amount
              Text(
                _currFmt.format(commission.amount / 100.0),
                style: AppTypography.caption.copyWith(
                  fontSize: 12,
                  color: AppColors.neutral400,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              // Net commission
              Text(
                commission.formattedProfessionalAmount,
                style: AppTypography.bodySemibold.copyWith(
                  fontSize: 14,
                  color: AppColors.neutral900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Summary Footer ───────────────────────────────────────────
class _SummaryFooter extends StatelessWidget {
  final int totalProfessional;
  final int totalCardFee;

  const _SummaryFooter({
    required this.totalProfessional,
    required this.totalCardFee,
  });

  static final _currFmt = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.neutral200),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (totalCardFee > 0)
            _SummaryRow(
              label: 'Taxa cartão descontada',
              value: '−${_currFmt.format(totalCardFee / 100.0)}',
              valueColor: AppColors.error,
            ),
          _SummaryRow(
            label: 'Total a pagar',
            value: _currFmt.format(totalProfessional / 100.0),
            isBold: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.body.copyWith(
              fontSize: 14,
              color: isBold ? AppColors.neutral900 : AppColors.neutral600,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodySemibold.copyWith(
              fontSize: isBold ? 16 : 14,
              color: valueColor ?? AppColors.neutral900,
            ),
          ),
        ],
      ),
    );
  }
}
