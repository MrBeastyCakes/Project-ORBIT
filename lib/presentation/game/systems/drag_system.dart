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

  /// ID of the body's original parent (star for planets, black hole for stars).
  final String originalParentId;

  /// ID of the parent currently being targeted (may change during drag).
  String currentTargetParentId;

  _DragState({
    required this.id,
    required this.type,
    required this.originalPosition,
    required this.originalParentId,
  }) : currentTargetParentId = originalParentId;
}

/// Ghost orbit path rendered around the current/nearest parent while dragging.
/// Radius dynamically follows the dragged body's distance from the parent.
class _GhostOrbitComponent extends Component {
  Vector2 center;
  double radius = 80.0;
  bool visible = false;

  _GhostOrbitComponent({required this.center});

  @override
  void render(Canvas canvas) {
    if (!visible) return;
    // Outer glow ring.
    final glowPaint = Paint()
      ..color = const Color(0x22FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(center.x, center.y), radius, glowPaint);

    // Crisp orbit line.
    final paint = Paint()
      ..color = const Color(0x55FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(center.x, center.y), radius, paint);
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

  // ── Callbacks ─────────────────────────────────────────────────────────────

  /// Fired when a body's orbit radius changes (same parent, new distance).
  void Function(String bodyId, String bodyType, double newRadius)?
      onOrbitRadiusChanged;

  // ── Public API ────────────────────────────────────────────────────────────

  bool get isDragging => _active != null;

  /// The parent ID currently targeted during drag (for external reading).
  String? get currentTargetParentId => _active?.currentTargetParentId;

  /// Begin dragging [planetId] from its current world [position].
  /// [currentParentId] is the planet's current parent star id.
  void startDragPlanet(String planetId, Vector2 position, String currentParentId) {
    _active = _DragState(
      id: planetId,
      type: DragBodyType.planet,
      originalPosition: position.clone(),
      originalParentId: currentParentId,
    );
    _highlightStars(true);
    // Show ghost orbit immediately at current distance.
    _updateGhostForPlanet(position);
  }

  /// Begin dragging [starId] from its current world [position].
  /// [currentParentId] is the star's current parent black hole id.
  void startDragStar(String starId, Vector2 position, String currentParentId) {
    _active = _DragState(
      id: starId,
      type: DragBodyType.star,
      originalPosition: position.clone(),
      originalParentId: currentParentId,
    );
    _highlightBlackHoles(true);
    _updateGhostForStar(position);
  }

  /// Called every frame during drag with the current world [position].
  /// Updates ghost orbit and swaps parent target if a closer valid parent is nearby.
  void updateDrag(Vector2 position) {
    if (_active == null) return;
    if (_active!.type == DragBodyType.planet) {
      _updateGhostForPlanet(position);
    } else {
      _updateGhostForStar(position);
    }
  }

  /// Resolves the drop: reparents if target changed, otherwise updates orbit radius.
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

  /// Cancel drag — snaps body back to original position.
  void cancelDrag() {
    final state = _active;
    if (state == null) return;
    _ghost.visible = false;
    _active = null;
    _highlightStars(false);
    _highlightBlackHoles(false);

    if (state.type == DragBodyType.planet) {
      planets[state.id]?.position = state.originalPosition.clone();
    } else {
      stars[state.id]?.position = state.originalPosition.clone();
    }
  }

  // ── Ghost orbit updates ─────────────────────────────────────────────────

  void _updateGhostForPlanet(Vector2 bodyPos) {
    final state = _active!;
    // Find the nearest star. If within snap range, target it; otherwise keep current.
    final nearest = _nearestStar(bodyPos);
    if (nearest != null) {
      final dist = bodyPos.distanceTo(nearest.position);
      if (dist <= planetSnapRange || nearest.entity.id == state.currentTargetParentId) {
        state.currentTargetParentId = nearest.entity.id;
      }
    }
    // Show ghost centered on the target parent.
    final targetStar = stars[state.currentTargetParentId];
    if (targetStar != null) {
      _ghost.center = targetStar.position.clone();
      _ghost.radius = bodyPos.distanceTo(targetStar.position).clamp(30.0, 600.0);
      _ghost.visible = true;
    } else {
      _ghost.visible = false;
    }
  }

  void _updateGhostForStar(Vector2 bodyPos) {
    final state = _active!;
    final nearest = _nearestBlackHole(bodyPos);
    if (nearest != null) {
      final dist = bodyPos.distanceTo(nearest.position);
      if (dist <= starSnapRange || nearest.entity.id == state.currentTargetParentId) {
        state.currentTargetParentId = nearest.entity.id;
      }
    }
    final targetBh = blackHoles[state.currentTargetParentId];
    if (targetBh != null) {
      _ghost.center = targetBh.position.clone();
      _ghost.radius = bodyPos.distanceTo(targetBh.position).clamp(60.0, 800.0);
      _ghost.visible = true;
    } else {
      _ghost.visible = false;
    }
  }

  // ── Drop resolution ───────────────────────────────────────────────────────

  void _resolvePlanetDrop(_DragState state, Vector2 dropPosition) {
    final planetComp = planets[state.id];
    if (planetComp == null) return;

    final targetStar = stars[state.currentTargetParentId];
    if (targetStar == null) return;

    final newRadius = dropPosition.distanceTo(targetStar.position).clamp(30.0, 600.0);
    final reparented = state.currentTargetParentId != state.originalParentId;

    if (reparented) {
      onReparentPlanet?.call(state.id, state.currentTargetParentId);
    }

    // Always fire orbit radius changed (covers both reparent and same-parent adjust).
    onOrbitRadiusChanged?.call(state.id, 'planet', newRadius);
  }

  void _resolveStarDrop(_DragState state, Vector2 dropPosition) {
    final starComp = stars[state.id];
    if (starComp == null) return;

    final targetBh = blackHoles[state.currentTargetParentId];
    if (targetBh == null) return;

    final newRadius = dropPosition.distanceTo(targetBh.position).clamp(60.0, 800.0);
    final reparented = state.currentTargetParentId != state.originalParentId;

    if (reparented) {
      onReparentStar?.call(state.id, state.currentTargetParentId);
    }

    onOrbitRadiusChanged?.call(state.id, 'star', newRadius);
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


