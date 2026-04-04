import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/http/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/agenda_provider.dart';
import '../../../core/utils/phone_formatter.dart';
import '../repositories/appointment_repository.dart';

/// Bottom sheet for booking a new appointment.
///
/// Entry points:
/// 1. Tap on empty timeline slot → pre-fills [initialHour] and [initialMinute]
/// 2. [+] button in header → no pre-filled time (null)
class QuickBookSheet extends ConsumerStatefulWidget {
  final DateTime date;
  final String professionalId;
  final String? professionalName;
  final int? initialHour;
  final int? initialMinute;

  const QuickBookSheet({
    super.key,
    required this.date,
    required this.professionalId,
    this.professionalName,
    this.initialHour,
    this.initialMinute,
  });

  static Future<void> show(
    BuildContext context, {
    required DateTime date,
    required String professionalId,
    String? professionalName,
    int? hour,
    int? minute,
  }) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => QuickBookSheet(
        date: date,
        professionalId: professionalId,
        professionalName: professionalName,
        initialHour: hour,
        initialMinute: minute,
      ),
    );
  }

  @override
  ConsumerState<QuickBookSheet> createState() => _QuickBookSheetState();
}

class _QuickBookSheetState extends ConsumerState<QuickBookSheet> {
  // ─── Client search ───────────────────────────────────────────────────────
  final _clientController = TextEditingController();
  Timer? _debounce;
  List<ClientSearchResult> _clientResults = [];
  bool _searchingClients = false;
  ClientSearchResult? _selectedClient;

  // Quick create client
  bool _showNewClientForm = false;
  final _newClientNameController = TextEditingController();
  final _newClientPhoneController = TextEditingController();
  bool _creatingClient = false;

  // ─── Service selection ───────────────────────────────────────────────────
  List<ServiceOption> _services = [];
  bool _loadingServices = true;
  ServiceOption? _selectedService;

  // ─── Time selection ──────────────────────────────────────────────────────
  int? _selectedHour;
  int? _selectedMinute;
  List<AvailableSlot> _slots = [];
  bool _loadingSlots = false;
  bool _slotConflict = false;

  // ─── Notes ───────────────────────────────────────────────────────────────
  bool _showNotes = false;
  final _notesController = TextEditingController();

