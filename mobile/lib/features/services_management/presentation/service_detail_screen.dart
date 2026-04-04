import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../data/service_mgmt_repository.dart';
import '../domain/service_model.dart';
import '../providers/service_mgmt_provider.dart';

class ServiceDetailScreen extends ConsumerStatefulWidget {
  final String serviceId;
  const ServiceDetailScreen({super.key, required this.serviceId});

  @override
  ConsumerState<ServiceDetailScreen> createState() =>
      _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends ConsumerState<ServiceDetailScreen> {
  ServiceModel? _service;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadService();
  }

  Future<void> _loadService() async {
    try {
      final repo = ref.read(serviceMgmtRepositoryProvider);
      final service = await repo.getService(widget.serviceId);
      if (mounted) setState(() { _service = service; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showActions() {
    final service = _service;
    if (service == null) return;
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
            _menuItem(ctx, Icons.edit_outlined, 'Editar serviço', onTap: () {
              Navigator.pop(ctx);
              context.push('/services/${service.id}/edit');
            }),
            _menuItem(
              ctx,
              service.isActive
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              service.isActive ? 'Desativar serviço' : 'Ativar serviço',
              onTap: () {
                Navigator.pop(ctx);
                _toggleActive();
              },
            ),
            _menuItem(
              ctx,
              Icons.delete_outline,
              'Excluir serviço',
              color: AppColors.error,
              onTap: () {
                Navigator.pop(ctx);
                _delete();
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleActive() async {
    final service = _service;
    if (service == null) return;
    try {
      final repo = ref.read(serviceMgmtRepositoryProvider);
      final updated = await repo.toggleActive(service.id, !service.isActive);
      ref.read(serviceMgmtProvider.notifier).refresh();
      if (mounted) {
        setState(() => _service = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updated.isActive ? 'Serviço ativado' : 'Serviço desativado',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Text('Excluir serviço?', style: AppTypography.title),
        content: Text(
          'Tem certeza? Esta ação não pode ser desfeita.',
          style: AppTypography.body.copyWith(color: AppColors.neutral600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Voltar',
              style: AppTypography.body.copyWith(color: AppColors.neutral600),
            ),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.heavyImpact();
              Navigator.pop(ctx, true);
            },
            child: Text(
              'Excluir',
              style: AppTypography.body.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ref
          .read(serviceMgmtRepositoryProvider)
          .deleteService(widget.serviceId);
      ref.read(serviceMgmtProvider.notifier).refresh();
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do serviço'),
        actions: [
          GestureDetector(
            onTap: _showActions,
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(Icons.more_horiz_rounded, color: AppColors.neutral400),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _service == null
              ? Center(
                  child: Text(
                    'Serviço não encontrado',
                    style: AppTypography.body.copyWith(
                      color: AppColors.neutral400,
                    ),
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final service = _service!;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Status badge
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: service.isActive
                    ? AppColors.successSoft
                    : AppColors.neutral100,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                service.isActive ? 'Ativo' : 'Inativo',
                style: AppTypography.micro.copyWith(
                  color: service.isActive
                      ? AppColors.success
                      : AppColors.neutral400,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (service.categoryName != null) ...[
              const SizedBox(width: AppSpacing.sm),
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
                  service.categoryName!,
                  style: AppTypography.micro.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: AppSpacing.lg),

        // Service name
        Text(service.name, style: AppTypography.display),

        const SizedBox(height: AppSpacing.xl),

        // Info cards
        _infoRow(Icons.attach_money_rounded, 'Preço', service.formattedPrice),
        const SizedBox(height: AppSpacing.md),
        _infoRow(Icons.schedule_rounded, 'Duração', service.formattedDuration),
        if (service.bufferMinutes > 0) ...[
          const SizedBox(height: AppSpacing.md),
          _infoRow(
            Icons.hourglass_bottom_rounded,
            'Intervalo',
            '${service.bufferMinutes} min',
          ),
        ],
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        border: Border.all(color: AppColors.neutral200),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.neutral400, size: 22),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: AppColors.neutral400,
                ),
              ),
              const SizedBox(height: 2),
              Text(value, style: AppTypography.bodySemibold),
            ],
          ),
        ],
      ),
    );
  }
}
