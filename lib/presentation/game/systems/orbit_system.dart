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

  void registerStar({
    required StarComponent component,
    required String id,
    required double orbitRadius,
    required double parentX,
    required double parentY,
    double initialAngle = 0.0,
  }) {
    _angles[id] = initialAngle;
    _entries.removeWhere((e) => e.id == id);
    _entries.add(_OrbitalEntry(
      id: id,
      orbitRadius: orbitRadius,
      parentX: parentX,
      parentY: parentY,
      updatePosition: (x, y) => component.position = Vector2(x, y),
    ));
  }

  void registerPlanet({
    required PlanetComponent component,
    required String id,
    required double orbitRadius,
    required double parentX,
    required double parentY,
    double initialAngle = 0.0,
  }) {
    _angles[id] = initialAngle;
    _entries.removeWhere((e) => e.id == id);
    _entries.add(_OrbitalEntry(
      id: id,
      orbitRadius: orbitRadius,
      parentX: parentX,
      parentY: parentY,
      updatePosition: (x, y) => component.position = Vector2(x, y),
    ));
  }

  void registerMoon({
    required MoonComponent component,
    required String id,
    required double orbitRadius,
    required double parentX,
    required double parentY,
    double initialAngle = 0.0,
  }) {
    _angles[id] = initialAngle;
    _entries.removeWhere((e) => e.id == id);
    _entries.add(_OrbitalEntry(
      id: id,
      orbitRadius: orbitRadius,
      parentX: parentX,
      parentY: parentY,
      updatePosition: (x, y) => component.position = Vector2(x, y),
    ));
  }

  void unregister(String id) {
    _angles.remove(id);
    _entries.removeWhere((e) => e.id == id);
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
      // Skip orbit updates for bodies whose parent center is far off-screen.
      // The parent position + orbitRadius defines the furthest possible location.
      if (!rect.inflate(entry.orbitRadius).contains(
            Offset(entry.parentX, entry.parentY),
          )) {
        continue;
      }
      final speed = _orbitSpeed(entry.orbitRadius);
      _angles[entry.id] = (_angles[entry.id]! + speed * dt) % 360.0;
      final rad = _angles[entry.id]! * math.pi / 180.0;
      final x = entry.parentX + entry.orbitRadius * math.cos(rad);
      final y = entry.parentY + entry.orbitRadius * math.sin(rad);
      entry.updatePosition(x, y);
    }
  }
}

class _OrbitalEntry {
  final String id;
  final double orbitRadius;
  final double parentX;
  final double parentY;
  final void Function(double x, double y) updatePosition;

  const _OrbitalEntry({
    required this.id,
    required this.orbitRadius,
    required this.parentX,
    required this.parentY,
    required this.updatePosition,
  });
}
