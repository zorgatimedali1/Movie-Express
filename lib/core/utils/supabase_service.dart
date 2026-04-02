// lib/core/utils/supabase_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

/// Convenient global accessor for the Supabase client.
class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;

  static User? get currentUser => client.auth.currentUser;

  static String? get currentUserId => currentUser?.id;

  static bool get isLoggedIn => currentUser != null;

  /// Auth state stream
  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;
}
