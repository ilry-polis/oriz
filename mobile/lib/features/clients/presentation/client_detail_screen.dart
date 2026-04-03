import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../data/client_repository.dart';
import '../domain/client_model.dart';
import '../providers/client_provider.dart';
import 'widgets/tag_chip.dart';

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
    _tabController = TabController(length: 3, vsync: this);
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
          title: Text(client.name),
          actions: [
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') context.push('/clients/${client.id}/edit');
                if (v == 'delete') _anonymize();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: 'edit', child: Text('Editar cliente')),
                const PopupMenuItem(
                  value: 'delete',
                  child:
                      Text('Excluir cliente', style: TextStyle(color: AppColors.error)),
                ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (client.phone != null)
                    Text(client.phone!,
                        style: const TextStyle(color: AppColors.neutral600)),
                  if (client.email != null)
                    Text(client.email!,
                        style: const TextStyle(
                            color: AppColors.neutral600, fontSize: 13)),
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
            // Tabs
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Histórico'),
                Tab(text: 'Anamnese'),
                Tab(text: 'Notas'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _HistoricoTab(clientId: widget.clientId),
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
