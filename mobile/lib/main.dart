import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/http/api_client.dart';
import 'core/router/app_router.dart';
import 'core/supabase/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'features/agenda/repositories/appointment_repository.dart';
import 'features/agenda/repositories/blocked_slot_repository.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/onboarding/data/onboarding_repository.dart';

const _isRelease = bool.fromEnvironment('dart.vm.product');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'http://localhost:54321',
  );
  const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'dev-anon-key',
  );
  const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  // Fail fast in release builds if env vars are missing
  assert(!_isRelease || supabaseUrl != 'http://localhost:54321',
      'SUPABASE_URL must be set for release builds');
  assert(!_isRelease || supabaseAnonKey != 'dev-anon-key',
      'SUPABASE_ANON_KEY must be set for release builds');
  assert(!_isRelease || apiBaseUrl != 'http://localhost:3000',
      'API_BASE_URL must be set for release builds');

  await initSupabase(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          AuthRepository(supabase.auth),
        ),
        onboardingRepositoryProvider.overrideWithValue(
          OnboardingRepository(
            ApiClient(baseUrl: apiBaseUrl, auth: supabase.auth),
          ),
        ),
        appointmentRepositoryProvider.overrideWithValue(
          AppointmentRepository(
            ApiClient(baseUrl: apiBaseUrl, auth: supabase.auth),
          ),
        ),
        blockedSlotRepositoryProvider.overrideWithValue(
          BlockedSlotRepository(
            ApiClient(baseUrl: apiBaseUrl, auth: supabase.auth),
          ),
        ),
      ],
      child: const OrizApp(),
    ),
  );
}

class OrizApp extends ConsumerWidget {
  const OrizApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Oriz',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: router,
    );
  }
}
