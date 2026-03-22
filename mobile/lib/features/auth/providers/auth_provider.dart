import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../data/auth_repository.dart';

// ─── State ────────────────────────────────────────────────
sealed class AuthStateData {
  const AuthStateData();
}

class AuthUnauthenticated extends AuthStateData {
  const AuthUnauthenticated();
}

class AuthLoading extends AuthStateData {
  const AuthLoading();
}

class AuthAuthenticated extends AuthStateData {
  final Session session;
  const AuthAuthenticated(this.session);
}

class AuthError extends AuthStateData {
  final String message;
  final bool rateLimited;
  final DateTime? rateLimitedUntil;
  const AuthError(this.message, {this.rateLimited = false, this.rateLimitedUntil});
}

class AuthActionSuccess extends AuthStateData {
  final String message;
  const AuthActionSuccess(this.message);
}

// ─── Provider ─────────────────────────────────────────────
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  throw UnimplementedError(
    'authRepositoryProvider must be overridden with a real AuthRepository',
  );
});

final authNotifierProvider =
    NotifierProvider<AuthNotifier, AuthStateData>(AuthNotifier.new);

class AuthNotifier extends Notifier<AuthStateData> {
  int _failureCount = 0;

  @override
  AuthStateData build() {
    final repo = ref.read(authRepositoryProvider);
    final session = repo.currentSession;
    return session != null
        ? AuthAuthenticated(session)
        : const AuthUnauthenticated();
  }

  bool get isRateLimited {
    final s = state;
    if (s is AuthError && s.rateLimitedUntil != null) {
      return DateTime.now().isBefore(s.rateLimitedUntil!);
    }
    return false;
  }

  Future<void> signIn({required String email, required String password}) async {
    if (isRateLimited) return;
    state = const AuthLoading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final response = await repo.signIn(email: email, password: password);
      _failureCount = 0;
      state = AuthAuthenticated(response.session!);
    } on AuthException catch (e) {
      _failureCount++;
      final limited = _failureCount >= 3;
      state = AuthError(
        e.message,
        rateLimited: limited,
        rateLimitedUntil:
            limited ? DateTime.now().add(const Duration(seconds: 30)) : null,
      );
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = const AuthLoading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final response =
          await repo.signUp(email: email, password: password, fullName: fullName);
      state = AuthAuthenticated(response.session!);
    } on AuthException catch (e) {
      state = AuthError(e.message);
    }
  }

  Future<void> resetPassword({required String email}) async {
    state = const AuthLoading();
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.resetPassword(email: email);
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      // intentionally swallowed — email enumeration protection
    }
    state = const AuthActionSuccess('Se o email existir, enviaremos instrucoes.');
  }

  Future<void> signOut() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.signOut();
    _failureCount = 0;
    state = const AuthUnauthenticated();
  }
}
