import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/theme_constants.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/router/app_router.dart';
import 'presentation/screens/auth_screen.dart';
import 'presentation/screens/galaxy_screen.dart';

class OrbitApp extends ConsumerStatefulWidget {
  const OrbitApp({super.key});

  @override
  ConsumerState<OrbitApp> createState() => _OrbitAppState();
}

class _OrbitAppState extends ConsumerState<OrbitApp> {
  @override
  void initState() {
    super.initState();
    // Check for an existing session on startup (non-blocking).
    Future.microtask(() => ref.read(authProvider.notifier).checkAuth());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Project ORBIT',
      theme: ThemeConstants.orbitDarkTheme,
      debugShowCheckedModeBanner: false,
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: const _AuthGate(),
    );
  }
}

/// Decides whether to show the auth screen or the main galaxy screen.
///
/// While the auth check is in flight we show a minimal splash. Once resolved
/// we land the user on either [AuthScreen] or [GalaxyScreen] depending on
/// whether a session exists.
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // Still checking — show a neutral splash so the screen doesn't flash.
    if (authState.isLoading) {
      return const Scaffold(
        backgroundColor: ThemeConstants.backgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            color: ThemeConstants.accentColor,
          ),
        ),
      );
    }

    // Authenticated or explicitly chose local mode → main app.
    if (authState.isAuthenticated || authState.choseLocalMode) {
      return const GalaxyScreen();
    }

    // Not authenticated yet → show sign-in screen.
    return const AuthScreen();
  }
}
