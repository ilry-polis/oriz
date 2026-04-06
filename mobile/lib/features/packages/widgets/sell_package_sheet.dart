import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/http/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/package_model.dart';
import '../providers/package_provider.dart';
import '../repositories/package_repository.dart';

/// Bottom sheet for selling a package to a specific client.
///
/// Shows all available packages (optionally filtered by [serviceId]).
/// On confirmation, calls createSubscription.
class SellPackageSheet extends ConsumerStatefulWidget {
  final String clientId;
  final String clientName;
  final String? serviceId;

  const SellPackageSheet({
    super.key,
    required this.clientId,
    required this.clientName,
    this.serviceId,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String clientId,
    required String clientName,
    String? serviceId,
  }) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => SellPackageSheet(
        clientId: clientId,
        clientName: clientName,
        serviceId: serviceId,
      ),
    );
  }

  @override
  ConsumerState<SellPackageSheet> createState() => _SellPackageSheetState();
}

class _SellPackageSheetState extends ConsumerState<SellPackageSheet> {
  PackageModel? _selected;
  bool _selling = false;
  String? _error;

  Future<void> _sell() async {
    final pkg = _selected;
    if (pkg == null) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _selling = true;
      _error = null;
    });
    try {
      final repo = ref.read(packageRepositoryProvider);
      await repo.createSubscription(
        packageId: pkg.id,
        clientId: widget.clientId,
      );
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pacote "${pkg.name}" vendido para ${widget.clientName}'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _selling = false;
          _error = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _selling = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(packageProvider);
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
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Vender pacote', style: AppTypography.title),
                  const SizedBox(height: 2),
                  Text(
                    'Para: ${widget.clientName}',
                    style: AppTypography.body
                        .copyWith(color: AppColors.neutral600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(color: AppColors.neutral200, height: 1),

            // Package list
            Flexible(
              child: asyncState.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    'Erro ao carregar pacotes: $e',
                    style: AppTypography.body
                        .copyWith(color: AppColors.neutral600),
                  ),
                ),
                data: (listState) {
                  if (listState is PackageListLoaded) {
                    final packages = widget.serviceId != null
                        ? listState.items
                            .where((p) =>
                                p.serviceIds.contains(widget.serviceId))
                            .toList()
                        : listState.items;

                    if (packages.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.card_giftcard_outlined,
                              size: 40,
                              color: AppColors.neutral300,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Nenhum pacote disponivel',
                              style: AppTypography.body
                                  .copyWith(color: AppColors.neutral600),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      itemCount: packages.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.xs),
                      itemBuilder: (_, i) {
                        final pkg = packages[i];
                        final isSelected = _selected?.id == pkg.id;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selected = pkg);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.accentSoft
                                  : AppColors.neutral100,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.neutral200,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        pkg.name,
                                        style: AppTypography.bodySemibold
                                            .copyWith(
                                          color: isSelected
                                              ? AppColors.primary
                                              : AppColors.neutral900,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${pkg.totalSessions} sessoes · ${pkg.validityLabel}',
                                        style: AppTypography.caption
                                            .copyWith(
                                          color: AppColors.neutral600,
                                        ),
                                      ),
                                      if (pkg.serviceNames.isNotEmpty)
                                        Text(
                                          pkg.serviceLabel,
                                          style: AppTypography.micro.copyWith(
                                            color: AppColors.neutral400,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      pkg.formattedPrice,
                                      style: AppTypography.bodySemibold
                                          .copyWith(
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.neutral900,
                                      ),
                                    ),
                                    if (pkg.totalSessions > 0)
                                      Text(
                                        _pricePerSession(pkg),
                                        style: AppTypography.micro.copyWith(
                                          color: AppColors.neutral400,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Icon(
                                  isSelected
                                      ? Icons.check_circle_rounded
                                      : Icons.circle_outlined,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.neutral300,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),

            // Error
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  _error!,
                  style:
                      AppTypography.caption.copyWith(color: AppColors.error),
                ),
              ),

            // Confirm button
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: (_selected != null && !_selling) ? _sell : null,
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
                  child: _selling
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Confirmar venda'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _pricePerSession(PackageModel pkg) {
    final perSession = pkg.price ~/ pkg.totalSessions;
    final reais = perSession ~/ 100;
    final centavos = perSession % 100;
    return 'R\$ $reais,${centavos.toString().padLeft(2, '0')}/sessao';
  }
}
