import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../data/client_repository.dart';
import '../domain/client_model.dart';
import '../providers/client_provider.dart';
import 'widgets/tag_chip.dart';
import '../../packages/models/package_subscription_model.dart';
import '../../packages/repositories/package_repository.dart';
import '../../packages/widgets/sell_package_sheet.dart';

String _formatPhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  // Remove country code 55 if present
  final local = digits.startsWith('55') && digits.length > 11
      ? digits.substring(2)
      : digits;
  if (local.length == 11) {
    return '(${local.substring(0, 2)}) ${local.substring(2, 7)}-${local.substring(7)}';
  }
  if (local.length == 10) {
    return '(${local.substring(0, 2)}) ${local.substring(2, 6)}-${local.substring(6)}';
  }
  return phone;
}

String _whatsappUrl(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  final withCountry = digits.startsWith('55') ? digits : '55$digits';
  return 'https://wa.me/$withCountry';
}

class ClientDetailScreen extends ConsumerStatefulWidget {
  final String clientId;
  const ClientDetailScreen({super.key, required this.clientId});

  @override
  ConsumerState<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends ConsumerState<ClientDetailScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  final _noteController = TextEditingController();
  List<ClientNote> _notes = [];
  bool _loadingNotes = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadNotes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    try {
      final repo = ref.read(clientRepositoryProvider);
      final response = await repo.listNotes(widget.clientId);
      final data = (response['data'] as List?)
              ?.map((e) => ClientNote.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      if (mounted) {
        setState(() {
          _notes = data;
          _loadingNotes = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingNotes = false);
    }
  }

  Future<void> _addNote() async {
    final content = _noteController.text.trim();
    if (content.isEmpty) return;

    try {
      final repo = ref.read(clientRepositoryProvider);
      final note = await repo.createNote(widget.clientId, content);
      if (mounted) {
        setState(() {
          _notes.insert(0, note);
          _noteController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  void _showActions(ClientModel client) {
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
            _actionItem(ctx, Icons.edit_outlined, 'Editar cliente', onTap: () {
              Navigator.pop(ctx);
              context.push('/clients/${client.id}/edit');
            }),
            _actionItem(
              ctx,
              isVip ? Icons.star_rounded : Icons.star_outline_rounded,
              isVip ? 'Remover VIP' : 'Marcar como VIP',
              color: isVip ? AppColors.accent : null,
              onTap: () {
                Navigator.pop(ctx);
                _toggleVip(client);
              },
            ),
            _actionItem(
              ctx,
              Icons.delete_outline,
              'Excluir cliente',
              color: AppColors.error,
              onTap: () {
                Navigator.pop(ctx);
                _anonymize();
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  Widget _actionItem(
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

  Future<void> _toggleVip(ClientModel client) async {
    final isVip = client.tags.contains('vip');
    final newTags = isVip
        ? client.tags.where((t) => t != 'vip').toList()
        : [...client.tags, 'vip'];
    try {
      final repo = ref.read(clientRepositoryProvider);
      await repo.updateTags(client.id, newTags);
      ref.invalidate(clientDetailProvider(widget.clientId));
      ref.read(clientListProvider.notifier).refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isVip ? 'VIP removido' : 'Marcado como VIP'),
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

  Future<void> _anonymize() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Anonimizar cliente'),
        content: const Text(
          'Esta ação é irreversível. Os dados pessoais serão anonimizados permanentemente. O histórico de agendamentos será mantido.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Anonimizar',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ref.read(clientRepositoryProvider).anonymize(widget.clientId);
      ref.read(clientListProvider.notifier).refresh();
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientAsync = ref.watch(clientDetailProvider(widget.clientId));

    return clientAsync.when(
      loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: Center(child: Text('Erro: $e'))),
      data: (client) => Scaffold(
        appBar: AppBar(
          title: const Text('Cliente'),
          actions: [
            GestureDetector(
              onTap: () => _showActions(client),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.more_horiz_rounded,
                  color: AppColors.neutral400,
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Header with profile avatar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile photo / initials avatar
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.neutral200,
                    child: Text(
                      client.initials,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutral600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.neutral900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (client.phone != null)
                          Row(
                            children: [
                              Text(
                                _formatPhone(client.phone!),
                                style: const TextStyle(
                                    color: AppColors.neutral600, fontSize: 14),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              GestureDetector(
                                onTap: () async {
                                  HapticFeedback.lightImpact();
                                  final uri =
                                      Uri.parse(_whatsappUrl(client.phone!));
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri,
                                        mode: LaunchMode.externalApplication);
                                  }
                                },
                                child: const FaIcon(
                                  FontAwesomeIcons.whatsapp,
                                  color: Color(0xFF25D366),
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        if (client.email != null)
                          Text(client.email!,
                              style: const TextStyle(
                                  color: AppColors.neutral400, fontSize: 13)),
                        if (client.allTags.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Wrap(
                              spacing: 6,
                              children: client.allTags
                                  .map((t) => TagChip(
                                        label: t,
                                        readOnly: client.autoTags.contains(t),
                                      ))
                                  .toList(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Tabs
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Histórico'),
                Tab(text: 'Pacotes'),
                Tab(text: 'Anamnese'),
                Tab(text: 'Notas'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _HistoricoTab(clientId: widget.clientId),
                  _PacotesTab(
                    clientId: widget.clientId,
                    clientName: client.name,
                  ),
                  _AnamneseTab(clientId: widget.clientId),
                  _NotasTab(
                    notes: _notes,
                    loading: _loadingNotes,
                    controller: _noteController,
                    onSubmit: _addNote,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoricoTab extends ConsumerWidget {
  final String clientId;
  const _HistoricoTab({required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ref.read(clientRepositoryProvider).listAppointments(clientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = (snapshot.data?['data'] as List?) ?? [];
        if (data.isEmpty) {
          return const Center(
            child: Text('Nenhum agendamento ainda',
                style: TextStyle(color: AppColors.neutral400)),
          );
        }
        return ListView.builder(
          itemCount: data.length,
          itemBuilder: (_, i) {
            final appt = AppointmentHistory.fromJson(
                data[i] as Map<String, dynamic>);
            return ListTile(
              title: Text(appt.serviceName),
              subtitle: Text(appt.professionalName),
              trailing: Text(appt.status,
                  style: const TextStyle(fontSize: 12)),
            );
          },
        );
      },
    );
  }
}

// ─── Pacotes Tab ─────────────────────────────────────────────────────────────

class _PacotesTab extends ConsumerStatefulWidget {
  final String clientId;
  final String clientName;

  const _PacotesTab({required this.clientId, required this.clientName});

  @override
  ConsumerState<_PacotesTab> createState() => _PacotesTabState();
}

class _PacotesTabState extends ConsumerState<_PacotesTab> {
  List<PackageSubscriptionModel> _subscriptions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(packageRepositoryProvider);
      final result =
          await repo.listSubscriptions(clientId: widget.clientId, limit: 50);
      if (mounted) {
        setState(() {
          _subscriptions = result.items;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _sellPackage() async {
    final sold = await SellPackageSheet.show(
      context,
      clientId: widget.clientId,
      clientName: widget.clientName,
    );
    if (sold == true) {
      await _loadSubscriptions();
    }
  }

  Future<void> _extendExpiry(PackageSubscriptionModel sub) async {
    final now = DateTime.now();
    final initialDate = sub.expiresAt.isAfter(now) ? sub.expiresAt : now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked == null || !mounted) return;
    try {
      final repo = ref.read(packageRepositoryProvider);
      await repo.extendExpiry(
        subscriptionId: sub.id,
        newExpiresAt: picked,
      );
      await _loadSubscriptions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Validade estendida'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: AppTypography.caption),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: _loadSubscriptions,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Sell button header
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pacotes ativos',
                style:
                    AppTypography.bodySemibold,
              ),
              TextButton.icon(
                onPressed: _sellPackage,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Vender pacote'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  textStyle: AppTypography.caption
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _subscriptions.isEmpty
              ? Center(
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
                        'Nenhum pacote ativo',
                        style: AppTypography.body
                            .copyWith(color: AppColors.neutral600),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextButton(
                        onPressed: _sellPackage,
                        child: const Text('Vender pacote'),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  itemCount: _subscriptions.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.xs),
                  itemBuilder: (_, i) {
                    final sub = _subscriptions[i];
                    return _SubscriptionCard(
                      subscription: sub,
                      onExtend: () => _extendExpiry(sub),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  final PackageSubscriptionModel subscription;
  final VoidCallback onExtend;

  const _SubscriptionCard({
    required this.subscription,
    required this.onExtend,
  });

  @override
  Widget build(BuildContext context) {
    final sub = subscription;
    final isExpired = sub.isExpired;
    final isActive = sub.isActive;

    Color statusColor;
    String statusLabel;
    if (sub.status == SubscriptionStatus.depleted) {
      statusColor = AppColors.neutral400;
      statusLabel = 'Esgotado';
    } else if (isExpired) {
      statusColor = AppColors.error;
      statusLabel = 'Expirado';
    } else if (isActive) {
      statusColor = AppColors.success;
      statusLabel = 'Ativo';
    } else {
      statusColor = AppColors.neutral400;
      statusLabel = sub.statusLabel;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        border: Border.all(
          color: isExpired ? AppColors.errorSoft : AppColors.neutral200,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  sub.packageName ?? 'Pacote',
                  style: AppTypography.bodySemibold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  statusLabel,
                  style: AppTypography.micro.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          // Progress bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: LinearProgressIndicator(
                    value: sub.progressFraction,
                    backgroundColor: AppColors.neutral200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isExpired ? AppColors.neutral400 : AppColors.primary,
                    ),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${sub.sessionsUsed}/${sub.sessionsTotal}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.neutral600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Expira: ${sub.formattedExpiry}',
                style: AppTypography.micro.copyWith(
                  color: isExpired ? AppColors.error : AppColors.neutral400,
                ),
              ),
              if (isExpired)
                GestureDetector(
                  onTap: onExtend,
                  child: Text(
                    'Estender validade',
                    style: AppTypography.micro.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Anamnese Tab ──────────────────────────────────────────────────────────────

class _AnamneseTab extends StatelessWidget {
  final String clientId;
  const _AnamneseTab({required this.clientId});

  static const _categories = ['lash', 'micropig', 'unhas', 'estetica', 'cabelo'];
  static const _labels = {
    'lash': 'Cílios / Lash',
    'micropig': 'Micropigmentação',
    'unhas': 'Unhas',
    'estetica': 'Estética',
    'cabelo': 'Cabelo',
  };

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: _categories.map((cat) {
        return ListTile(
          title: Text(_labels[cat] ?? cat),
          trailing: const Icon(Icons.chevron_right, color: AppColors.neutral300),
          onTap: () => context.push('/clients/$clientId/anamnesis/$cat'),
        );
      }).toList(),
    );
  }
}

class _NotasTab extends StatelessWidget {
  final List<ClientNote> notes;
  final bool loading;
  final TextEditingController controller;
  final VoidCallback onSubmit;

  const _NotasTab({
    required this.notes,
    required this.loading,
    required this.controller,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : notes.isEmpty
                  ? const Center(
                      child: Text('Nenhuma nota',
                          style: TextStyle(color: AppColors.neutral400)))
                  : ListView.builder(
                      itemCount: notes.length,
                      itemBuilder: (_, i) {
                        final note = notes[i];
                        return ListTile(
                          title: Text(note.content),
                          subtitle: Text(
                            note.createdAt,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.neutral400),
                          ),
                        );
                      },
                    ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.neutral200)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'Adicionar nota...',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send, color: AppColors.primary),
                onPressed: onSubmit,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
