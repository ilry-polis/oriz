import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/http/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../onboarding/data/onboarding_repository.dart';
import '../onboarding/presentation/widgets/day_hours_card.dart';

const _dayKeys = [
  'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday',
];
const _dayLabels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab', 'Dom'];

class _DayState {
  bool enabled;
  List<TimeRange> ranges;

  _DayState({required this.enabled, required this.ranges});
}

class WorkingHoursScreen extends ConsumerStatefulWidget {
  final String? professionalId;

  const WorkingHoursScreen({super.key, this.professionalId});

  @override
  ConsumerState<WorkingHoursScreen> createState() => _WorkingHoursScreenState();
}

class _WorkingHoursScreenState extends ConsumerState<WorkingHoursScreen> {
  late List<_DayState> _days;
  List<_DayState>? _original;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  String? _professionalId;

  @override
  void initState() {
    super.initState();
    _days = List.generate(7, (i) {
      final isSunday = i == 6;
      return _DayState(
        enabled: !isSunday,
        ranges: isSunday ? [] : [const TimeRange(open: '09:00', close: '18:00')],
      );
    });
    _loadHours();
  }

  Future<void> _loadHours() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      // Load from current professional's working_hours
      // Until 03-04 provides a /professionals/me endpoint, we read from
      // onboarding's getMyStudio which returns the professionalId.
      final repo = ref.read(onboardingRepositoryProvider);
      final info = await repo.getMyStudio();
      if (info != null) {
        _professionalId = widget.professionalId ?? info.professionalId;
      }
      // working_hours pre-loading from API deferred until professionals/me endpoint
      // is fully available. Default hours from initState are used as fallback.
      setState(() { _isLoading = false; });
      _snapshot();
    } on ApiException catch (e) {
      setState(() { _isLoading = false; _error = e.message; });
    } on Exception catch (e) {
      setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  /// Take a snapshot of current state to detect changes.
  void _snapshot() {
    _original = _days.map((d) => _DayState(enabled: d.enabled, ranges: List.of(d.ranges))).toList();
  }

  bool get _hasChanges {
    if (_original == null) return false;
    for (var i = 0; i < 7; i++) {
      if (_days[i].enabled != _original![i].enabled) return true;
      if (_days[i].ranges.length != _original![i].ranges.length) return true;
      for (var j = 0; j < _days[i].ranges.length; j++) {
        final a = _days[i].ranges[j];
        final b = _original![i].ranges[j];
        if (a.open != b.open || a.close != b.close) return true;
      }
    }
    return false;
  }

  Map<String, List<Map<String, String>>> _buildPayload() {
    final result = <String, List<Map<String, String>>>{};
    for (var i = 0; i < 7; i++) {
      result[_dayKeys[i]] = _days[i].enabled
          ? _days[i].ranges.map((r) => {'open': r.open, 'close': r.close}).toList()
          : [];
    }
    return result;
  }

  String? _validate() {
    for (var i = 0; i < 7; i++) {
      if (!_days[i].enabled) continue;
      for (final range in _days[i].ranges) {
        if (range.open.compareTo(range.close) >= 0) {
          return 'Horario de abertura deve ser anterior ao fechamento (${_dayLabels[i]})';
        }
      }
    }
    return null;
  }

  Future<void> _save() async {
    final err = _validate();
    if (err != null) {
      setState(() => _error = err);
      return;
    }

    final profId = _professionalId;
    if (profId == null || profId.isEmpty || profId == 'current') {
      setState(() => _error = 'ID do profissional nao disponivel. Tente novamente.');
      return;
    }

    setState(() { _isSaving = true; _error = null; });
    try {
      final repo = ref.read(onboardingRepositoryProvider);
      await repo.updateWorkingHours(profId, _buildPayload());
      _snapshot();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Horarios atualizados!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          ),
        );
        setState(() { _isSaving = false; });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() { _isSaving = false; _error = e.message; });
    } on Exception catch (e) {
      if (mounted) setState(() { _isSaving = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu horario', style: AppTypography.title),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.neutral900,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.neutral200),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 100),
          children: [
            Text(
              'Configure os dias e horarios que voce trabalha. Os agendamentos serao limitados a esses periodos.',
              style: AppTypography.body.copyWith(color: AppColors.neutral600),
            ),
            const SizedBox(height: AppSpacing.lg),

            ...List.generate(7, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: DayHoursCard(
                  dayLabel: _dayLabels[i],
                  enabled: _days[i].enabled,
                  ranges: _days[i].ranges,
                  onChanged: (enabled, ranges) {
                    setState(() {
                      _days[i] = _DayState(enabled: enabled, ranges: ranges);
                      _error = null;
                    });
                  },
                ),
              );
            }),

            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_error!, style: AppTypography.caption.copyWith(color: AppColors.error)),
            ],
          ],
        ),

        // Sticky save button
        Positioned(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: AppSpacing.lg,
          child: AnimatedOpacity(
            opacity: _hasChanges ? 1.0 : 0.5,
            duration: const Duration(milliseconds: 200),
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: (_hasChanges && !_isSaving) ? _save : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text('Salvar', style: AppTypography.bodySemibold.copyWith(color: Colors.white)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
