// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/movies/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Initialize Supabase ─────────────────────────────────────────────────
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  runApp(
    // ProviderScope required for Riverpod
    const ProviderScope(child: MovieRecApp()),
  );
}

class MovieRecApp extends StatelessWidget {
  const MovieRecApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const _AppGate(),
      );
}

/// Routes between auth screens and the main app depending on session state.
class _AppGate extends ConsumerStatefulWidget {
  const _AppGate();

  @override
  ConsumerState<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends ConsumerState<_AppGate> {
  bool _showLogin = true;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Logged in → Home
    if (authState.isLoggedIn) return const HomeScreen();

    // Not logged in → Login / Register toggle
    return _showLogin
        ? LoginScreen(
            onGoToRegister: () => setState(() => _showLogin = false))
        : RegisterScreen(
            onGoToLogin: () => setState(() => _showLogin = true));
  }
}
