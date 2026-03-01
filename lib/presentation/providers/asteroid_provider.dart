import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/asteroid.dart';
import '../../domain/repositories/note_content_repository.dart';
import '../../domain/usecases/create_asteroid.dart';
import '../../domain/usecases/accrete_asteroid.dart';
import '../../domain/usecases/get_all_asteroids.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../../core/utils/id_generator.dart';
import 'galaxy_provider.dart';
import 'providers.dart';

class AsteroidState {
  final List<Asteroid> asteroids;
  final bool isCapturing;
  final Failure? error;

  const AsteroidState({
    this.asteroids = const [],
    this.isCapturing = false,
    this.error,
  });

  AsteroidState copyWith({
    List<Asteroid>? asteroids,
    bool? isCapturing,
    Failure? error,
    bool clearError = false,
  }) {
    return AsteroidState(
      asteroids: asteroids ?? this.asteroids,
      isCapturing: isCapturing ?? this.isCapturing,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AsteroidNotifier extends StateNotifier<AsteroidState> {
  final CreateAsteroid _createAsteroid;
  final AccreteAsteroid _accreteAsteroid;
  final GetAllAsteroids _getAllAsteroids;

  AsteroidNotifier({
    required CreateAsteroid createAsteroid,
    required AccreteAsteroid accreteAsteroid,
    required GetAllAsteroids getAllAsteroids,
  })  : _createAsteroid = createAsteroid,
        _accreteAsteroid = accreteAsteroid,
        _getAllAsteroids = getAllAsteroids,
        super(const AsteroidState());

  /// Load all persisted asteroids.
  Future<void> loadAll() async {
    final result = await _getAllAsteroids(const NoParams());
    result.fold(
      (failure) => state = state.copyWith(error: failure),
      (asteroids) => state = state.copyWith(asteroids: asteroids),
    );
  }

  /// Capture a new thought as an asteroid placed at the galaxy edge.
  Future<void> capture(String text) async {
    if (text.trim().isEmpty) return;
    state = state.copyWith(isCapturing: true, clearError: true);

    final trimmedText = text.length > 280 ? text.substring(0, 280) : text;

    // Random position at the galaxy edge (800–1200 world units from origin).
    final rng = math.Random();
    final radius = 800.0 + rng.nextDouble() * 400.0;
    final angle = rng.nextDouble() * 2 * math.pi;
    final x = radius * math.cos(angle);
    final y = radius * math.sin(angle);

    final asteroid = Asteroid(
      id: generateId(),
      text: trimmedText,
      x: x,
      y: y,
      createdAt: DateTime.now(),
    );

    final result = await _createAsteroid(CreateAsteroidParams(asteroid: asteroid));
    result.fold(
      (failure) => state = state.copyWith(isCapturing: false, error: failure),
      (_) => state = state.copyWith(
        asteroids: [...state.asteroids, asteroid],
        isCapturing: false,
      ),
    );
  }

  /// Accrete an asteroid onto an existing planet (merge text into planet note).
  Future<void> accrete(String asteroidId, String targetPlanetId) async {
    final asteroid = state.asteroids.where((a) => a.id == asteroidId).firstOrNull;
    if (asteroid == null) return;

    final result = await _accreteAsteroid(AccreteAsteroidParams(
      asteroid: asteroid,
      targetPlanetId: targetPlanetId,
    ));
    result.fold(
      (failure) => state = state.copyWith(error: failure),
      (_) => state = state.copyWith(
        asteroids: state.asteroids.where((a) => a.id != asteroidId).toList(),
      ),
    );
  }

  /// Promote an asteroid to a new planet under the given star.
  Future<void> promoteToplanet(String asteroidId, String starId) async {
    final asteroid = state.asteroids.where((a) => a.id == asteroidId).firstOrNull;
    if (asteroid == null) return;

    final name = asteroid.text.length > 30
        ? '${asteroid.text.substring(0, 30)}\u2026'
        : asteroid.text;

    final result = await _accreteAsteroid(AccreteAsteroidParams(
      asteroid: asteroid,
      promotionParams: AsteroidPromotionParams(
        name: name,
        parentStarId: starId,
        orbitRadius: 80.0,
        orbitAngle: math.Random().nextDouble() * 2 * math.pi,
        color: 0xFF4A90D9,
      ),
    ));
    result.fold(
      (failure) => state = state.copyWith(error: failure),
      (_) => state = state.copyWith(
        asteroids: state.asteroids.where((a) => a.id != asteroidId).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Use-case providers
// ---------------------------------------------------------------------------

final _createAsteroidProvider = Provider<CreateAsteroid>((ref) {
  return CreateAsteroid(repository: ref.watch(celestialBodyRepositoryProvider));
});

final _getAllAsteroidsProvider = Provider<GetAllAsteroids>((ref) {
  return GetAllAsteroids(repository: ref.watch(celestialBodyRepositoryProvider));
});

final _accreteAsteroidProvider = Provider<AccreteAsteroid>((ref) {
  return AccreteAsteroid(
    celestialBodyRepository: ref.watch(celestialBodyRepositoryProvider),
    noteContentRepository: ref.watch(noteContentRepositoryProvider),
  );
});

final noteContentRepositoryProvider = Provider<NoteContentRepository>((ref) {
  return ref.watch(noteContentRepositoryImplProvider);
});

final asteroidProvider =
    StateNotifierProvider<AsteroidNotifier, AsteroidState>((ref) {
  return AsteroidNotifier(
    createAsteroid: ref.watch(_createAsteroidProvider),
    accreteAsteroid: ref.watch(_accreteAsteroidProvider),
    getAllAsteroids: ref.watch(_getAllAsteroidsProvider),
  );
});
