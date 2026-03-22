import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/agenda/agenda_day_screen.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../shell/app_shell.dart';

/// Listenable that notifies GoRouter when auth state changes.
class AuthNotifierListenable extends ChangeNotifier {
  AuthNotifierListenable(Ref ref) {
    ref.listen(authNotifierProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final repo = ref.read(authRepositoryProvider);
  final authListenable = AuthNotifierListenable(ref);

  return GoRouter(
    initialLocation: '/agenda',
    refreshListenable: authListenable,
    redirect: (context, state) {
      final hasSession = repo.currentSession != null;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/forgot-password';

      if (!hasSession && !isAuthRoute) return '/login';
      if (hasSession && isAuthRoute) return '/agenda';
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
            builder: (_, __) => const _Placeholder('Clientes'),
          ),
          GoRoute(
            path: '/financial',
            builder: (_, __) => const _Placeholder('Financeiro'),
          ),
          GoRoute(
            path: '/more',
            builder: (_, __) => const _Placeholder('Mais'),
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
