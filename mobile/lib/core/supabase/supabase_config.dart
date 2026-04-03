import 'package:supabase_flutter/supabase_flutter.dart';

/// Initialize Supabase SDK. Call once in main() before runApp().
Future<void> initSupabase({
  required String url,
  required String anonKey,
}) async {
  await Supabase.initialize(
    url: url,
    anonKey: anonKey,
  );
}

/// Shorthand to access the Supabase client singleton.
SupabaseClient get supabase => Supabase.instance.client;
