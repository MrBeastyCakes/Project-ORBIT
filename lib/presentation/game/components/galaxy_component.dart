import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:orbit_app/domain/entities/asteroid.dart';
import 'package:orbit_app/domain/entities/black_hole.dart';
import 'package:orbit_app/domain/entities/constellation_link.dart';
import 'package:orbit_app/domain/entities/moon.dart';
import 'package:orbit_app/domain/entities/planet.dart';
import 'package:orbit_app/domain/entities/star.dart';
import 'package:orbit_app/domain/entities/wormhole.dart';
import 'package:orbit_app/presentation/game/components/asteroid_component.dart';
import 'package:orbit_app/presentation/game/components/black_hole_component.dart';
import 'package:orbit_app/presentation/game/components/constellation_line.dart';
import 'package:orbit_app/presentation/game/components/moon_component.dart';
import 'package:orbit_app/presentation/game/components/nebula_component.dart';
import 'package:orbit_app/presentation/game/components/planet_component.dart';
import 'package:orbit_app/presentation/game/components/star_component.dart';
import 'package:orbit_app/presentation/game/components/wormhole_component.dart';
import 'package:orbit_app/presentation/game/effects/supernova_effect.dart';

/// Level-of-detail tier determined by current camera zoom.
enum LodLevel { galaxy, system, planet }

class GalaxyComponent extends Component with HasGameReference<FlameGame> {
  final Map<String, BlackHoleComponent> _blackHoles = {};
  final Map<String, StarComponent> _stars = {};
  final Map<String, PlanetComponent> _planets = {};
  final Map<String, MoonComponent> _moons = {};
  final Map<String, AsteroidComponent> _asteroids = {};
  final Map<String, WormholeComponent> _wormholes = {};
  final Map<String, ConstellationLine> _constellationLines = {};

  /// Maps constellation link id → (sourcePlanetId, targetPlanetId) for
  /// position tracking in [updateConstellationPositions].
  final Map<String, (String, String)> _constellationPlanetIds = {};

  // ── Tidal lock data ──────────────────────────────────────────────────────────

  /// Pairs of planet IDs that are tidally locked (stored as domain links with
  /// a naming convention: the link id starts with "tidal_").
  final List<(String, String)> _tidalLockPairs = [];

  // ── Viewport culling & LOD ────────────────────────────────────────────────

  /// Padding (in world units) beyond the visible rect before culling.
  static const double _cullPadding = 200.0;

  /// Current LOD tier, updated each frame from camera zoom.
  LodLevel currentLod = LodLevel.system;

  /// The visible world rect expanded by [_cullPadding], recalculated each frame.
  Rect _visibleRect = Rect.zero;

  /// Returns true if [worldPos] is within (or near) the camera viewport.
  bool isInViewport(Vector2 worldPos) {
    return _visibleRect.contains(Offset(worldPos.x, worldPos.y));
  }

  /// Recalculates [_visibleRect] and [currentLod] from the current camera.
  void updateViewportAndLod() {
    final cam = game.camera;
    final zoom = cam.viewfinder.zoom;
    final pos = cam.viewfinder.position;
    final viewport = cam.viewport;
    final halfW = viewport.size.x / (2 * zoom);
    final halfH = viewport.size.y / (2 * zoom);

    _visibleRect = Rect.fromLTRB(
      pos.x - halfW - _cullPadding,
      pos.y - halfH - _cullPadding,
      pos.x + halfW + _cullPadding,
      pos.y + halfH + _cullPadding,
    );

    if (zoom < 0.2) {
      currentLod = LodLevel.galaxy;
    } else if (zoom < 1.0) {
      currentLod = LodLevel.system;
    } else {
      currentLod = LodLevel.planet;
    }
  }

  // ── Loading ─────────────────────────────────────────────────────────────────

  Future<void> loadBodies({
    List<BlackHole> blackHoles = const [],
    List<Star> stars = const [],
    List<Planet> planets = const [],
    List<Moon> moons = const [],
    List<Asteroid> asteroids = const [],
    List<Wormhole> wormholes = const [],
    List<ConstellationLink> constellationLinks = const [],
  }) async {
    for (final bh in blackHoles) {
      await addBlackHole(bh);
    }
    for (final s in stars) {
      await addStar(s);
    }
    for (final p in planets) {
      await addPlanet(p);
    }
    for (final m in moons) {
      await addMoon(m);
    }
    for (final a in asteroids) {
      await addAsteroid(a);
    }
    for (final w in wormholes) {
      await addWormhole(w);
    }
    for (final cl in constellationLinks) {
      await addConstellationLink(cl);
    }
  }

