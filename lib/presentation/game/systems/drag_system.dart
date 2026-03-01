import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import 'package:orbit_app/presentation/game/components/black_hole_component.dart';
import 'package:orbit_app/presentation/game/components/planet_component.dart';
import 'package:orbit_app/presentation/game/components/star_component.dart';

/// Tracks what is currently being dragged.
enum DragBodyType { planet, star }

/// Holds state for an active drag operation.
class _DragState {
  final String id;
  final DragBodyType type;
  final Vector2 originalPosition;

  _DragState({
    required this.id,
    required this.type,
    required this.originalPosition,
  });
}

/// Ghost orbit path rendered around the nearest valid drop target while
/// dragging.
class _GhostOrbitComponent extends Component {
  static const double _orbitRadius = 80.0;
  Vector2 center;
  bool visible = false;

  _GhostOrbitComponent({required this.center});

  @override
  void render(Canvas canvas) {
    if (!visible) return;
    final paint = Paint()
      ..color = const Color(0x44FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(
      Offset(center.x, center.y),
      _orbitRadius,
      paint,
    );
  }
}

/// Manages the state of a drag operation:
/// - Highlights valid drop targets
/// - Renders a ghost orbit path near the nearest valid target
/// - Resolves drop: reparent or snap-back
///
/// Usage: add to the game world, call [startDragPlanet] / [startDragStar]
/// from the component's long-press, [updateDrag] on pointer move, and
/// [endDrag] on pointer up.
class DragSystem extends Component {
  /// World units — planet drops within this range of a star reparent.
  static const double planetSnapRange = 100.0;

  /// World units — star drops within this range of a black hole reparent.
  static const double starSnapRange = 150.0;

  // ── External data refs (set by OrbitGame after mounting) ──────────────────

  /// All star components keyed by star id — set by OrbitGame.
  Map<String, StarComponent> stars = {};

  /// All black-hole components keyed by id — set by OrbitGame.
  Map<String, BlackHoleComponent> blackHoles = {};

  /// All planet components keyed by id — set by OrbitGame.
  Map<String, PlanetComponent> planets = {};

  // ── Callbacks ─────────────────────────────────────────────────────────────

  /// Fired when a planet is successfully dropped onto a different star.
  void Function(String planetId, String newStarId)? onReparentPlanet;

  /// Fired when a star is successfully dropped onto a different black hole.
  void Function(String starId, String newBlackHoleId)? onReparentStar;

  // ── Internal state ────────────────────────────────────────────────────────

  _DragState? _active;
  final _GhostOrbitComponent _ghost =
      _GhostOrbitComponent(center: Vector2.zero());

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await add(_ghost);
  }

  // ── Public API ────────────────────────────────────────────────────────────

  bool get isDragging => _active != null;

  /// Begin dragging [planetId] from its current world [position].
  void startDragPlanet(String planetId, Vector2 position) {
    _active = _DragState(
      id: planetId,
      type: DragBodyType.planet,
      originalPosition: position.clone(),
    );
    _highlightStars(true);
  }

  /// Begin dragging [starId] from its current world [position].
  void startDragStar(String starId, Vector2 position) {
    _active = _DragState(
      id: starId,
      type: DragBodyType.star,
      originalPosition: position.clone(),
    );
    _highlightBlackHoles(true);
  }

  /// Called every frame during drag with the current world [position] of the
  /// dragged body.  Updates the ghost orbit toward the nearest valid target.
  void updateDrag(Vector2 position) {
    if (_active == null) return;
    if (_active!.type == DragBodyType.planet) {
      final nearest = _nearestStar(position);
      if (nearest != null) {
        _ghost.center = nearest.position.clone();
        _ghost.visible = true;
      } else {
        _ghost.visible = false;
      }
    } else {
      final nearest = _nearestBlackHole(position);
      if (nearest != null) {
        _ghost.center = nearest.position.clone();
        _ghost.visible = true;
      } else {
        _ghost.visible = false;
      }
    }
  }

  /// Called when the pointer is released at world [position].
  /// Resolves the drop: reparents or snaps back.
  void endDrag(Vector2 dropPosition) {
    final state = _active;
    if (state == null) return;

    _ghost.visible = false;
    _active = null;

    if (state.type == DragBodyType.planet) {
      _highlightStars(false);
      _resolvePlanetDrop(state, dropPosition);
    } else {
      _highlightBlackHoles(false);
      _resolveStarDrop(state, dropPosition);
    }
  }

  /// Cancel drag without resolving — snaps body back to original position.
  void cancelDrag() {
    final state = _active;
    if (state == null) return;
    _ghost.visible = false;
    _active = null;
    _highlightStars(false);
    _highlightBlackHoles(false);

    if (state.type == DragBodyType.planet) {
      final comp = planets[state.id];
      comp?.position = state.originalPosition.clone();
    } else {
      final comp = stars[state.id];
      comp?.position = state.originalPosition.clone();
    }
  }

  // ── Drop resolution ───────────────────────────────────────────────────────

