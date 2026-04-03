import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/agenda/agenda_day_screen.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/clients/presentation/anamnesis_form_screen.dart';
import '../../features/clients/presentation/client_detail_screen.dart';
import '../../features/clients/presentation/client_form_screen.dart';
import '../../features/clients/presentation/client_list_screen.dart';
import '../../features/more/presentation/more_screen.dart';
import '../../features/services_management/presentation/service_form_screen.dart';
import '../../features/services_management/presentation/services_management_screen.dart';
import '../../features/team/presentation/invite_accept_screen.dart';
import '../../features/team/presentation/professional_form_screen.dart';
import '../../features/team/presentation/team_management_screen.dart';
import '../http/api_client.dart';
import '../../features/onboarding/data/onboarding_repository.dart';
import '../../features/onboarding/presentation/onboarding_complete_screen.dart';
import '../../features/onboarding/presentation/onboarding_wizard_screen.dart';
import '../shell/app_shell.dart';

/// Listenable that notifies GoRouter when auth state changes.
class AuthNotifierListenable extends ChangeNotifier {
  AuthNotifierListenable(Ref ref) {
    ref.listen(authNotifierProvider, (_, __) => notifyListeners());
  }
}

/// Tracks studio state for routing decisions.
sealed class StudioRouteState {
  const StudioRouteState();
}

class StudioUnknown extends StudioRouteState {
  const StudioUnknown();
}

class StudioNotFound extends StudioRouteState {
  const StudioNotFound();
}

class StudioExists extends StudioRouteState {
  final bool onboardingComplete;
  const StudioExists({required this.onboardingComplete});
}

class StudioStateNotifier extends Notifier<StudioRouteState> {
  @override
  StudioRouteState build() => const StudioUnknown();

  void markOnboardingComplete() {
    state = const StudioExists(onboardingComplete: true);
  }

  void setNotFound() {
    state = const StudioNotFound();
  }

  void setExists({required bool onboardingComplete}) {
    state = StudioExists(onboardingComplete: onboardingComplete);
  }

  void reset() {
    state = const StudioUnknown();
  }
}

final studioStateProvider =
    NotifierProvider<StudioStateNotifier, StudioRouteState>(StudioStateNotifier.new);

final routerProvider = Provider<GoRouter>((ref) {
  final authRepo = ref.read(authRepositoryProvider);
  final authListenable = AuthNotifierListenable(ref);

  Future<void> checkStudio() async {
    try {
      final onboardingRepo = ref.read(onboardingRepositoryProvider);
      final info = await onboardingRepo.getMyStudio();
      if (info == null) {
        ref.read(studioStateProvider.notifier).setNotFound();
      } else {
        ref.read(studioStateProvider.notifier).setExists(
          onboardingComplete: info.onboardingStep == 'complete',
        );
      }
    } on ApiException catch (e) {
      // 404 = no studio; treat as no studio
      if (e.statusCode == 404) {
        ref.read(studioStateProvider.notifier).setNotFound();
      }
      // Other API errors (500, network): keep unknown so redirect doesn't
      // falsely send user to onboarding. Router will retry on next auth change.
    } catch (_) {
      // Network/timeout: keep StudioUnknown — don't assume no studio
    }
  }

  ref.listen(authNotifierProvider, (prev, next) {
    if (next is AuthAuthenticated && prev is! AuthAuthenticated) {
      checkStudio();
    }
    if (next is AuthUnauthenticated) {
      ref.read(studioStateProvider.notifier).reset();
    }
  });

  ref.listen(studioStateProvider, (_, __) {
    authListenable.notifyListeners();
  });

  if (authRepo.currentSession != null) {
    Future.microtask(checkStudio);
  }

  return GoRouter(
    initialLocation: '/agenda',
    refreshListenable: authListenable,
    redirect: (context, state) {
      final hasSession = authRepo.currentSession != null;
      final path = state.matchedLocation;

      final isAuthRoute = path == '/login' ||
          path == '/signup' ||
          path == '/forgot-password';
      final isOnboardingRoute = path.startsWith('/onboarding');
      final isInviteRoute = path.startsWith('/invite/');

      if (!hasSession && !isAuthRoute && !isInviteRoute) return '/login';

      if (hasSession && isAuthRoute) {
        final studio = ref.read(studioStateProvider);
        if (studio is StudioExists && studio.onboardingComplete) {
          return '/agenda';
        }
        // Unknown, NotFound, or incomplete → onboarding (shows loading while checking)
        return '/onboarding';
      }

      if (hasSession && !isAuthRoute && !isOnboardingRoute) {
        final studio = ref.read(studioStateProvider);
        if (studio is StudioNotFound) return '/onboarding';
        if (studio is StudioUnknown) return '/onboarding';
        if (studio is StudioExists && !studio.onboardingComplete) {
          return '/onboarding';
        }
      }

      if (hasSession && isOnboardingRoute) {
        final studio = ref.read(studioStateProvider);
        if (studio is StudioExists && studio.onboardingComplete) {
          return '/agenda';
        }
      }

      return null;
    },
    routes: [
      // Auth routes (no shell)
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (_, __) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),

      // Onboarding routes (no shell)
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingWizardScreen(),
      ),
      GoRoute(
        path: '/onboarding/complete',
        builder: (_, __) => const OnboardingCompleteScreen(),
      ),

      // Invite accept (no shell — standalone)
      GoRoute(
        path: '/invite/:token',
        builder: (_, state) => InviteAcceptScreen(
          token: state.pathParameters['token']!,
        ),
      ),

      // Protected routes with shell (bottom nav)
      ShellRoute(
        builder: (_, __, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/agenda',
            builder: (_, __) => const AgendaDayScreen(),
          ),
          GoRoute(
            path: '/clients',
            builder: (_, __) => const ClientListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, __) => const ClientFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (_, state) => ClientDetailScreen(
                  clientId: state.pathParameters['id']!,
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (_, state) => ClientFormScreen(
                      clientId: state.pathParameters['id'],
                    ),
                  ),
                  GoRoute(
                    path: 'anamnesis/:category',
                    builder: (_, state) => AnamnesisFormScreen(
                      clientId: state.pathParameters['id']!,
                      category: state.pathParameters['category']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/services',
            builder: (_, __) => const ServicesManagementScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, __) => const ServiceFormScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                builder: (_, state) => ServiceFormScreen(
                  serviceId: state.pathParameters['id'],
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/more',
            builder: (_, __) => const MoreScreen(),
            routes: [
              GoRoute(
                path: 'team',
                builder: (_, __) => const TeamManagementScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (_, __) => const ProfessionalFormScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class _Placeholder extends StatelessWidget {
  final String label;
  const _Placeholder(this.label);

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(label, style: const TextStyle(fontSize: 24)));
  }
}
