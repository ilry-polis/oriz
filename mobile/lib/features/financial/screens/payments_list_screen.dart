import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/payment_model.dart';
import '../repositories/financial_repository.dart';
import '../widgets/payment_list_item.dart';

// ─── State ────────────────────────────────────────────────────

sealed class PaymentsListState {
  const PaymentsListState();
}

class PaymentsListLoading extends PaymentsListState {
  const PaymentsListLoading();
}

class PaymentsListLoaded extends PaymentsListState {
  final List<PaymentListItem> payments;
  final bool hasMore;
  final String? cursor;
  final String? filterMethod;
  final bool isLoadingMore;

  const PaymentsListLoaded({
    required this.payments,
    required this.hasMore,
    this.cursor,
    this.filterMethod,
    this.isLoadingMore = false,
  });

  PaymentsListLoaded copyWith({
    List<PaymentListItem>? payments,
    bool? hasMore,
    String? cursor,
    String? filterMethod,
    bool? isLoadingMore,
    bool clearFilterMethod = false,
    bool clearCursor = false,
  }) {
    return PaymentsListLoaded(
      payments: payments ?? this.payments,
      hasMore: hasMore ?? this.hasMore,
      cursor: clearCursor ? null : cursor ?? this.cursor,
      filterMethod:
          clearFilterMethod ? null : filterMethod ?? this.filterMethod,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class PaymentsListError extends PaymentsListState {
  final String message;
  const PaymentsListError(this.message);
}

// ─── Notifier ─────────────────────────────────────────────────

class PaymentsListNotifier extends Notifier<PaymentsListState> {
  static final _fmt = DateFormat('yyyy-MM-dd');

  // Default to current month
  late DateTime _refDate;
  late String _dateFrom;
  late String _dateTo;

  @override
  PaymentsListState build() {
    _refDate = DateTime.now();
    final start = DateTime(_refDate.year, _refDate.month, 1);
    final end = DateTime(_refDate.year, _refDate.month + 1, 0);
    _dateFrom = _fmt.format(start);
    _dateTo = _fmt.format(end);
    _load(showLoading: true);
    return const PaymentsListLoading();
  }

  Future<void> _load({
    String? filterMethod,
    String? cursor,
    bool showLoading = false,
    bool append = false,
  }) async {
    if (showLoading) state = const PaymentsListLoading();

    try {
      final repo = ref.read(financialRepositoryProvider);
      final result = await repo.listPayments(
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        method: filterMethod,
        cursor: cursor,
      );

      if (append && state is PaymentsListLoaded) {
        final current = state as PaymentsListLoaded;
        state = current.copyWith(
          payments: [...current.payments, ...result.items],
          hasMore: result.hasMore,
          cursor: result.cursor,
          isLoadingMore: false,
        );
      } else {
        state = PaymentsListLoaded(
          payments: result.items,
          hasMore: result.hasMore,
          cursor: result.cursor,
          filterMethod: filterMethod,
        );
      }
    } catch (e) {
      state = PaymentsListError(e.toString());
    }
  }

  Future<void> refresh() async {
    final method =
        state is PaymentsListLoaded ? (state as PaymentsListLoaded).filterMethod : null;
    await _load(filterMethod: method, showLoading: false);
  }

  Future<void> applyFilter(String? method) async {
    await _load(filterMethod: method, showLoading: true);
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! PaymentsListLoaded) return;
    if (!current.hasMore || current.cursor == null) return;
    if (current.isLoadingMore) return;

    state = current.copyWith(isLoadingMore: true);

    await _load(
      filterMethod: current.filterMethod,
      cursor: current.cursor,
      append: true,
    );
  }
}

final paymentsListProvider =
    NotifierProvider<PaymentsListNotifier, PaymentsListState>(
        PaymentsListNotifier.new);

// ─── Screen ───────────────────────────────────────────────────

class PaymentsListScreen extends ConsumerStatefulWidget {
  const PaymentsListScreen({super.key});

  @override
  ConsumerState<PaymentsListScreen> createState() => _PaymentsListScreenState();
}

class _PaymentsListScreenState extends ConsumerState<PaymentsListScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(paymentsListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentsListProvider);

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        title: const Text('Pagamentos'),
      ),
      body: Column(
        children: [
          // ── Filter chips ──
          Container(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
              child: _FilterChipsRow(
                selectedMethod: state is PaymentsListLoaded
                    ? state.filterMethod
                    : null,
                onMethodChanged: (m) =>
                    ref.read(paymentsListProvider.notifier).applyFilter(m),
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.neutral200),
          // ── Content ──
          Expanded(
            child: switch (state) {
              PaymentsListLoading() => _buildSkeleton(),
              PaymentsListError(:final message) => _buildError(message),
              PaymentsListLoaded() => _buildLoaded(state),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      itemCount: 8,
      itemBuilder: (context, index) => Container(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.neutral200, width: 1),
          ),
        ),
        child: const PaymentListItemSkeleton(),
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Erro ao carregar pagamentos',
              style: AppTypography.bodySemibold,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style:
                  AppTypography.caption.copyWith(color: AppColors.neutral400),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () =>
                  ref.read(paymentsListProvider.notifier).refresh(),
              style:
                  FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoaded(PaymentsListLoaded state) {
    if (state.payments.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => ref.read(paymentsListProvider.notifier).refresh(),
        child: ListView(
          children: [
            const SizedBox(height: AppSpacing.xxl),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(paymentsListProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: state.payments.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.payments.length) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final payment = state.payments[index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(
                bottom:
                    BorderSide(color: AppColors.neutral200, width: 1),
              ),
            ),
            child: PaymentListItemWidget(payment: payment),
          );
        },
      ),
    );
  }
}

// ─── Filter Chips Row ─────────────────────────────────────────

class _FilterChipsRow extends StatelessWidget {
  final String? selectedMethod;
  final ValueChanged<String?> onMethodChanged;

  const _FilterChipsRow({
    required this.selectedMethod,
    required this.onMethodChanged,
  });

  static const _methods = {
    'pix': 'Pix',
    'credit': 'Crédito',
    'debit': 'Débito',
    'cash': 'Dinheiro',
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'Todos',
            selected: selectedMethod == null,
            onTap: () => onMethodChanged(null),
          ),
          ..._methods.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xs),
              child: _FilterChip(
                label: e.value,
                selected: selectedMethod == e.key,
                onTap: () => onMethodChanged(
                    selectedMethod == e.key ? null : e.key),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.neutral200,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: selected ? Colors.white : AppColors.neutral600,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
