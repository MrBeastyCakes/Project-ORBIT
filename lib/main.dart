import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'data/models/black_hole_model.dart';
import 'data/models/star_model.dart';
import 'data/models/planet_model.dart';
import 'data/models/moon_model.dart';
import 'data/models/asteroid_model.dart';
import 'data/models/note_content_model.dart';
import 'data/models/wormhole_model.dart';
import 'data/models/constellation_link_model.dart';
import 'data/models/user_profile_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global error boundary: catch unhandled Flutter framework errors.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  try {
    await _initHive();
    runApp(const ProviderScope(child: OrbitApp()));
  } catch (e) {
    // Hive or other critical init failure -- show error screen.
    runApp(_ErrorApp(error: e.toString()));
  }
}

Future<void> _initHive() async {
  await Hive.initFlutter();

  // Register all Hive type adapters
  Hive.registerAdapter(BlackHoleModelAdapter());
  Hive.registerAdapter(StarModelAdapter());
  Hive.registerAdapter(PlanetModelAdapter());
  Hive.registerAdapter(MoonModelAdapter());
  Hive.registerAdapter(AsteroidModelAdapter());
  Hive.registerAdapter(NoteContentModelAdapter());
  Hive.registerAdapter(WormholeModelAdapter());
  Hive.registerAdapter(ConstellationLinkModelAdapter());
  Hive.registerAdapter(UserProfileModelAdapter());

  // Open all typed Hive boxes
  await Future.wait([
    Hive.openBox<BlackHoleModel>('blackHoles'),
    Hive.openBox<StarModel>('stars'),
    Hive.openBox<PlanetModel>('planets'),
    Hive.openBox<MoonModel>('moons'),
    Hive.openBox<AsteroidModel>('asteroids'),
    Hive.openBox<NoteContentModel>('noteContents'),
    Hive.openBox<WormholeModel>('wormholes'),
    Hive.openBox<ConstellationLinkModel>('constellationLinks'),
    Hive.openBox<UserProfileModel>('users'),
    Hive.openBox<dynamic>('preferences'),
  ]);
}

/// Minimal error app shown when Hive initialization fails.
class _ErrorApp extends StatelessWidget {
  final String error;

  const _ErrorApp({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        backgroundColor: const Color(0xFF0A0A1A),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Color(0xFFFF6B6B),
                  size: 64,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Failed to initialize ORBIT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Local storage could not be opened.\nPlease restart the app or clear app data.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                    fontFamily: 'monospace',
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