  void _resolvePlanetDrop(_DragState state, Vector2 dropPosition) {
    final planetComp = planets[state.id];
    if (planetComp == null) return;

    // Find the nearest star within snap range.
    StarComponent? best;
    double bestDist = double.infinity;
    for (final star in stars.values) {
      final d = dropPosition.distanceTo(star.position);
      if (d < bestDist) {
        bestDist = d;
        best = star;
      }
    }

    if (best != null && bestDist <= planetSnapRange) {
      // Check if it's actually a different star.
      final currentStarId = planetComp.entity.parentStarId;
      if (best.entity.id != currentStarId) {
        onReparentPlanet?.call(state.id, best.entity.id);
        // Smoothly animate to new orbit angle based on drop position.
        _animatePlanetToOrbit(planetComp, best.position, dropPosition);
        return;
      }
    }

    // Snap back.
    _animateSnap(planetComp, state.originalPosition);
  }

  void _resolveStarDrop(_DragState state, Vector2 dropPosition) {
    final starComp = stars[state.id];
    if (starComp == null) return;

    BlackHoleComponent? best;
    double bestDist = double.infinity;
    for (final bh in blackHoles.values) {
      final d = dropPosition.distanceTo(bh.position);
      if (d < bestDist) {
        bestDist = d;
        best = bh;
      }
    }

    if (best != null && bestDist <= starSnapRange) {
      final currentBhId = starComp.entity.parentBlackHoleId;
      if (best.entity.id != currentBhId) {
        onReparentStar?.call(state.id, best.entity.id);
        _animateStarToOrbit(starComp, best.position, dropPosition);
        return;
      }
    }

    // Snap back.
    _animateSnap(starComp, state.originalPosition);
  }

  // ── Orbit angle animation helpers ─────────────────────────────────────────

  /// Moves [comp] toward [targetParentCenter] in an arc based on the angle
  /// derived from [dropWorldPos].  This is a simple lerp-based approach so
  /// the body eases into its new orbit position.
  void _animatePlanetToOrbit(
    PlanetComponent comp,
    Vector2 targetParentCenter,
    Vector2 dropWorldPos,
  ) {
    final delta = dropWorldPos - targetParentCenter;
    final orbitRadius = comp.entity.orbitRadius.clamp(60.0, double.infinity);
    final angle = math.atan2(delta.y, delta.x);
    final targetPos = targetParentCenter +
        Vector2(math.cos(angle) * orbitRadius, math.sin(angle) * orbitRadius);
    _smoothMove(comp, targetPos, 0.4);
  }

  void _animateStarToOrbit(
    StarComponent comp,
    Vector2 targetParentCenter,
    Vector2 dropWorldPos,
  ) {
    final delta = dropWorldPos - targetParentCenter;
    final orbitRadius = comp.entity.orbitRadius.clamp(100.0, double.infinity);
    final angle = math.atan2(delta.y, delta.x);
    final targetPos = targetParentCenter +
        Vector2(math.cos(angle) * orbitRadius, math.sin(angle) * orbitRadius);
    _smoothMove(comp, targetPos, 0.4);
  }

  void _animateSnap(PositionComponent comp, Vector2 target) {
    _smoothMove(comp, target, 0.3);
  }

  /// Schedules a simple lerp move on [comp] toward [target] over [duration]s.
  void _smoothMove(PositionComponent comp, Vector2 target, double duration) {
    comp.add(
      _LerpMoveEffect(target: target.clone(), duration: duration),
    );
  }

  // ── Highlight helpers ─────────────────────────────────────────────────────

  void _highlightStars(bool on) {
    for (final s in stars.values) {
      s.isDragTarget = on;
    }
  }

  void _highlightBlackHoles(bool on) {
    for (final bh in blackHoles.values) {
      bh.isDragTarget = on;
    }
  }

  // ── Nearest-target helpers ────────────────────────────────────────────────

  StarComponent? _nearestStar(Vector2 pos) {
    StarComponent? best;
    double bestDist = double.infinity;
    for (final s in stars.values) {
      final d = pos.distanceTo(s.position);
      if (d < bestDist) {
        bestDist = d;
        best = s;
      }
    }
    return best;
  }

  BlackHoleComponent? _nearestBlackHole(Vector2 pos) {
    BlackHoleComponent? best;
    double bestDist = double.infinity;
    for (final bh in blackHoles.values) {
      final d = pos.distanceTo(bh.position);
      if (d < bestDist) {
        bestDist = d;
        best = bh;
      }
    }
    return best;
  }
}

// ── Lerp move effect ──────────────────────────────────────────────────────────

/// A simple position lerp effect added as a child of a [PositionComponent].
class _LerpMoveEffect extends Component {
  final Vector2 target;
  final double duration;
  double _elapsed = 0.0;
  Vector2? _start;

  _LerpMoveEffect({required this.target, required this.duration});

  @override
  void onMount() {
    _start = (parent as PositionComponent).position.clone();
  }

  @override
  void update(double dt) {
    _elapsed += dt;
    final t = (_elapsed / duration).clamp(0.0, 1.0);
    final eased = t * t * (3.0 - 2.0 * t); // smoothstep
    final comp = parent as PositionComponent;
    comp.position = Vector2(
      _start!.x + (_start!.x - target.x).abs() > 0.1
          ? _lerp(_start!.x, target.x, eased)
          : target.x,
      _start!.y + (_start!.y - target.y).abs() > 0.1
          ? _lerp(_start!.y, target.y, eased)
          : target.y,
    );
    if (t >= 1.0) removeFromParent();
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;
}
