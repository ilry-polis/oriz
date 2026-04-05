import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../models/commission_model.dart';
import '../providers/commission_provider.dart';
import '../providers/financial_provider.dart';
import '../repositories/commission_repository.dart';
import '../widgets/breakdown_section.dart';
import '../widgets/kpi_card.dart';
import '../widgets/method_donut_chart.dart';
import '../widgets/payment_list_item.dart';
import '../widgets/revenue_bar_chart.dart';

class FinancialDashboardScreen extends ConsumerStatefulWidget {
  const FinancialDashboardScreen({super.key});

  @override
  ConsumerState<FinancialDashboardScreen> createState() =>
      _FinancialDashboardScreenState();
}

class _FinancialDashboardScreenState
    extends ConsumerState<FinancialDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(financialDashboardProvider.notifier).loadMorePayments();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        title: const Text('Financeiro'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.neutral900,
          unselectedLabelColor: AppColors.neutral400,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2,
          dividerColor: AppColors.neutral200,
          labelStyle: AppTypography.bodySemibold.copyWith(fontSize: 14),
          unselectedLabelStyle: AppTypography.body.copyWith(fontSize: 14),
          tabs: const [
            Tab(text: 'Resumo'),
            Tab(text: 'Gráficos'),
            Tab(text: 'Comissões'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ResumoTab(scrollController: _scrollController),
          const _GraficosTab(),
          const _ComissoesTab(),
        ],
      ),
    );
  }
}

// ─── Resumo Tab ───────────────────────────────────────────────
class _ResumoTab extends ConsumerWidget {
  final ScrollController scrollController;

  const _ResumoTab({required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashState = ref.watch(financialDashboardProvider);

    return switch (dashState) {
      FinancialDashboardLoading() => _buildSkeleton(),
      FinancialDashboardError(:final message) => _buildError(
          context,
          message,
          () => ref.read(financialDashboardProvider.notifier).refresh(),
        ),
      FinancialDashboardLoaded() => _buildLoaded(context, ref, dashState),
    };
  }

  Widget _buildSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Period chips skeleton
        Row(
          children: List.generate(
            3,
            (_) => Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Container(
                width: 60,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.neutral200,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // KPI grid skeleton
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.5,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(4, (_) => const KpiCardSkeleton()),
        ),
        const SizedBox(height: AppSpacing.md),
        ...List.generate(5, (_) => const PaymentListItemSkeleton()),
      ],
    );
  }