  // ─── Submission ──────────────────────────────────────────────────────────
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selectedHour = widget.initialHour;
    _selectedMinute = widget.initialMinute ?? 0;
    _loadServices();
  }

  @override
  void dispose() {
    _clientController.dispose();
    _debounce?.cancel();
    _newClientNameController.dispose();
    _newClientPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  String get _dateStr {
    final y = widget.date.year;
    final m = widget.date.month.toString().padLeft(2, '0');
    final d = widget.date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String? get _selectedTimeStr {
    if (_selectedHour == null) return null;
    final h = _selectedHour!.toString().padLeft(2, '0');
    final m = (_selectedMinute ?? 0).toString().padLeft(2, '0');
    return '$h:$m';
  }

  bool get _canSubmit =>
      _selectedClient != null &&
      _selectedService != null &&
      _selectedHour != null &&
      !_submitting &&
      !_slotConflict;

  // ─── Data loading ─────────────────────────────────────────────────────────

  Future<void> _loadServices() async {
    try {
      final repo = ref.read(appointmentRepositoryProvider);
      final services =
          await repo.getServicesForProfessional(widget.professionalId);
      if (mounted) setState(() => _services = services);
    } catch (_) {
      // ignore — show empty list
    } finally {
      if (mounted) setState(() => _loadingServices = false);
    }
  }

  Future<void> _loadAvailableSlots() async {
    final service = _selectedService;
    if (service == null) return;
    setState(() {
      _loadingSlots = true;
      _slotConflict = false;
    });
    try {
      final repo = ref.read(appointmentRepositoryProvider);
      final slots = await repo.getAvailableSlots(
        date: _dateStr,
        professionalId: widget.professionalId,
        serviceId: service.id,
      );
      if (mounted) {
        setState(() {
          _slots = slots;
          // If pre-selected time, validate against slots
          if (_selectedHour != null) {
            _validateSelectedTime();
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _slots = []);
    } finally {
      if (mounted) setState(() => _loadingSlots = false);
    }
  }

  void _validateSelectedTime() {
    if (_selectedHour == null) return;
    final selectedStr = _selectedTimeStr;
    if (selectedStr == null) return;

    // Check if selected time is in the available slots list
    final matchingSlot = _slots.where(
      (s) {
        final h = s.startTime.hour.toString().padLeft(2, '0');
        final m = s.startTime.minute.toString().padLeft(2, '0');
        return '$h:$m' == selectedStr;
      },
    ).firstOrNull;

    setState(() {
      _slotConflict = matchingSlot != null && !matchingSlot.available;
    });
  }

  void _onClientSearch(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _clientResults = [];
        _searchingClients = false;
      });
      return;
    }
    setState(() => _searchingClients = true);
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final repo = ref.read(appointmentRepositoryProvider);
        final results = await repo.searchClients(query);
        if (mounted) setState(() => _clientResults = results);
      } catch (_) {
        if (mounted) setState(() => _clientResults = []);
      } finally {
        if (mounted) setState(() => _searchingClients = false);
      }
    });
  }

  void _selectClient(ClientSearchResult client) {
    setState(() {
      _selectedClient = client;
      _clientResults = [];
      _showNewClientForm = false;
      _clientController.text = client.name;
    });
    FocusScope.of(context).unfocus();
    HapticFeedback.selectionClick();
  }

  Future<void> _createAndSelectClient() async {
    final name = _newClientNameController.text.trim();
    final phone = stripPhoneMask(_newClientPhoneController.text);
    if (name.isEmpty || phone.isEmpty) return;

    setState(() => _creatingClient = true);
    try {
      final repo = ref.read(appointmentRepositoryProvider);
      final client = await repo.createClient(name: name, phone: phone);
      _selectClient(client);
      setState(() => _showNewClientForm = false);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _creatingClient = false);
    }
  }

  void _selectService(ServiceOption service) {
    setState(() {
      _selectedService = service;
      _slots = [];
    });
    HapticFeedback.selectionClick();
    _loadAvailableSlots();
  }

  void _selectSlot(AvailableSlot slot) {
    if (!slot.available) return;
    setState(() {
      _selectedHour = slot.startTime.hour;
      _selectedMinute = slot.startTime.minute;
      _slotConflict = false;
    });
    HapticFeedback.selectionClick();
  }

  Future<void> _openTimePicker() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _selectedHour ?? 9,
        minute: _selectedMinute ?? 0,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedHour = picked.hour;
        _selectedMinute = picked.minute;
      });
      _validateSelectedTime();
    }
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    HapticFeedback.mediumImpact();
    setState(() => _submitting = true);
    try {
      await ref.read(agendaNotifierProvider.notifier).createAppointment(
            clientId: _selectedClient!.id,
            professionalId: widget.professionalId,
            serviceId: _selectedService!.id,
            date: _dateStr,
            startTime: _selectedTimeStr!,
            notes: _showNotes ? _notesController.text.trim() : null,
          );
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      final isConflict = e.code == 'TIME_SLOT_TAKEN';
      if (isConflict) {
        setState(() => _slotConflict = true);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isConflict
                ? 'Horario ja ocupado, selecione outro.'
                : e.message,
          ),
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
              _buildHandle(),
              _buildHeader(),
              const Divider(color: AppColors.neutral200, height: 1),
              _buildClientSection(),
              _buildServiceSection(),
              _buildTimeSection(),
              _buildNotesSection(),
              _buildConfirmButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.only(top: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.neutral300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final hasTime = _selectedHour != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          if (hasTime)
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
                _selectedTimeStr!,
                style: AppTypography.bodySemibold
                    .copyWith(color: AppColors.primary),
              ),
            ),
          if (hasTime) const SizedBox(width: AppSpacing.sm),
          Text('Novo agendamento', style: AppTypography.title),
        ],
      ),
    );
  }

  Widget _buildClientSection() {
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
            'Cliente',
            style:
                AppTypography.caption.copyWith(color: AppColors.neutral600),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: _clientController,
            decoration: InputDecoration(
              hintText: 'Buscar cliente...',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.neutral400,
                size: 20,
              ),
              suffixIcon: _searchingClients
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : _selectedClient != null
                      ? IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: AppColors.neutral400,
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedClient = null;
                              _clientController.clear();
                              _clientResults = [];
                            });
                          },
                        )
                      : null,
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
            onChanged: _onClientSearch,
            readOnly: _selectedClient != null,
          ),
          if (_clientResults.isNotEmpty || _showNewClientForm) ...[
            const SizedBox(height: AppSpacing.xs),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.neutral200),
                borderRadius: BorderRadius.circular(AppRadius.md),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ..._clientResults.map(
                    (c) => ListTile(
                      title: Text(c.name, style: AppTypography.body),
                      subtitle: c.phone != null
                          ? Text(
                              c.phone!,
                              style: AppTypography.caption,
                            )
                          : null,
                      dense: true,
                      onTap: () => _selectClient(c),
                    ),
                  ),
                  if (_showNewClientForm)
                    _buildNewClientForm()
                  else
                    ListTile(
                      leading: const Icon(
                        Icons.add_circle_outline_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      title: Text(
                        '+ Novo cliente',
                        style: AppTypography.body
                            .copyWith(color: AppColors.primary),
                      ),
                      dense: true,
                      onTap: () {
                        setState(() => _showNewClientForm = true);
                      },
                    ),
                ],
              ),
            ),
          ],
          if (_clientResults.isEmpty &&
              !_showNewClientForm &&
              _selectedClient == null &&
              _clientController.text.isNotEmpty &&
              !_searchingClients) ...[
            const SizedBox(height: AppSpacing.xs),
            GestureDetector(
              onTap: () => setState(() => _showNewClientForm = true),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.neutral200),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.add_circle_outline_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '+ Novo cliente',
                      style:
                          AppTypography.body.copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNewClientForm() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Novo cliente',
            style: AppTypography.caption.copyWith(
              color: AppColors.neutral600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: _newClientNameController,
            decoration: _inputDecoration('Nome'),
            autofocus: true,
          ),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: _newClientPhoneController,
            decoration: _inputDecoration('(00) 00000-0000'),
            keyboardType: TextInputType.phone,
            inputFormatters: [BrazilPhoneFormatter()],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              TextButton(
                onPressed: () => setState(() => _showNewClientForm = false),
                child: Text(
                  'Cancelar',
                  style:
                      AppTypography.caption.copyWith(color: AppColors.neutral600),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: _creatingClient ? null : _createAndSelectClient,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      textStyle: AppTypography.caption,
                    ),
                    child: _creatingClient
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Adicionar'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceSection() {
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
            'Servico',
            style:
                AppTypography.caption.copyWith(color: AppColors.neutral600),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (_loadingServices)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            )
          else if (_services.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                'Nenhum servico disponivel',
                style: AppTypography.caption,
              ),
            )
          else
            ...List.generate(_services.length, (i) {
              final service = _services[i];
              final selected = _selectedService?.id == service.id;
              return GestureDetector(
                onTap: () => _selectService(service),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : AppColors.neutral100,
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : AppColors.neutral200,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          service.name,
                          style: AppTypography.body.copyWith(
                            color: selected
                                ? Colors.white
                                : AppColors.neutral900,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      Text(
                        '${service.durationMinutes}min',
                        style: AppTypography.caption.copyWith(
                          color:
                              selected ? Colors.white70 : AppColors.neutral400,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        service.formattedPrice,
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
        ],
      ),
    );
  }

  Widget _buildTimeSection() {
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
            'Horario',
            style:
                AppTypography.caption.copyWith(color: AppColors.neutral600),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (_selectedService != null) ...[
            if (_loadingSlots)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              )
            else if (_slots.isNotEmpty) ...[
              Text(
                'Horarios disponiveis',
                style: AppTypography.caption.copyWith(
                  color: AppColors.neutral600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _slots.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.xs),
                  itemBuilder: (_, i) {
                    final slot = _slots[i];
                    final isSelected = _selectedHour == slot.startTime.hour &&
                        _selectedMinute == slot.startTime.minute;
                    return GestureDetector(
                      onTap: slot.available ? () => _selectSlot(slot) : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : slot.available
                                  ? AppColors.neutral100
                                  : AppColors.neutral200.withValues(alpha: 0.5),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : slot.available
                                    ? AppColors.neutral200
                                    : AppColors.neutral300,
                          ),
                          borderRadius:
                              BorderRadius.circular(AppRadius.full),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          slot.label,
                          style: AppTypography.caption.copyWith(
                            color: isSelected
                                ? Colors.white
                                : slot.available
                                    ? AppColors.neutral900
                                    : AppColors.neutral400,
                            fontWeight: isSelected ? FontWeight.w600 : null,
                            decoration: slot.available
                                ? null
                                : TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
          ],
          // Current selection or picker
          GestureDetector(
            onTap: _openTimePicker,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                border: Border.all(
                  color: _slotConflict
                      ? AppColors.error
                      : AppColors.neutral200,
                ),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 18,
                    color: _slotConflict
                        ? AppColors.error
                        : AppColors.neutral400,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    _selectedTimeStr ?? 'Selecionar horario',
                    style: AppTypography.body.copyWith(
                      color: _selectedTimeStr == null
                          ? AppColors.neutral400
                          : _slotConflict
                              ? AppColors.error
                              : AppColors.neutral900,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.neutral400,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_slotConflict)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Horario indisponivel',
                style: AppTypography.caption.copyWith(color: AppColors.error),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
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
          if (!_showNotes)
            GestureDetector(
              onTap: () => setState(() => _showNotes = true),
              child: Text(
                '+ Adicionar observacao',
                style: AppTypography.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: 'Observacoes (opcional)',
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
                contentPadding: const EdgeInsets.all(AppSpacing.sm),
              ),
              maxLines: 3,
              style: AppTypography.body,
            ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: _canSubmit ? _submit : null,
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
          child: _submitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Agendar'),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.neutral100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.neutral200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.neutral200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 8,
      ),
      isDense: true,
    );
  }
}
