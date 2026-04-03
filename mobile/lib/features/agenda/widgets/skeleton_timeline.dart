import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Skeleton shimmer for the agenda timeline during loading
class SkeletonTimeline extends StatefulWidget {
  const SkeletonTimeline({super.key});

  @override
  State<SkeletonTimeline> createState() => _SkeletonTimelineState();
}

class _SkeletonTimelineState extends State<SkeletonTimeline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _shimmer = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) {
        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            children: [
              _skeletonSlot('09:00'),
              const SizedBox(height: AppSpacing.md),
              _skeletonSlot('10:00'),
              const SizedBox(height: AppSpacing.md),
              _skeletonSlot('11:00'),
              const SizedBox(height: AppSpacing.md),
              _skeletonSlot('12:00'),
              const SizedBox(height: AppSpacing.md),
              _skeletonSlot('14:00'),
            ],
          ),
        );
      },
    );
  }

  Widget _skeletonSlot(String hour) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 48,
          child: Text(
            hour,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.neutral400,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                gradient: LinearGradient(
                  begin: Alignment(_shimmer.value - 1, 0),
                  end: Alignment(_shimmer.value, 0),
                  colors: const [
                    AppColors.neutral200,
                    AppColors.neutral100,
                    AppColors.neutral200,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _bar(140),
                  const SizedBox(height: AppSpacing.sm),
                  _bar(100),
                  const SizedBox(height: AppSpacing.sm),
                  _bar(70, height: 16, radius: AppRadius.full),
                ],
              ),
          ),
        ),
      ],
    );
  }

  Widget _bar(double width, {double height = 14, double radius = AppRadius.sm}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.neutral300.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
