import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class DaySelector extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const DaySelector({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  State<DaySelector> createState() => _DaySelectorState();
}

class _DaySelectorState extends State<DaySelector> {
  static const _dayLabels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

  /// Total weeks to generate (past + future). Center = today's week.
  static const _totalWeeks = 104; // ~2 years
  static const _centerIndex = _totalWeeks ~/ 2;

  late final PageController _pageController;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = _pageIndexForDate(widget.selectedDate);
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void didUpdateWidget(DaySelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    final targetPage = _pageIndexForDate(widget.selectedDate);
    if (targetPage != _currentPage) {
      _currentPage = targetPage;
      _pageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Monday of the reference week (today's week).
  DateTime get _referenceMonday {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
  }

  /// Convert a date to its page index.
  int _pageIndexForDate(DateTime date) {
    final refMonday = _referenceMonday;
    final dateMonday = DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: date.weekday - 1));
    final weekDiff = dateMonday.difference(refMonday).inDays ~/ 7;
    return _centerIndex + weekDiff;
  }

  /// Get the Monday for a given page index.
  DateTime _mondayForPage(int page) {
    final weekOffset = page - _centerIndex;
    return _referenceMonday.add(Duration(days: weekOffset * 7));
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    return SizedBox(
      height: 64,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _totalWeeks,
        onPageChanged: (page) {
          _currentPage = page;
        },
        itemBuilder: (context, pageIndex) {
          final monday = _mondayForPage(pageIndex);
          final days = List.generate(7, (i) => monday.add(Duration(days: i)));

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (i) {
              final day = days[i];
              final isSelected = _isSameDay(day, widget.selectedDate);
              final isToday = _isSameDay(day, today);

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onDateSelected(day);
                },
                child: SizedBox(
                  width: 44,
                  height: 60,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _dayLabels[i],
                        style: AppTypography.micro.copyWith(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.neutral400,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: isToday && !isSelected
                              ? Border.all(
                                  color: AppColors.neutral300, width: 1.5)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: AppTypography.body.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : isToday
                                      ? AppColors.primary
                                      : AppColors.neutral600,
                              fontWeight: isSelected || isToday
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
