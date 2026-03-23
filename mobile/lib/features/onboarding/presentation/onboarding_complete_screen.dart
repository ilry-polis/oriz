import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class OnboardingCompleteScreen extends StatefulWidget {
  const OnboardingCompleteScreen({super.key});

  @override
  State<OnboardingCompleteScreen> createState() => _OnboardingCompleteScreenState();
}

class _OnboardingCompleteScreenState extends State<OnboardingCompleteScreen> {
  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 80,
                color: AppColors.success,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Seu estudio esta pronto!',
                style: AppTypography.display,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Agora voce pode agendar seus primeiros atendimentos.',
                style: AppTypography.body.copyWith(color: AppColors.neutral600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () => context.go('/agenda'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: Text(
                    'Ir para Agenda',
                    style: AppTypography.bodySemibold.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
