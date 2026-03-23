import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class TimeRange {
  final String open;
  final String close;

  const TimeRange({required this.open, required this.close});
}

/// Generates time options from 00:00 to 23:45 in 15-minute increments
List<String> get timeOptions {
  final options = <String>[];
  for (var h = 0; h < 24; h++) {
    for (var m = 0; m < 60; m += 15) {
      options.add('${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}');
    }
  }
  return options;
}

class DayHoursCard extends StatelessWidget {
  final String dayLabel;
  final bool enabled;
  final List<TimeRange> ranges;
  final void Function(bool enabled, List<TimeRange> ranges) onChanged;

  const DayHoursCard({
    super.key,
    required this.dayLabel,
    required this.enabled,
    required this.ranges,
    required this.onChanged,
  });

  void _toggleEnabled() {
    onChanged(!enabled, ranges);
  }

  void _addRange() {
    onChanged(enabled, [...ranges, const TimeRange(open: '09:00', close: '18:00')]);
  }

  void _removeRange(int index) {
    if (ranges.length <= 1) return;
    final updated = [...ranges]..removeAt(index);
    onChanged(enabled, updated);
  }

  void _updateOpen(int index, String value) {
    final updated = [...ranges];
    updated[index] = TimeRange(open: value, close: updated[index].close);
    onChanged(enabled, updated);
  }

  void _updateClose(int index, String value) {
    final updated = [...ranges];
    updated[index] = TimeRange(open: updated[index].open, close: value);
    onChanged(enabled, updated);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: enabled ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.neutral100,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(dayLabel, style: AppTypography.bodySemibold),
                const Spacer(),
                Switch(
                  value: enabled,
                  onChanged: (_) => _toggleEnabled(),
                  activeColor: AppColors.primary,
                ),
              ],
            ),

            if (!enabled)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text('Fechado',
                    style: AppTypography.caption.copyWith(color: AppColors.neutral400)),
              ),

            if (enabled) ...[
              ...List.generate(ranges.length, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child: _TimeDropdown(
                          value: ranges[i].open,
                          onChanged: (v) => _updateOpen(i, v),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                        child: Text('ate', style: AppTypography.caption),
                      ),
                      Expanded(
                        child: _TimeDropdown(
                          value: ranges[i].close,
                          onChanged: (v) => _updateClose(i, v),
                        ),
                      ),
                      if (ranges.length > 1)
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: IconButton(
                            icon: const Icon(Icons.close, size: 16, color: AppColors.neutral400),
                            onPressed: () => _removeRange(i),
                          ),
                        ),
                    ],
                  ),
                );
              }),

              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _addRange,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    foregroundColor: AppColors.primary,
                  ),
                  child: Text('+ Intervalo', style: AppTypography.caption.copyWith(color: AppColors.primary)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimeDropdown extends StatelessWidget {
  final String value;
  final void Function(String) onChanged;

  const _TimeDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final options = timeOptions;
    return DropdownButtonFormField<String>(
      value: options.contains(value) ? value : '09:00',
      isExpanded: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.neutral200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.neutral200),
        ),
      ),
      items: options
          .map((t) => DropdownMenuItem(value: t, child: Text(t, style: AppTypography.caption)))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