  // ── Black holes ─────────────────────────────────────────────────────────────

  Future<void> addBlackHole(BlackHole entity) async {
    if (_blackHoles.containsKey(entity.id)) return;
    final component = BlackHoleComponent(entity: entity);
    _blackHoles[entity.id] = component;
    await add(component);
  }

  void removeBlackHole(String id) {
    final component = _blackHoles.remove(id);
    component?.removeFromParent();
  }

  // ── Stars ───────────────────────────────────────────────────────────────────

  Future<void> addStar(Star entity) async {
    if (_stars.containsKey(entity.id)) return;
    final component = StarComponent(entity: entity);
    _stars[entity.id] = component;
    await add(component);
  }

  void removeStar(String id) {
    final component = _stars.remove(id);
    component?.removeFromParent();
  }

  // ── Planets ─────────────────────────────────────────────────────────────────

  Future<void> addPlanet(Planet entity) async {
    if (_planets.containsKey(entity.id)) return;
    final component = PlanetComponent(entity: entity);
    _planets[entity.id] = component;
    await add(component);
  }

  /// Remove a planet with a supernova + nebula effect at its position.
  void removePlanet(String id) {
    final component = _planets.remove(id);
    if (component == null) return;
    final pos = component.position.clone();
    component.removeFromParent();
    _spawnDeletionEffect(pos);
  }

  /// Remove a planet immediately without any visual effect (e.g. on reload).
  void removePlanetSilent(String id) {
    final component = _planets.remove(id);
    component?.removeFromParent();
  }

  // ── Moons ───────────────────────────────────────────────────────────────────

  /// Add a moon and attach it as a child of its parent [PlanetComponent] so it
  /// orbits in planet-local space. Falls back to adding to the galaxy directly
  /// when the parent planet is not yet loaded.
  Future<void> addMoon(Moon entity) async {
    if (_moons.containsKey(entity.id)) return;
    final component = MoonComponent(entity: entity);
    _moons[entity.id] = component;

    final parent = _planets[entity.parentPlanetId];
    if (parent != null) {
      await parent.add(component);
    } else {
      await add(component);
    }
  }

  void removeMoon(String id) {
    final component = _moons.remove(id);
    component?.removeFromParent();
  }

  /// Trigger the landing animation on a moon and remove it from the registry.
  /// The [MoonComponent] removes itself from the tree once the animation ends.
  void toggleMoonCompleted(String id) {
    final component = _moons[id];
    if (component == null) return;
    component.triggerLanding();
    // Remove from registry immediately so it won't be operated on again.
    _moons.remove(id);
  }

  // ── Asteroids ───────────────────────────────────────────────────────────────

  Future<void> addAsteroid(Asteroid entity) async {
    if (_asteroids.containsKey(entity.id)) return;
    final component = AsteroidComponent(entity: entity);
    _asteroids[entity.id] = component;
    await add(component);
  }

  void removeAsteroid(String id) {
    final component = _asteroids.remove(id);
    component?.removeFromParent();
  }

  // ── Wormholes ────────────────────────────────────────────────────────────────

  /// Creates a [WormholeComponent] positioned on the source planet's surface
  /// and stores the target reference.
  Future<void> addWormhole(Wormhole entity) async {
    if (_wormholes.containsKey(entity.id)) return;

    final sourcePlanet = _planets[entity.sourcePlanetId];
    final targetPlanet = _planets[entity.targetPlanetId];
    final position =
        sourcePlanet?.position.clone() ?? Vector2.zero();
    final targetName = targetPlanet?.entity.name ?? entity.targetPlanetId;

    final component = WormholeComponent(
      position: position,
      sourcePlanetId: entity.sourcePlanetId,
      targetPlanetId: entity.targetPlanetId,
      targetPlanetName: targetName,
    );
    _wormholes[entity.id] = component;
    await add(component);
  }

  /// Removes the wormhole with the given [id] from the scene.
  void removeWormhole(String id) {
    final component = _wormholes.remove(id);
    component?.removeFromParent();
  }

  // ── Constellation links ──────────────────────────────────────────────────────

