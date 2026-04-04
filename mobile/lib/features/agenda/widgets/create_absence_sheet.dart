import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/appointment_model.dart';
import '../providers/agenda_provider.dart';

List<String> _buildTimeOptions() {
  final options = <String>[];
  for (var h = 0; h < 24; h++) {
    for (var m = 0; m < 60; m += 15) {
      options.add(
        '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}',
      );
    }
  }
  return options;
}

final _timeOptions = _buildTimeOptions();

/// Bottom sheet for creating sporadic or recurring absences (blocked slots).
class CreateAbsenceSheet extends ConsumerStatefulWidget {
  final DateTime initialDate;
  final String initialStartTime;
  final String initialEndTime;
  final VoidCallback? onCreated;

  const CreateAbsenceSheet({
    super.key,
    required this.initialDate,
    required this.initialStartTime,
    required this.initialEndTime,
    this.onCreated,
  });

  static Future<void> show(
    BuildContext context, {
    required DateTime initialDate,
    required String initialStartTime,
    required String initialEndTime,
    VoidCallback? onCreated,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => CreateAbsenceSheet(
        initialDate: initialDate,
        initialStartTime: initialStartTime,
        initialEndTime: initialEndTime,
        onCreated: onCreated,
      ),
    );
  }

  @override
  ConsumerState<CreateAbsenceSheet> createState() => _CreateAbsenceSheetState();
}

class _CreateAbsenceSheetState extends ConsumerState<CreateAbsenceSheet> {
  final _titleController = TextEditingController();
  late DateTime _date;
  late String _startTime;
  late String _endTime;
  bool _isRecurring = false;
  final Set<int> _recurringDays = {};
  DateTime? _recurringUntil;
  bool _isSaving = false;
  String? _error;

  static const _dayLabels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab', 'Dom'];

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
    _startTime = _timeOptions.contains(widget.initialStartTime)
        ? widget.initialStartTime
        : '09:00';
    _endTime = _timeOptions.contains(widget.initialEndTime)
        ? widget.initialEndTime
        : '10:00';
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    const months = [
      'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
      'jul', 'ago', 'set', 'out', 'nov', 'dez',
    ];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }

  String _toDateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _pickUntilDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _recurringUntil ?? _date.add(const Duration(days: 30)),
      firstDate: _date,
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null && mounted) setState(() => _recurringUntil = picked);
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Informe um titulo para a ausencia');
      return;
    }
    if (_isRecurring && _recurringDays.isEmpty) {
      setState(() => _error = 'Selecione ao menos um dia da semana');
      return;
    }

    setState(() { _isSaving = true; _error = null; });

    try {
      RecurrenceRule? rule;
      if (_isRecurring && _recurringDays.isNotEmpty) {
        rule = RecurrenceRule(
          frequency: 'weekly',
          days: _recurringDays.toList()..sort(),
          until: _recurringUntil,
        );
      }

      final professionalId = ref.read(currentProfessionalIdProvider) ?? '';

      await ref.read(agendaNotifierProvider.notifier).createAbsence(
            professionalId: professionalId,
            date: _toDateStr(_date),
            startTime: _startTime,
            endTime: _endTime,
            title: title,
            recurrenceRule: rule,
          );

      if (mounted) {
        Navigator.pop(context);
        widget.onCreated?.call();
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() { _isSaving = false; _error = e.toString(); });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(color: AppColors.neutral300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text('Nova ausencia', style: AppTypography.title),
              const SizedBox(height: AppSpacing.lg),

              // Title
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Titulo *',
                  hintText: 'Ex: Dentista, Almoco, Reuniao',
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
                ),
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) { if (_error != null) setState(() => _error = null); },
              ),
              const SizedBox(height: AppSpacing.md),

              // Date picker
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.neutral100,
                    border: Border.all(color: AppColors.neutral200),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Data', style: AppTypography.micro.copyWith(color: AppColors.neutral400)),
                          const SizedBox(height: 2),
                          Text(_formatDate(_date), style: AppTypography.body),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.neutral400),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Time range
              Row(
                children: [
                  Expanded(child: _timeDropdown('Inicio', _startTime, (v) => setState(() => _startTime = v))),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: _timeDropdown('Fim', _endTime, (v) => setState(() => _endTime = v))),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Recurring toggle
              Row(
                children: [
                  Text('Recorrente', style: AppTypography.body),
                  const Spacer(),
                  Switch(
                    value: _isRecurring,
                    onChanged: (v) => setState(() { _isRecurring = v; if (!v) _recurringDays.clear(); }),
                    activeColor: AppColors.success,
                  ),
                ],
              ),

              if (_isRecurring) ...[
                const SizedBox(height: AppSpacing.xs),
                Text('Dias da semana', style: AppTypography.caption.copyWith(color: AppColors.neutral600)),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  children: List.generate(7, (i) {
                    final apiDay = i; // 0=Mon..6=Sun
                    final selected = _recurringDays.contains(apiDay);
                    return FilterChip(
                      label: Text(
                        _dayLabels[i],
                        style: AppTypography.caption.copyWith(
                          color: selected ? AppColors.primary : AppColors.neutral600,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      selected: selected,
                      onSelected: (_) => setState(() {
                        if (selected) { _recurringDays.remove(apiDay); }
                        else { _recurringDays.add(apiDay); }
                      }),
                      selectedColor: AppColors.accentSoft,
                      checkmarkColor: AppColors.primary,
                      side: BorderSide(color: selected ? AppColors.accent : AppColors.neutral200),
                    );
                  }),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Text('Data final', style: AppTypography.body),
                    const Spacer(),
                    TextButton(
                      onPressed: _pickUntilDate,
                      child: Text(
                        _recurringUntil != null ? _formatDate(_recurringUntil!) : 'Sem data final',
                        style: AppTypography.body.copyWith(color: AppColors.primary),
                      ),
                    ),
                    if (_recurringUntil != null)
                      GestureDetector(
                        onTap: () => setState(() => _recurringUntil = null),
                        child: const Icon(Icons.close, size: 16, color: AppColors.neutral400),
                      ),
                  ],
                ),
              ],

              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(_error!, style: AppTypography.caption.copyWith(color: AppColors.error)),
              ],

              const SizedBox(height: AppSpacing.lg),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Criar ausencia', style: AppTypography.bodySemibold.copyWith(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timeDropdown(String label, String value, void Function(String) onChanged) {
    return DropdownButtonFormField<String>(
      value: _timeOptions.contains(value) ? value : _timeOptions.first,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.neutral100,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.neutral200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.neutral200),
        ),
      ),
      isExpanded: true,
      items: _timeOptions.map((t) => DropdownMenuItem(value: t, child: Text(t, style: AppTypography.caption))).toList(),
      onChanged: (v) { if (v != null) onChanged(v); },
    );
  }
}
