import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../../core/constants/theme_constants.dart';
import 'galaxy_screen.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // Navigate to GalaxyScreen once authenticated
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated && context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const GalaxyScreen()),
        );
      }
    });

    return Scaffold(
      backgroundColor: ThemeConstants.backgroundColor,
      body: Center(
        child: Card(
          color: ThemeConstants.surfaceColor,
          margin: const EdgeInsets.symmetric(horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: ThemeConstants.accentColor.withValues(alpha: 0.3),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // App logo / title
                const Icon(
                  Icons.blur_circular,
                  size: 64,
                  color: ThemeConstants.accentColor,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Project ORBIT',
                  style: TextStyle(
                    color: ThemeConstants.starColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Spatial, physics-driven notes',
                  style: TextStyle(
                    color: ThemeConstants.starColor.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 40),

                // Error message
                if (authState.error != null) ...[
                  Text(
                    authState.error!.message,
                    style: const TextStyle(color: Colors.redAccent),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],

                // Sign-in button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: authState.isLoading
                        ? null
                        : () =>
                            ref.read(authProvider.notifier).signIn(),
                    icon: authState.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black54,
                            ),
                          )
                        : const Icon(Icons.login, size: 20),
                    label: Text(
                      authState.isLoading
                          ? 'Signing in...'
                          : 'Sign in with Google',
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Skip / local-only button
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor:
                          ThemeConstants.starColor.withValues(alpha: 0.6),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: authState.isLoading
                        ? null
                        : () {
                            ref
                                .read(authProvider.notifier)
                                .continueLocally();
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute<void>(
                                builder: (_) => const GalaxyScreen(),
                              ),
                            );
                          },
                    child: const Text('Continue without account'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
