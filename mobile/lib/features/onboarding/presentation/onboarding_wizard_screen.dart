import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../providers/onboarding_provider.dart';
import 'steps/business_hours_step.dart';
import 'steps/services_step.dart';
import 'steps/studio_data_step.dart';
import 'widgets/wizard_stepper.dart';

class OnboardingWizardScreen extends ConsumerStatefulWidget {
  const OnboardingWizardScreen({super.key});

  @override
  ConsumerState<OnboardingWizardScreen> createState() => _OnboardingWizardScreenState();
}

class _OnboardingWizardScreenState extends ConsumerState<OnboardingWizardScreen> {
  final _pageController = PageController();

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(onboardingNotifierProvider.notifier).init(),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _animateToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingNotifierProvider);

    ref.listen(onboardingNotifierProvider, (prev, next) {
      if (next is OnboardingStep && prev is OnboardingStep) {
        if (next.currentStep != prev.currentStep) {
          _animateToPage(next.currentStep);
        }
      }
      if (next is OnboardingStep && prev is OnboardingLoading) {
        if (next.currentStep > 0) {
          // Schedule after build so PageView is attached
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_pageController.hasClients) {
              _pageController.jumpToPage(next.currentStep);
            }
          });
        }
      }
      if (next is OnboardingComplete) {
        context.go('/onboarding/complete');
      }
    });

    if (state is OnboardingLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    if (state is OnboardingError) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(state.message),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: () =>
                    ref.read(onboardingNotifierProvider.notifier).init(),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final currentStep = (state is OnboardingStep) ? state.currentStep : 0;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.lg),
            WizardStepper(
              currentStep: currentStep,
              totalSteps: 3,
              onStepTapped: (step) {
                ref.read(onboardingNotifierProvider.notifier).goToStep(step);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  StudioDataStep(),
                  ServicesStep(),
                  BusinessHoursStep(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