  /// Creates a [ConstellationLine] between the two planets referenced by
  /// [entity].  Tidal-lock links (id prefixed with "tidal_") get the
  /// [ConstellationLineType.tidalLock] style.
  Future<void> addConstellationLink(ConstellationLink entity) async {
    if (_constellationLines.containsKey(entity.id)) return;

    final planetA = _planets[entity.sourcePlanetId];
    final planetB = _planets[entity.targetPlanetId];
    final posA = planetA?.position.clone() ?? Vector2.zero();
    final posB = planetB?.position.clone() ?? Vector2.zero();

    final isTidal = entity.id.startsWith('tidal_');
    if (isTidal) {
      _tidalLockPairs.add((entity.sourcePlanetId, entity.targetPlanetId));
    }

    final line = ConstellationLine(
      startPosition: posA,
      endPosition: posB,
      lineType: isTidal
          ? ConstellationLineType.tidalLock
          : ConstellationLineType.constellation,
    );
    _constellationLines[entity.id] = line;
    _constellationPlanetIds[entity.id] =
        (entity.sourcePlanetId, entity.targetPlanetId);
    await add(line);
  }

  /// Removes the constellation line with [id] from the scene.
  void removeConstellationLink(String id) {
    final line = _constellationLines.remove(id);
    line?.removeFromParent();
    final ids = _constellationPlanetIds.remove(id);
    if (ids != null) {
      _tidalLockPairs.remove(ids);
    }
  }

  /// Updates all constellation line positions to track their planets.
  /// Call once per frame — positions change as planets orbit.
  void updateConstellationPositions() {
    for (final entry in _constellationLines.entries) {
      final line = entry.value;
      final ids = _constellationPlanetIds[entry.key];
      if (ids == null) continue;
      final posA = _planets[ids.$1]?.position;
      final posB = _planets[ids.$2]?.position;
      if (posA != null && posB != null) {
        line.updatePositions(posA.clone(), posB.clone());
      }
    }
  }

  // ── Deletion effect ─────────────────────────────────────────────────────────

  /// Spawn a [SupernovaEffect] at [position]; when it finishes (~1.8 s) a
  /// [NebulaComponent] takes its place and fades over 5 s.
  void _spawnDeletionEffect(Vector2 position) {
    final supernova = SupernovaEffect(position: position.clone());

    // Wrap in a coordinator component that spawns the nebula on completion.
    final coordinator = _DeletionCoordinator(
      position: position.clone(),
      onSupernovaDone: () => add(NebulaComponent(position: position.clone())),
    );

    add(supernova);
    add(coordinator);
  }

  // ── Accessors ───────────────────────────────────────────────────────────────

  BlackHoleComponent? getBlackHole(String id) => _blackHoles[id];
  StarComponent? getStar(String id) => _stars[id];
  PlanetComponent? getPlanet(String id) => _planets[id];
  MoonComponent? getMoon(String id) => _moons[id];
  AsteroidComponent? getAsteroid(String id) => _asteroids[id];

  /// All planet components — used by [VisualStateSystem].
  Iterable<PlanetComponent> get allPlanets => _planets.values;

  /// Keyed planet map — used by telescope mode and [CollisionSystem].
  Map<String, PlanetComponent> get allPlanetComponents =>
      Map.unmodifiable(_planets);

  /// Alias used by [AsteroidComponent] for collision checks.
  Map<String, PlanetComponent> get planetsMap => Map.unmodifiable(_planets);

  /// Star IDs — used by [AsteroidComponent] for promotion proximity checks.
  Iterable<String> get starIds => _stars.keys;

  /// Returns all tidally locked planet ID pairs.
  List<(String, String)> getTidalLockedPairs() =>
      List.unmodifiable(_tidalLockPairs);

  /// Star component map — used by [DragSystem].
  Map<String, StarComponent> get starsMap => Map.unmodifiable(_stars);

  /// Black-hole component map — used by [DragSystem].
  Map<String, BlackHoleComponent> get blackHolesMap =>
      Map.unmodifiable(_blackHoles);
}

// ── Helper ───────────────────────────────────────────────────────────────────

/// Waits for the supernova lifetime to elapse, then fires [onSupernovaDone]
/// and removes itself.  This avoids coupling [SupernovaEffect] to the galaxy.
class _DeletionCoordinator extends Component {
  static const double _supernovaLifetime = 1.8;

  final void Function() onSupernovaDone;
  double _elapsed = 0.0;
  bool _fired = false;

  _DeletionCoordinator({
    required Vector2 position,
    required this.onSupernovaDone,
  });

  @override
  void update(double dt) {
    if (_fired) return;
    _elapsed += dt;
    if (_elapsed >= _supernovaLifetime) {
      _fired = true;
      onSupernovaDone();
      removeFromParent();
    }
  }
}
