import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:orbit_app/presentation/game/components/moon_component.dart';
import 'package:orbit_app/presentation/game/components/planet_component.dart';
import 'package:orbit_app/presentation/game/components/star_component.dart';

/// Kepler-inspired orbit system: inner orbits faster.
/// orbitSpeed = baseSpeed / sqrt(orbitRadius / referenceRadius)
class OrbitSystem extends Component with HasGameReference<FlameGame> {
  static const double _baseSpeed = 30.0; // degrees per second at reference
  static const double _referenceRadius = 200.0;

  /// Padding beyond the visible viewport for orbit updates (world units).
  static const double _orbitCullPadding = 400.0;

  /// Orbit angles in degrees, keyed by entity id.
  final Map<String, double> _angles = {};

  /// Registered orbital bodies.
  final List<_OrbitalEntry> _entries = [];

  /// Base positions calculated by orbit (before gravity perturbation).
  final Map<String, Vector2> basePositions = {};

  /// IDs of bodies whose final position is managed by the gravity system.
  final Set<String> _gravityManaged = {};

  /// IDs of bodies whose orbit rotation is paused (touch-held).
  final Set<String> _paused = {};

  /// Pause orbit rotation for a body (e.g. while touch-held).
  void pause(String id) => _paused.add(id);

  /// Resume orbit rotation for a body.
  void resume(String id) => _paused.remove(id);

  /// Mark a body as gravity-managed (orbit calculates base, gravity sets final pos).
  void setGravityManaged(String id) => _gravityManaged.add(id);

  void clearGravityManaged(String id) => _gravityManaged.remove(id);

  void registerStar({
    required StarComponent component,
    required String id,
    required double orbitRadius,
    required Vector2 Function() getParentPosition,
    double initialAngle = 0.0,
  }) {
    _angles[id] = initialAngle;
    _entries.removeWhere((e) => e.id == id);
    _entries.add(_OrbitalEntry(
      id: id,
      orbitRadius: orbitRadius,
      getParentPosition: getParentPosition,
      updatePosition: (x, y) => component.position = Vector2(x, y),
    ));
  }

  void registerPlanet({
    required PlanetComponent component,
    required String id,
    required double orbitRadius,
    required Vector2 Function() getParentPosition,
    double initialAngle = 0.0,
  }) {
    _angles[id] = initialAngle;
    _entries.removeWhere((e) => e.id == id);
    _entries.add(_OrbitalEntry(
      id: id,
      orbitRadius: orbitRadius,
      getParentPosition: getParentPosition,
      updatePosition: (x, y) => component.position = Vector2(x, y),
    ));
  }

  void registerMoon({
    required MoonComponent component,
    required String id,
    required double orbitRadius,
    required Vector2 Function() getParentPosition,
    double initialAngle = 0.0,
  }) {
    _angles[id] = initialAngle;
    _entries.removeWhere((e) => e.id == id);
    _entries.add(_OrbitalEntry(
      id: id,
      orbitRadius: orbitRadius,
      getParentPosition: getParentPosition,
      updatePosition: (x, y) => component.position = Vector2(x, y),
    ));
  }

  /// Update the orbit radius for a registered body (e.g. after drag-to-resize).
  void updateOrbitRadius(String id, double newRadius) {
    for (final entry in _entries) {
      if (entry.id == id) {
        entry.orbitRadius = newRadius;
        return;
      }
    }
  }

  void unregister(String id) {
    _angles.remove(id);
    _entries.removeWhere((e) => e.id == id);
    basePositions.remove(id);
    _gravityManaged.remove(id);
    _paused.remove(id);
  }

  double _orbitSpeed(double orbitRadius) {
    if (orbitRadius <= 0) return _baseSpeed;
    return _baseSpeed / math.sqrt(orbitRadius / _referenceRadius);
  }

  /// Returns the expanded visible rect used for orbit culling.
  Rect _visibleRect() {
    final cam = game.camera;
    final zoom = cam.viewfinder.zoom;
    final pos = cam.viewfinder.position;
    final viewport = cam.viewport;
    final halfW = viewport.size.x / (2 * zoom);
    final halfH = viewport.size.y / (2 * zoom);
    return Rect.fromLTRB(
      pos.x - halfW - _orbitCullPadding,
      pos.y - halfH - _orbitCullPadding,
      pos.x + halfW + _orbitCullPadding,
      pos.y + halfH + _orbitCullPadding,
    );
  }

  @override
  void update(double dt) {
    final rect = _visibleRect();
    for (final entry in _entries) {
      final parentPos = entry.getParentPosition();
      // Skip orbit updates for bodies whose parent center is far off-screen.
      // The parent position + orbitRadius defines the furthest possible location.
      if (!rect.inflate(entry.orbitRadius).contains(
            Offset(parentPos.x, parentPos.y),
          )) {
        continue;
      }
      // Skip angle advancement if paused (touch-held).
      if (!_paused.contains(entry.id)) {
        final speed = _orbitSpeed(entry.orbitRadius);
        _angles[entry.id] = (_angles[entry.id]! + speed * dt) % 360.0;
      }
      final rad = _angles[entry.id]! * math.pi / 180.0;
      final x = parentPos.x + entry.orbitRadius * math.cos(rad);
      final y = parentPos.y + entry.orbitRadius * math.sin(rad);
      // Store base position for gravity system to read.
      basePositions[entry.id] = Vector2(x, y);
      // Only set component position if NOT gravity-managed.
      if (!_gravityManaged.contains(entry.id)) {
        entry.updatePosition(x, y);
      }
    }
  }
}

class _OrbitalEntry {
  final String id;
  double orbitRadius;
  final Vector2 Function() getParentPosition;
  final void Function(double x, double y) updatePosition;

  _OrbitalEntry({
    required this.id,
    required this.orbitRadius,
    required this.getParentPosition,
    required this.updatePosition,
  });
}
