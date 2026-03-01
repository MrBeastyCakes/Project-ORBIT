import 'package:flutter/material.dart';

import '../screens/galaxy_screen.dart';
import '../screens/surface_screen.dart';
import '../screens/telescope_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/auth_screen.dart';

/// Route name constants.
class AppRoutes {
  AppRoutes._();

  static const String root = '/';
  static const String surface = '/surface';
  static const String telescope = '/telescope';
  static const String settings = '/settings';
  static const String auth = '/auth';
}

/// Generates routes for [MaterialApp.onGenerateRoute].
///
/// Usage:
/// ```dart
/// MaterialApp(
///   onGenerateRoute: AppRouter.onGenerateRoute,
///   initialRoute: AppRoutes.root,
/// )
/// ```
class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '/');

    switch (uri.path) {
      case AppRoutes.root:
        // Check auth state and redirect accordingly.
        // Auth check is handled inside OrbitApp / GalaxyScreen flow.
        return MaterialPageRoute<void>(
          builder: (_) => const GalaxyScreen(),
          settings: settings,
        );

      case AppRoutes.auth:
        return MaterialPageRoute<void>(
          builder: (_) => const AuthScreen(),
          settings: settings,
        );

      case AppRoutes.surface:
        final planetId = uri.queryParameters['planetId'] ??
            (settings.arguments as String?);
        if (planetId == null) {
          return _errorRoute('Missing planetId for /surface route');
        }
        return MaterialPageRoute<void>(
          builder: (_) => SurfaceScreen(planetId: planetId),
          settings: settings,
        );

      case AppRoutes.telescope:
        return PageRouteBuilder<void>(
          opaque: false,
          pageBuilder: (_, __, ___) => const TelescopeScreen(),
          settings: settings,
        );

      case AppRoutes.settings:
        return MaterialPageRoute<void>(
          builder: (_) => const SettingsScreen(),
          settings: settings,
        );

      default:
        return _errorRoute('Unknown route: ${settings.name}');
    }
  }

  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        body: Center(child: Text(message)),
      ),
    );
  }
}
