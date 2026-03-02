import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/black_hole.dart';
import '../../domain/entities/star.dart';
import '../../domain/entities/planet.dart';
import '../../domain/entities/moon.dart';
import '../../domain/entities/asteroid.dart';
import '../../domain/repositories/celestial_body_repository.dart';
import '../../domain/repositories/constellation_repository.dart';
import '../../domain/repositories/wormhole_repository.dart';
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
  final WormholeRepository _wormholeRepository;
  final ConstellationRepository _constellationRepository;

  GalaxyNotifier(
    this._repository,
    this._wormholeRepository,
    this._constellationRepository,
  ) : super(const GalaxyState());

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
      final index = state.blackHoles.length;
      final angle = index * 2 * math.pi / 6; // max 6 positions in a ring
      const distance = 500.0; // spacing between black holes
      final x = distance * math.cos(angle);
      final y = distance * math.sin(angle);
      final blackHole = BlackHole(
        id: generateId(),
        name: name,
        x: x,
        y: y,
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
      final random = math.Random();
      final siblingCount =
          state.stars.where((s) => s.parentBlackHoleId == blackHoleId).length;
      final orbitRadius = 150.0 + siblingCount * 80.0;
      final orbitAngle = random.nextDouble() * 360.0;
      // Compute initial position from parent black hole + orbit params.
      final parentBh = state.blackHoles.where((bh) => bh.id == blackHoleId).firstOrNull;
      final angleRad = orbitAngle * math.pi / 180.0;
      final initialX = (parentBh?.x ?? 0) + orbitRadius * math.cos(angleRad);
      final initialY = (parentBh?.y ?? 0) + orbitRadius * math.sin(angleRad);
      final star = Star(
        id: generateId(),
        name: name,
        x: initialX,
        y: initialY,
        mass: 500,
        parentBlackHoleId: blackHoleId,
        orbitRadius: orbitRadius,
        orbitAngle: orbitAngle,
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
      final random = math.Random();
      final siblingCount =
          state.planets.where((p) => p.parentStarId == starId).length;
      final orbitRadius = 80.0 + siblingCount * 50.0;
      final orbitAngle = random.nextDouble() * 360.0;
      // Compute initial position from parent star + orbit params.
      final parentStar = state.stars.where((s) => s.id == starId).firstOrNull;
      final pAngleRad = orbitAngle * math.pi / 180.0;
      final initialX = (parentStar?.x ?? 0) + orbitRadius * math.cos(pAngleRad);
      final initialY = (parentStar?.y ?? 0) + orbitRadius * math.sin(pAngleRad);
      final planet = Planet(
        id: generateId(),
        name: name,
        x: initialX,
        y: initialY,
        mass: 100,
        parentStarId: starId,
        orbitRadius: orbitRadius,
        orbitAngle: orbitAngle,
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
  /// [bodyType] should be one of: 'blackHole', 'star', 'planet'.
  Future<void> updateBodyColor(
      String id, String bodyType, int newColor) async {
    switch (bodyType) {
      case 'blackHole':
        final bh = state.blackHoles.where((b) => b.id == id).firstOrNull;
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
        final result = await _repository.updateBlackHole(updated);
        result.fold(
          (f) => state = state.copyWith(error: f),
          (_) => state = state.copyWith(
            blackHoles: [...state.blackHoles.where((b) => b.id != id), updated],
          ),
        );

      case 'star':
        final star = state.stars.where((s) => s.id == id).firstOrNull;
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
        final result = await _repository.updateStar(updated);
        result.fold(
          (f) => state = state.copyWith(error: f),
          (_) => state = state.copyWith(
            stars: [...state.stars.where((s) => s.id != id), updated],
          ),
        );

      case 'planet':
        final planet = state.planets.where((p) => p.id == id).firstOrNull;
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
        final result = await _repository.updatePlanet(updated);
        result.fold(
          (f) => state = state.copyWith(error: f),
          (_) => state = state.copyWith(
            planets: [...state.planets.where((p) => p.id != id), updated],
          ),
        );
    }
  }

  /// Rename a black hole, preserving all other fields.
  Future<void> renameBlackHole(String id, String newName) async {
    final bh = state.blackHoles.where((b) => b.id == id).firstOrNull;
    if (bh == null) return;
    final updated = BlackHole(
      id: bh.id,
      name: newName,
      x: bh.x,
      y: bh.y,
      mass: bh.mass,
      orbitRadius: bh.orbitRadius,
      orbitAngle: bh.orbitAngle,
      color: bh.color,
      createdAt: bh.createdAt,
      updatedAt: DateTime.now(),
    );
    final result = await _repository.updateBlackHole(updated);
    result.fold(
      (f) => state = state.copyWith(error: f),
      (_) => state = state.copyWith(
        blackHoles: [...state.blackHoles.where((b) => b.id != id), updated],
      ),
    );
  }

  /// Rename a star, preserving all other fields.
  Future<void> renameStar(String id, String newName) async {
    final star = state.stars.where((s) => s.id == id).firstOrNull;
    if (star == null) return;
    final updated = Star(
      id: star.id,
      name: newName,
      x: star.x,
      y: star.y,
      mass: star.mass,
      parentBlackHoleId: star.parentBlackHoleId,
      orbitRadius: star.orbitRadius,
      orbitAngle: star.orbitAngle,
      color: star.color,
      createdAt: star.createdAt,
      updatedAt: DateTime.now(),
    );
    final result = await _repository.updateStar(updated);
    result.fold(
      (f) => state = state.copyWith(error: f),
      (_) => state = state.copyWith(
        stars: [...state.stars.where((s) => s.id != id), updated],
      ),
    );
  }

  /// Rename a planet, preserving all other fields.
  Future<void> renamePlanet(String id, String newName) async {
    final planet = state.planets.where((p) => p.id == id).firstOrNull;
    if (planet == null) return;
    final updated = Planet(
      id: planet.id,
      name: newName,
      x: planet.x,
      y: planet.y,
      mass: planet.mass,
      parentStarId: planet.parentStarId,
      orbitRadius: planet.orbitRadius,
      orbitAngle: planet.orbitAngle,
      color: planet.color,
      wordCount: planet.wordCount,
      lastOpenedAt: planet.lastOpenedAt,
      visualState: planet.visualState,
      createdAt: planet.createdAt,
      updatedAt: DateTime.now(),
    );
    final result = await _repository.updatePlanet(updated);
    result.fold(
      (f) => state = state.copyWith(error: f),
      (_) => state = state.copyWith(
        planets: [...state.planets.where((p) => p.id != id), updated],
      ),
    );
  }

  /// Update the orbit radius for a planet or star (after drag-to-resize).
  Future<void> updateOrbitRadius(String id, String bodyType, double newRadius) async {
    if (bodyType == 'planet') {
      final planet = state.planets.cast<Planet?>().firstWhere(
        (p) => p!.id == id,
        orElse: () => null,
      );
      if (planet == null) return;
      final updated = Planet(
        id: planet.id,
        name: planet.name,
        x: planet.x,
        y: planet.y,
        mass: planet.mass,
        parentStarId: planet.parentStarId,
        orbitRadius: newRadius,
        orbitAngle: planet.orbitAngle,
        color: planet.color,
        wordCount: planet.wordCount,
        lastOpenedAt: planet.lastOpenedAt,
        visualState: planet.visualState,
        createdAt: planet.createdAt,
        updatedAt: DateTime.now(),
      );
      final result = await _repository.updatePlanet(updated);
      result.fold(
        (f) => state = state.copyWith(error: f),
        (_) => state = state.copyWith(
          planets: [...state.planets.where((p) => p.id != id), updated],
        ),
      );
    } else if (bodyType == 'star') {
      final star = state.stars.cast<Star?>().firstWhere(
        (s) => s!.id == id,
        orElse: () => null,
      );
      if (star == null) return;
      final updated = Star(
        id: star.id,
        name: star.name,
        x: star.x,
        y: star.y,
        mass: star.mass,
        parentBlackHoleId: star.parentBlackHoleId,
        orbitRadius: newRadius,
        orbitAngle: star.orbitAngle,
        color: star.color,
        createdAt: star.createdAt,
        updatedAt: DateTime.now(),
      );
      final result = await _repository.updateStar(updated);
      result.fold(
        (f) => state = state.copyWith(error: f),
        (_) => state = state.copyWith(
          stars: [...state.stars.where((s) => s.id != id), updated],
        ),
      );
    }
  }

  /// Add a moon to the given planet.
  Future<void> addMoon(String label, String parentPlanetId) async {
    try {
      final random = math.Random();
      final siblingCount =
          state.moons.where((m) => m.parentPlanetId == parentPlanetId).length;
      final orbitRadius = 40.0 + siblingCount * 20.0;
      final orbitAngle = random.nextDouble() * 360.0;
      final moon = Moon(
        id: generateId(),
        parentPlanetId: parentPlanetId,
        label: label,
        isCompleted: false,
        orbitRadius: orbitRadius,
        orbitAngle: orbitAngle,
      );
      final result = await _repository.insertMoon(moon);
      result.fold(
        (failure) => state = state.copyWith(error: failure),
        (_) => state = state.copyWith(
          moons: [...state.moons, moon],
        ),
      );
    } catch (e) {
      state = state.copyWith(error: CacheFailure('Failed to add moon: $e'));
    }
  }

  /// Toggle the completed state of a moon.
  Future<void> toggleMoonCompleted(String moonId) async {
    final moon = state.moons.where((m) => m.id == moonId).firstOrNull;
    if (moon == null) return;
    final updated = Moon(
      id: moon.id,
      parentPlanetId: moon.parentPlanetId,
      label: moon.label,
      isCompleted: !moon.isCompleted,
      orbitRadius: moon.orbitRadius,
      orbitAngle: moon.orbitAngle,
    );
    final result = await _repository.updateMoon(updated);
    result.fold(
      (f) => state = state.copyWith(error: f),
      (_) => state = state.copyWith(
        moons: [...state.moons.where((m) => m.id != moonId), updated],
      ),
    );
  }

  /// Delete a moon by id.
  Future<void> deleteMoon(String id) async {
    try {
      final result = await _repository.deleteMoon(id);
      result.fold(
        (failure) => state = state.copyWith(error: failure),
        (_) => state = state.copyWith(
          moons: state.moons.where((m) => m.id != id).toList(),
        ),
      );
    } catch (e) {
      state = state.copyWith(error: CacheFailure('Failed to delete moon: $e'));
    }
  }

  Future<void> deleteBlackHole(String id) async {
    try {
      final result = await _repository.deleteBlackHole(id);
      result.fold(
        (failure) => state = state.copyWith(error: failure),
        (_) {
          // Cascade removal from in-memory state
          final removedStarIds = state.stars
              .where((s) => s.parentBlackHoleId == id)
              .map((s) => s.id)
              .toSet();
          final removedPlanetIds = state.planets
              .where((p) => removedStarIds.contains(p.parentStarId))
              .map((p) => p.id)
              .toSet();
          state = state.copyWith(
            blackHoles: state.blackHoles.where((bh) => bh.id != id).toList(),
            stars: state.stars.where((s) => !removedStarIds.contains(s.id)).toList(),
            planets: state.planets.where((p) => !removedPlanetIds.contains(p.id)).toList(),
            moons: state.moons.where((m) => !removedPlanetIds.contains(m.parentPlanetId)).toList(),
          );
        },
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
        (_) {
          // Cascade removal from in-memory state
          final removedPlanetIds = state.planets
              .where((p) => p.parentStarId == id)
              .map((p) => p.id)
              .toSet();
          state = state.copyWith(
            stars: state.stars.where((s) => s.id != id).toList(),
            planets: state.planets.where((p) => !removedPlanetIds.contains(p.id)).toList(),
            moons: state.moons.where((m) => !removedPlanetIds.contains(m.parentPlanetId)).toList(),
          );
        },
      );
    } catch (e) {
      state = state.copyWith(error: CacheFailure('Failed to delete star: $e'));
    }
  }

  Future<void> deletePlanet(String id) async {
    try {
      // Cascade delete wormholes referencing this planet
      final wormholesResult = await _wormholeRepository.getWormholes();
      wormholesResult.fold((_) {}, (wormholes) async {
        for (final w in wormholes) {
          if (w.sourcePlanetId == id || w.targetPlanetId == id) {
            await _wormholeRepository.deleteWormhole(w.id);
          }
        }
      });

      // Cascade delete constellation links referencing this planet
      final linksResult = await _constellationRepository.getConstellationLinks();
      linksResult.fold((_) {}, (links) async {
        for (final l in links) {
          if (l.sourcePlanetId == id || l.targetPlanetId == id) {
            await _constellationRepository.deleteConstellationLink(l.id);
          }
        }
      });

      final result = await _repository.deletePlanet(id);
      result.fold(
        (failure) => state = state.copyWith(error: failure),
        (_) => state = state.copyWith(
          planets: state.planets.where((p) => p.id != id).toList(),
          moons: state.moons.where((m) => m.parentPlanetId != id).toList(),
        ),
      );
    } catch (e) {
      state = state.copyWith(error: CacheFailure('Failed to delete planet: $e'));
    }
  }

  /// Reparent a body by updating its parentId in place.
  Future<void> reparentBody(String bodyId, String newParentId) async {
    final star = state.stars.where((s) => s.id == bodyId).firstOrNull;
    if (star != null) {
      final newStar = Star(
        id: bodyId,
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
      final result = await _repository.updateStar(newStar);
      result.fold(
        (f) => state = state.copyWith(error: f),
        (_) => state = state.copyWith(
          stars: [...state.stars.where((s) => s.id != bodyId), newStar],
        ),
      );
      return;
    }

    final planet = state.planets.where((p) => p.id == bodyId).firstOrNull;
    if (planet != null) {
      final newPlanet = Planet(
        id: bodyId,
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
      final result = await _repository.updatePlanet(newPlanet);
      result.fold(
        (f) => state = state.copyWith(error: f),
        (_) => state = state.copyWith(
          planets: [...state.planets.where((p) => p.id != bodyId), newPlanet],
        ),
      );
    }
  }
}

final galaxyProvider =
    StateNotifierProvider<GalaxyNotifier, GalaxyState>((ref) {
  final repository = ref.watch(celestialBodyRepositoryProvider);
  final wormholeRepo = ref.watch(wormholeRepositoryProvider);
  final constellationRepo = ref.watch(constellationRepositoryProvider);
  return GalaxyNotifier(repository, wormholeRepo, constellationRepo);
});

/// Repository provider — wired to data layer via DI providers.
final celestialBodyRepositoryProvider =
    Provider<CelestialBodyRepository>((ref) {
  return ref.watch(celestialBodyRepositoryImplProvider);
});