  Widget _buildError(
      BuildContext context, String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Erro ao carregar dados financeiros',
              style: AppTypography.bodySemibold,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: AppTypography.caption.copyWith(color: AppColors.neutral400),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoaded(
    BuildContext context,
    WidgetRef ref,
    FinancialDashboardLoaded state,
  ) {
    return RefreshIndicator(
      onRefresh: () => ref.read(financialDashboardProvider.notifier).refresh(),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // ── Period selector ──
          _PeriodSelector(
            selected: state.period,
            onChanged: (p) =>
                ref.read(financialDashboardProvider.notifier).changePeriod(p),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── KPI grid ──
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              KpiCard(
                label: 'Faturamento',
                value: state.summary.formattedRevenue,
                icon: Icons.attach_money_rounded,
              ),
              KpiCard(
                label: 'Ticket Médio',
                value: state.summary.formattedAvgTicket,
                icon: Icons.receipt_outlined,
              ),
              KpiCard(
                label: 'Ocupação',
                value: state.summary.formattedOccupancy,
                icon: Icons.schedule_rounded,
              ),
              KpiCard(
                label: 'Atendimentos',
                value: state.summary.formattedAppointments,
                icon: Icons.event_available_outlined,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Revenue bar chart ──
          Text(
            'FATURAMENTO POR DIA',
            style: AppTypography.micro.copyWith(
              color: AppColors.neutral400,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          RevenueBarChartCard(data: state.dailyRevenue),
          const SizedBox(height: AppSpacing.md),

          // ── Payments list (max 5, with "Ver tudo" link) ──
          if (state.payments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.payments_outlined,
                      size: 48,
                      color: AppColors.neutral300,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Nenhum pagamento no período',
                      style: AppTypography.body.copyWith(
                        color: AppColors.neutral400,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PAGAMENTOS RECENTES',
                  style: AppTypography.micro.copyWith(
                    color: AppColors.neutral400,
                    letterSpacing: 0.8,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push('/more/financial/payments'),
                  child: Text(
                    'Ver tudo',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
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
                itemCount: state.payments.take(5).length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.neutral200,
                  indent: AppSpacing.md,
                ),
                itemBuilder: (context, index) {
                  return PaymentListItemWidget(
                    payment: state.payments[index],
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

// ─── Period Selector ──────────────────────────────────────────
class _PeriodSelector extends StatelessWidget {
  final FinancialPeriod selected;
  final ValueChanged<FinancialPeriod> onChanged;

  const _PeriodSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: FinancialPeriod.values.map((period) {
          final isSelected = period == selected;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: ChoiceChip(
              label: Text(period.label),
              selected: isSelected,
              onSelected: (_) {
                HapticFeedback.selectionClick();
                onChanged(period);
              },
              selectedColor: AppColors.primary,
              backgroundColor: Colors.white,
              labelStyle: AppTypography.caption.copyWith(
                color: isSelected ? Colors.white : AppColors.neutral600,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 13,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.neutral200,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Gráficos Tab ────────────────────────────────────────────
class _GraficosTab extends ConsumerWidget {
  const _GraficosTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashState = ref.watch(financialDashboardProvider);

    if (dashState is FinancialDashboardLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (dashState is FinancialDashboardError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text('Erro ao carregar gráficos', style: AppTypography.bodySemibold),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () =>
                  ref.read(financialDashboardProvider.notifier).refresh(),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    final state = dashState as FinancialDashboardLoaded;

    return RefreshIndicator(
      onRefresh: () => ref.read(financialDashboardProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // ── Period selector ──
          _PeriodSelector(
            selected: state.period,
            onChanged: (p) =>
                ref.read(financialDashboardProvider.notifier).changePeriod(p),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Donut: por método de pagamento ──
          MethodDonutChartCard(data: state.breakdownByMethod),
          const SizedBox(height: AppSpacing.md),

          // ── Breakdown: por serviço ──
          Text(
            'RECEITA POR SERVIÇO',
            style: AppTypography.micro.copyWith(
              color: AppColors.neutral400,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          BreakdownSection(
            title: 'Por serviço',
            items: state.breakdownByService,
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Breakdown: por profissional ──
          Text(
            'RECEITA POR PROFISSIONAL',
            style: AppTypography.micro.copyWith(
              color: AppColors.neutral400,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          BreakdownSection(
            title: 'Por profissional',
            items: state.breakdownByProfessional,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

// ─── Comissões Tab ────────────────────────────────────────────
class _ComissoesTab extends ConsumerWidget {
  const _ComissoesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(commissionProvider);

    return switch (state) {
      CommissionLoading() => const Center(
          child: CircularProgressIndicator(),
        ),
      CommissionError(:final message) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppColors.error),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Erro ao carregar comissões',
                  style: AppTypography.bodySemibold,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(message, style: AppTypography.caption),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: () =>
                      ref.read(commissionProvider.notifier).refresh(),
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      CommissionLoaded() => _buildLoaded(context, ref, state),
    };
  }

  Widget _buildLoaded(
    BuildContext context,
    WidgetRef ref,
    CommissionLoaded state,
  ) {
    return RefreshIndicator(
      onRefresh: () => ref.read(commissionProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // ── Period navigator ──
          _PeriodNavigator(
            label: state.period.label,
            onPrevious: () =>
                ref.read(commissionProvider.notifier).goToPreviousPeriod(),
            onNext: () =>
                ref.read(commissionProvider.notifier).goToNextPeriod(),
          ),
          const SizedBox(height: AppSpacing.md),

          if (state.summaries.isEmpty)
            EmptyStateWidget(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Nenhuma comissão',
              subtitle:
                  'As comissões aparecem aqui após atendimentos concluídos',
              ctaLabel: 'Ver agenda',
              onCta: () => context.go('/agenda'),
            )
          else ...[
            Text(
              'PROFISSIONAIS',
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
                itemCount: state.summaries.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.neutral200,
                  indent: AppSpacing.md,
                ),
                itemBuilder: (context, index) {
                  final summary = state.summaries[index];
                  return _CommissionRow(
                    summary: summary,
                    isMarking: state.markingPaidIds
                        .contains(summary.professionalId),
                    period: state.period,
                    onMarkPaid: () => _confirmMarkPaid(context, ref, summary),
                    onTap: () => context.push(
                      '/more/financial/commissions/${summary.professionalId}',
                      extra: state.period,
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  void _confirmMarkPaid(
    BuildContext context,
    WidgetRef ref,
    CommissionSummary summary,
  ) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          'Marcar como pago',
          style: AppTypography.bodySemibold,
        ),
        content: Text(
          'Confirmar pagamento de ${summary.formattedTotalAmount} para ${summary.professionalName}?',
          style: AppTypography.body
              .copyWith(color: AppColors.neutral600, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: AppTypography.bodySemibold
                  .copyWith(color: AppColors.neutral600),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // Mark all pending commissions for this professional
              final state = ref.read(commissionProvider);
              if (state is! CommissionLoaded) return;
              // We need the actual commission IDs — load them
              final repo = ref.read(commissionRepositoryProvider);
              final result = await repo.list(
                professionalId: summary.professionalId,
                status: 'pending',
                periodStart: state.period.startStr,
                periodEnd: state.period.endStr,
              );
              final ids = result.items.map((c) => c.id).toList();
              if (ids.isNotEmpty) {
                await ref
                    .read(commissionProvider.notifier)
                    .markPaid(summary.professionalId, ids);
              }
            },
            child: Text(
              'Confirmar',
              style: AppTypography.bodySemibold.copyWith(
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Period Navigator ─────────────────────────────────────────
class _PeriodNavigator extends StatelessWidget {
  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _PeriodNavigator({
    required this.label,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () {
              HapticFeedback.selectionClick();
              onPrevious();
            },
            color: AppColors.neutral600,
            visualDensity: VisualDensity.compact,
          ),
          Text(
            label,
            style: AppTypography.bodySemibold.copyWith(fontSize: 15),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () {
              HapticFeedback.selectionClick();
              onNext();
            },
            color: AppColors.neutral600,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

// ─── Commission Row ───────────────────────────────────────────
class _CommissionRow extends StatelessWidget {
  final CommissionSummary summary;
  final bool isMarking;
  final CommissionPeriod period;
  final VoidCallback onMarkPaid;
  final VoidCallback onTap;

  const _CommissionRow({
    required this.summary,
    required this.isMarking,
    required this.period,
    required this.onMarkPaid,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPaid = summary.isPaid;

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              alignment: Alignment.center,
              child: Text(
                _initials(summary.professionalName),
                style: AppTypography.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Name + count
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.professionalName,
                    style: AppTypography.body.copyWith(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${summary.count} atendimento${summary.count != 1 ? "s" : ""}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.neutral400,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Amount + status + action
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  summary.formattedTotalAmount,
                  style: AppTypography.bodySemibold.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 4),
                if (isMarking)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (isPaid)
                  _StatusBadge(
                    label: 'Pago',
                    color: AppColors.success,
                    softColor: AppColors.successSoft,
                  )
                else
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onMarkPaid();
                    },
                    child: _StatusBadge(
                      label: 'Pagar',
                      color: AppColors.warning,
                      softColor: AppColors.warningSoft,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AppSpacing.xs),
            const Icon(
              Icons.chevron_right,
              size: 16,
              color: AppColors.neutral300,
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?';
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color softColor;

  const _StatusBadge({
    required this.label,
    required this.color,
    required this.softColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: softColor,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: AppTypography.micro.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}
