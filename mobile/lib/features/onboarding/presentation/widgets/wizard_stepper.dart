import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class WizardStepper extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final void Function(int)? onStepTapped;

  const WizardStepper({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.onStepTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps * 2 - 1, (i) {
        if (i.isOdd) {
          final stepBefore = i ~/ 2;
          final isCompleted = stepBefore < currentStep;
          return SizedBox(
            width: 40,
            child: Divider(
              thickness: 2,
              color: isCompleted ? AppColors.success : AppColors.neutral200,
            ),
          );
        }

        final stepIndex = i ~/ 2;
        final isCompleted = stepIndex < currentStep;
        final isActive = stepIndex == currentStep;

        return GestureDetector(
          onTap: isCompleted ? () => onStepTapped?.call(stepIndex) : null,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? AppColors.success
                      : isActive
                          ? AppColors.primary
                          : AppColors.neutral200,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : Text(
                          '${stepIndex + 1}',
                          style: AppTypography.caption.copyWith(
                            color: isActive ? Colors.white : AppColors.neutral400,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
