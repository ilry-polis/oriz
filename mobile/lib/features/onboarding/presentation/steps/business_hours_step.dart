import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../providers/onboarding_provider.dart';
import '../widgets/day_hours_card.dart';

const _dayKeys = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
const _dayLabels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab', 'Dom'];

class _DayState {
  bool enabled;
  List<TimeRange> ranges;

  _DayState({required this.enabled, required this.ranges});
}

class BusinessHoursStep extends ConsumerStatefulWidget {
  const BusinessHoursStep({super.key});

  @override
  ConsumerState<BusinessHoursStep> createState() => _BusinessHoursStepState();
}

class _BusinessHoursStepState extends ConsumerState<BusinessHoursStep> {
  late final List<_DayState> _days;

  @override
  void initState() {
    super.initState();
    _days = List.generate(7, (i) {
      final isSunday = i == 6;
      return _DayState(
        enabled: !isSunday,
        ranges: isSunday
            ? []
            : [const TimeRange(open: '09:00', close: '18:00')],
      );
    });
  }

  Map<String, List<Map<String, String>>> _buildHoursPayload() {
    final result = <String, List<Map<String, String>>>{};
    for (var i = 0; i < 7; i++) {
      result[_dayKeys[i]] = _days[i].enabled
          ? _days[i].ranges.map((r) => {'open': r.open, 'close': r.close}).toList()
          : [];
    }
    return result;
  }

  Future<void> _submit() async {
    await ref.read(onboardingNotifierProvider.notifier).setBusinessHours(
          _buildHoursPayload(),
        );
  }

  Future<void> _skip() async {
    await ref.read(onboardingNotifierProvider.notifier).skipBusinessHours();
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingNotifierProvider);
    final isSaving = onboardingState is OnboardingStep && onboardingState.isSaving;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.lg),
          Text('Horarios', style: AppTypography.title, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xs),
          Text('Passo 3 de 3', style: AppTypography.caption, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xl),

          ...List.generate(7, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: DayHoursCard(
                dayLabel: _dayLabels[i],
                enabled: _days[i].enabled,
                ranges: _days[i].ranges,
                onChanged: (enabled, ranges) {
                  setState(() {
                    _days[i].enabled = enabled;
                    _days[i].ranges = ranges.isEmpty && enabled
                        ? [const TimeRange(open: '09:00', close: '18:00')]
                        : ranges;
                  });
                },
              ),
            );
          }),

          const SizedBox(height: AppSpacing.lg),

          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: isSaving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primary.withAlpha(102),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accent,
                      ),
                    )
                  : Text('Concluir',
                      style: AppTypography.bodySemibold.copyWith(color: Colors.white)),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          Center(
            child: TextButton(
              onPressed: isSaving ? null : _skip,
              style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
              child: Text(
                'Pular por agora',
                style: AppTypography.caption.copyWith(color: AppColors.neutral600),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
