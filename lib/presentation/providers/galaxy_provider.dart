import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/black_hole.dart';
import '../../domain/entities/star.dart';
import '../../domain/entities/planet.dart';
import '../../domain/entities/moon.dart';
import '../../domain/entities/asteroid.dart';
import '../../domain/repositories/celestial_body_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/id_generator.dart';
import 'providers.dart';

class GalaxyState {
  final List<BlackHole> blackHoles;
  final List<Star> stars;
  final List<Planet> planets;
  final List<Moon> moons;
  final List<Asteroid> asteroids;
  final bool isLoading;
  final Failure? error;

  const GalaxyState({
    this.blackHoles = const [],
    this.stars = const [],
    this.planets = const [],
    this.moons = const [],
    this.asteroids = const [],
    this.isLoading = false,
    this.error,
  });

  GalaxyState copyWith({
    List<BlackHole>? blackHoles,
    List<Star>? stars,
    List<Planet>? planets,
    List<Moon>? moons,
    List<Asteroid>? asteroids,
    bool? isLoading,
    Failure? error,
    bool clearError = false,
  }) {
    return GalaxyState(
      blackHoles: blackHoles ?? this.blackHoles,
      stars: stars ?? this.stars,
      planets: planets ?? this.planets,
      moons: moons ?? this.moons,
      asteroids: asteroids ?? this.asteroids,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class GalaxyNotifier extends StateNotifier<GalaxyState> {
  final CelestialBodyRepository _repository;

  GalaxyNotifier(this._repository) : super(const GalaxyState());

  /// Clears the current error state.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final results = await Future.wait([
        _repository.getAllBlackHoles(),
        _repository.getAllStars(),
        _repository.getAllPlanets(),
        _repository.getAllMoons(),
        _repository.getAllAsteroids(),
      ]);

      final bhResult = results[0] as dynamic;
      final starResult = results[1] as dynamic;
      final planetResult = results[2] as dynamic;
      final moonResult = results[3] as dynamic;
      final asteroidResult = results[4] as dynamic;

      final allBlackHoles = <BlackHole>[];
      final allStars = <Star>[];
      final allPlanets = <Planet>[];
      final allMoons = <Moon>[];
      final allAsteroids = <Asteroid>[];

      // ignore: avoid_dynamic_calls
      bhResult.fold((f) => state = state.copyWith(isLoading: false, error: f as Failure), (v) => allBlackHoles.addAll(v as List<BlackHole>));
      // ignore: avoid_dynamic_calls
      starResult.fold((f) {}, (v) => allStars.addAll(v as List<Star>));
      // ignore: avoid_dynamic_calls
      planetResult.fold((f) {}, (v) => allPlanets.addAll(v as List<Planet>));
      // ignore: avoid_dynamic_calls
      moonResult.fold((f) {}, (v) => allMoons.addAll(v as List<Moon>));
      // ignore: avoid_dynamic_calls
      asteroidResult.fold((f) {}, (v) => allAsteroids.addAll(v as List<Asteroid>));

      state = state.copyWith(
        blackHoles: allBlackHoles,
        stars: allStars,
        planets: allPlanets,
        moons: allMoons,
        asteroids: allAsteroids,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: CacheFailure('Failed to load galaxy data: $e'),
      );
    }
  }

  Future<void> addBlackHole(String name) async {
    try {
      final now = DateTime.now();
      final blackHole = BlackHole(
        id: generateId(),
        name: name,
        x: 0,
        y: 0,
        mass: 1000,
        orbitRadius: 0,
        orbitAngle: 0,
        color: 0xFF2D1B69,
        createdAt: now,
        updatedAt: now,
      );
      final result = await _repository.insertBlackHole(blackHole);
      result.fold(
        (failure) => state = state.copyWith(error: failure),
        (_) => state = state.copyWith(
          blackHoles: [...state.blackHoles, blackHole],
        ),
      );
    } catch (e) {
      state = state.copyWith(error: CacheFailure('Failed to add black hole: $e'));
    }
  }

  Future<void> addStar(String name, String blackHoleId) async {
    try {
      final now = DateTime.now();
      final star = Star(
        id: generateId(),
        name: name,
        x: 0,
        y: 0,
        mass: 500,
        parentBlackHoleId: blackHoleId,
        orbitRadius: 150,
        orbitAngle: 0,
        color: 0xFFFFF8E7,
        createdAt: now,
        updatedAt: now,
      );
      final result = await _repository.insertStar(star);
      result.fold(
        (failure) => state = state.copyWith(error: failure),
        (_) => state = state.copyWith(
          stars: [...state.stars, star],
        ),
      );
    } catch (e) {
      state = state.copyWith(error: CacheFailure('Failed to add star: $e'));
    }
  }

  Future<void> addPlanet(String name, String starId) async {
    try {
      final now = DateTime.now();
      final planet = Planet(
        id: generateId(),
        name: name,
        x: 0,
        y: 0,
        mass: 100,
        parentStarId: starId,
        orbitRadius: 80,
        orbitAngle: 0,
        color: 0xFF4A90D9,
        createdAt: now,
        updatedAt: now,
        wordCount: 0,
        visualState: PlanetVisualState.protostar,
      );
      final result = await _repository.insertPlanet(planet);
      result.fold(
        (failure) => state = state.copyWith(error: failure),
        (_) => state = state.copyWith(
          planets: [...state.planets, planet],
        ),
      );
    } catch (e) {
      state = state.copyWith(error: CacheFailure('Failed to add planet: $e'));
    }
  }

  /// Update the color of a celestial body identified by [id] and [bodyType].
  ///
  /// Because the repository only supports insert/delete (no update), this
  /// method re-inserts the entity with the new color — matching the same
  /// pattern used by [reparentBody].
  ///
  /// [bodyType] should be one of: 'blackHole', 'star', 'planet'.
  Future<void> updateBodyColor(
      String id, String bodyType, int newColor) async {
    switch (bodyType) {
      case 'blackHole':
        final bh =
            state.blackHoles.where((b) => b.id == id).firstOrNull;
        if (bh == null) return;
        final updated = BlackHole(
          id: bh.id,
          name: bh.name,
          x: bh.x,
          y: bh.y,
          mass: bh.mass,
          orbitRadius: bh.orbitRadius,
          orbitAngle: bh.orbitAngle,
          color: newColor,
          createdAt: bh.createdAt,
          updatedAt: DateTime.now(),
        );
        final del = await _repository.deleteBlackHole(id);
        del.fold((f) { state = state.copyWith(error: f); return; }, (_) async {
          final ins = await _repository.insertBlackHole(updated);
          ins.fold(
            (f) => state = state.copyWith(error: f),
            (_) => state = state.copyWith(
              blackHoles: [
                ...state.blackHoles.where((b) => b.id != id),
                updated,
              ],
            ),
          );
        });

      case 'star':
        final star =
            state.stars.where((s) => s.id == id).firstOrNull;
        if (star == null) return;
        final updated = Star(
          id: star.id,
          name: star.name,
          x: star.x,
          y: star.y,
          mass: star.mass,
          parentBlackHoleId: star.parentBlackHoleId,
          orbitRadius: star.orbitRadius,
          orbitAngle: star.orbitAngle,
          color: newColor,
          createdAt: star.createdAt,
          updatedAt: DateTime.now(),
        );
        final del = await _repository.deleteStar(id);
        del.fold((f) { state = state.copyWith(error: f); return; }, (_) async {
          final ins = await _repository.insertStar(updated);
          ins.fold(
            (f) => state = state.copyWith(error: f),
            (_) => state = state.copyWith(
              stars: [
                ...state.stars.where((s) => s.id != id),
                updated,
              ],
            ),
          );
        });

      case 'planet':
        final planet =
            state.planets.where((p) => p.id == id).firstOrNull;
        if (planet == null) return;
        final updated = Planet(
          id: planet.id,
          name: planet.name,
          x: planet.x,
          y: planet.y,
          mass: planet.mass,
          parentStarId: planet.parentStarId,
          orbitRadius: planet.orbitRadius,
          orbitAngle: planet.orbitAngle,
          color: newColor,
          wordCount: planet.wordCount,
          lastOpenedAt: planet.lastOpenedAt,
          visualState: planet.visualState,
          createdAt: planet.createdAt,
          updatedAt: DateTime.now(),
        );
        final del = await _repository.deletePlanet(id);
        del.fold((f) { state = state.copyWith(error: f); return; }, (_) async {
          final ins = await _repository.insertPlanet(updated);
          ins.fold(
            (f) => state = state.copyWith(error: f),
            (_) => state = state.copyWith(
              planets: [
                ...state.planets.where((p) => p.id != id),
                updated,
              ],
            ),
          );
        });
    }
  }

  Future<void> deleteBlackHole(String id) async {
    try {
      final result = await _repository.deleteBlackHole(id);
      result.fold(
        (failure) => state = state.copyWith(error: failure),
        (_) => state = state.copyWith(
          blackHoles: state.blackHoles.where((bh) => bh.id != id).toList(),
        ),
      );
    } catch (e) {
      state = state.copyWith(error: CacheFailure('Failed to delete black hole: $e'));
    }
  }

  Future<void> deleteStar(String id) async {
    try {
      final result = await _repository.deleteStar(id);
      result.fold(
        (failure) => state = state.copyWith(error: failure),
        (_) => state = state.copyWith(
          stars: state.stars.where((s) => s.id != id).toList(),
        ),
      );
    } catch (e) {
      state = state.copyWith(error: CacheFailure('Failed to delete star: $e'));
    }
  }

  Future<void> deletePlanet(String id) async {
    try {
      final result = await _repository.deletePlanet(id);
      result.fold(
        (failure) => state = state.copyWith(error: failure),
        (_) => state = state.copyWith(
          planets: state.planets.where((p) => p.id != id).toList(),
        ),
      );
    } catch (e) {
      state = state.copyWith(error: CacheFailure('Failed to delete planet: $e'));
    }
  }

  /// Reparent a body by deleting the old record and inserting a new one
  /// with the updated parentId. The repository interface only exposes
  /// insert/delete (no update), so we recreate the entity.
  Future<void> reparentBody(String bodyId, String newParentId) async {
    final star = state.stars.where((s) => s.id == bodyId).firstOrNull;
    if (star != null) {
      final newStar = Star(
        id: generateId(),
        name: star.name,
        x: star.x,
        y: star.y,
        mass: star.mass,
        parentBlackHoleId: newParentId,
        orbitRadius: star.orbitRadius,
        orbitAngle: star.orbitAngle,
        color: star.color,
        createdAt: star.createdAt,
        updatedAt: DateTime.now(),
      );
      final del = await _repository.deleteStar(bodyId);
      del.fold((f) { state = state.copyWith(error: f); return; }, (_) async {
        final ins = await _repository.insertStar(newStar);
        ins.fold(
          (f) => state = state.copyWith(error: f),
          (_) => state = state.copyWith(
            stars: [...state.stars.where((s) => s.id != bodyId), newStar],
          ),
        );
      });
      return;
    }

    final planet = state.planets.where((p) => p.id == bodyId).firstOrNull;
    if (planet != null) {
      final newPlanet = Planet(
        id: generateId(),
        name: planet.name,
        x: planet.x,
        y: planet.y,
        mass: planet.mass,
        parentStarId: newParentId,
        orbitRadius: planet.orbitRadius,
        orbitAngle: planet.orbitAngle,
        color: planet.color,
        createdAt: planet.createdAt,
        updatedAt: DateTime.now(),
        wordCount: planet.wordCount,
        lastOpenedAt: planet.lastOpenedAt,
        visualState: planet.visualState,
      );
      final del = await _repository.deletePlanet(bodyId);
      del.fold((f) { state = state.copyWith(error: f); return; }, (_) async {
        final ins = await _repository.insertPlanet(newPlanet);
        ins.fold(
          (f) => state = state.copyWith(error: f),
          (_) => state = state.copyWith(
            planets: [...state.planets.where((p) => p.id != bodyId), newPlanet],
          ),
        );
      });
    }
  }
}

final galaxyProvider =
    StateNotifierProvider<GalaxyNotifier, GalaxyState>((ref) {
  final repository = ref.watch(celestialBodyRepositoryProvider);
  return GalaxyNotifier(repository);
});

/// Repository provider — wired to data layer via DI providers.
final celestialBodyRepositoryProvider =
    Provider<CelestialBodyRepository>((ref) {
  return ref.watch(celestialBodyRepositoryImplProvider);
});
