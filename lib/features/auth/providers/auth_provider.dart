// lib/features/auth/providers/auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/supabase_service.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  bool get isLoggedIn => user != null;

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) =>
      AuthState(
        user: clearUser ? null : user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : error ?? this.error,
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier()
      : super(AuthState(user: SupabaseService.currentUser)) {
    // Listen to Supabase auth state changes
    SupabaseService.authStateChanges.listen((event) {
      state = state.copyWith(
        user: event.session?.user,
        isLoading: false,
        clearError: true,
      );
    });
  }

  // ── Sign Up ──────────────────────────────────────────────────────────────

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await SupabaseService.client.auth.signUp(
        email: email.trim().toLowerCase(),
        password: password,
        data: {'full_name': name.trim()},
      );
      if (response.user == null) {
        state = state.copyWith(
            isLoading: false, error: 'Sign up failed. Try again.');
        return false;
      }
      state = state.copyWith(user: response.user, isLoading: false);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'Unexpected error. Try again.');
      return false;
    }
  }

  // ── Sign In ──────────────────────────────────────────────────────────────

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response =
          await SupabaseService.client.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      if (response.user == null) {
        state = state.copyWith(
            isLoading: false, error: 'Invalid credentials.');
        return false;
      }
      state = state.copyWith(user: response.user, isLoading: false);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'Unexpected error. Try again.');
      return false;
    }
  }

  // ── Sign Out ─────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await SupabaseService.client.auth.signOut();
    state = const AuthState();
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
