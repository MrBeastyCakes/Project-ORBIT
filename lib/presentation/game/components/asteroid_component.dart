import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:orbit_app/domain/entities/asteroid.dart';
import 'package:orbit_app/presentation/game/components/galaxy_component.dart';
import 'package:orbit_app/presentation/game/components/planet_component.dart';
import 'package:orbit_app/presentation/game/orbit_game.dart';
import 'package:orbit_app/presentation/game/systems/collision_system.dart';

/// Callback types used to communicate accretion events to the galaxy layer.
typedef AsteroidAccretionCallback = void Function(
    String asteroidId, String planetId);
typedef AsteroidPromoteCallback = void Function(
    String asteroidId, String starId);

class AsteroidComponent extends PositionComponent
    with DragCallbacks, HasGameReference<OrbitGame> {
  final Asteroid entity;

  /// Called when the asteroid is dropped onto a planet.
  AsteroidAccretionCallback? onAccrete;

  /// Called when the asteroid is dropped near a star's orbit for promotion.
  AsteroidPromoteCallback? onPromote;

  static const double _radius = 4.0;
  static const double _driftSpeed = 6.0; // world units / second
  static const double _attractionSpeed = 80.0; // world units / second when near planet

  final _collision = CollisionSystem();

  /// Gentle drift velocity applied when not being dragged.
  late Vector2 _velocity;

  /// Current pulse phase for the twinkle animation.
  double _pulseTimer = 0.0;

  /// Whether the asteroid is currently being dragged by the user.
  bool _isDragging = false;

  /// If within attraction range of a planet, this holds the planet position.
  Vector2? _attractionTarget;

  AsteroidComponent({
    required this.entity,
    this.onAccrete,
    this.onPromote,
  }) : super(
          position: Vector2(entity.x, entity.y),
          size: Vector2.all(_radius * 2 + 8),
          anchor: Anchor.center,
        ) {
    // Random slow drift direction
    final rng = math.Random();
    final angle = rng.nextDouble() * 2 * math.pi;
    _velocity = Vector2(
      math.cos(angle) * _driftSpeed,
      math.sin(angle) * _driftSpeed,
    );
  }

  // ---------------------------------------------------------------------------
  // Update
  // ---------------------------------------------------------------------------

  @override
  void update(double dt) {
    super.update(dt);

    // LOD: skip physics at galaxy/system zoom levels.
    final lod = game.galaxyComponent.currentLod;
    if (lod == LodLevel.galaxy || lod == LodLevel.system) return;

    _pulseTimer += dt;

    if (_isDragging) return;

    // Check for attraction target (nearest planet within accretion range).
    final planets = _galaxyPlanets();
    final target = _collision.findAccretionTarget(position, planets);

    if (target != null) {
      _attractionTarget = target.position.clone();
      // Accelerate toward planet
      final dir = (target.position - position)..normalize();
      position += dir * _attractionSpeed * dt;
    } else {
      _attractionTarget = null;
      // Normal slow drift
      position += _velocity * dt;
    }
  }

  // ---------------------------------------------------------------------------
  // Drag
  // ---------------------------------------------------------------------------

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _isDragging = true;
    _attractionTarget = null;
    event.continuePropagation = false;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    // event.localDelta is in component-local space; convert to world delta.
    // For a component with no rotation, local delta == world delta / zoom.
    final zoom = game.camera.viewfinder.zoom;
    position += event.localDelta / zoom;
    event.continuePropagation = false;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _isDragging = false;
    event.continuePropagation = false;

    final planets = _galaxyPlanets();
    final planetTarget = _collision.findAccretionTarget(position, planets);
    if (planetTarget != null) {
      onAccrete?.call(entity.id, planetTarget.entity.id);
      return;
    }

    // Check proximity to star orbits for promotion
    final nearStarId = _findNearbyStarOrbit();
    if (nearStarId != null) {
      onPromote?.call(entity.id, nearStarId);
    }
  }

  // ---------------------------------------------------------------------------
  // Render
  // ---------------------------------------------------------------------------

  @override
  void render(Canvas canvas) {
    // LOD: skip asteroids at galaxy/system zoom levels.
    final lod = game.galaxyComponent.currentLod;
    if (lod == LodLevel.galaxy || lod == LodLevel.system) return;

    final cx = size.x / 2;
    final cy = size.y / 2;

    // Pulse / twinkle: scale between 0.8 and 1.1
    final pulse = 0.9 + 0.15 * math.sin(_pulseTimer * 2.5);

    // Attraction glow when near a planet
    if (_attractionTarget != null) {
      final glowPaint = Paint()
        ..color = const Color(0x554499FF)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(cx, cy), _radius * 2.5, glowPaint);
    }

    // Irregular polygon approximating an asteroid shape
    const points = 7;
    final path = Path();
    for (int i = 0; i < points; i++) {
      final angle = (2 * math.pi / points) * i - math.pi / 2;
      final variance = (i % 3 == 0) ? 0.65 : ((i % 2 == 0) ? 0.85 : 1.0);
      final r = _radius * variance * pulse;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    final paint = Paint()
      ..color = const Color(0xFF8899AA)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);

    // Label: show truncated asteroid text when zoomed in close (zoom > 1.5)
    final zoom = game.camera.viewfinder.zoom;
    if (zoom > 1.5 && entity.text.isNotEmpty) {
      final label = entity.text.length > 20
          ? '${entity.text.substring(0, 20)}\u2026'
          : entity.text;
      final paragraphBuilder = ParagraphBuilder(
        ParagraphStyle(
          fontSize: 7,
          textAlign: TextAlign.center,
          fontFamily: 'sans-serif',
        ),
      )
        ..pushStyle(TextStyle(color: const Color(0xAAFFFFFF)))
        ..addText(label);
      final paragraph = paragraphBuilder.build()
        ..layout(ParagraphConstraints(width: 80));
      canvas.drawParagraph(
        paragraph,
        Offset(cx - 40, cy + _radius + 4),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Map<String, PlanetComponent> _galaxyPlanets() {
    return game.galaxyComponent.planetsMap;
  }

  /// Returns the ID of the nearest star if the asteroid is within
  /// star-orbit promotion distance (~120 world units of the star center).
  String? _findNearbyStarOrbit() {
    const promotionDistance = 120.0;
    final galaxy = game.galaxyComponent;
    for (final starId in galaxy.starIds) {
      final star = galaxy.getStar(starId);
      if (star == null) continue;
      final dist = position.distanceTo(star.position);
      if (dist < promotionDistance) {
        return starId;
      }
    }
    return null;
  }
}
