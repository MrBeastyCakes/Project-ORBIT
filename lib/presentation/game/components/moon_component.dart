import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:orbit_app/domain/entities/moon.dart';
import 'package:orbit_app/presentation/game/components/galaxy_component.dart';
import 'package:orbit_app/presentation/game/orbit_game.dart';

class MoonComponent extends PositionComponent with HasGameReference<OrbitGame> {
  Moon entity;

  static const double _radius = 5.0;

  // Landing animation state.
  bool _isLanding = false;
  double _landingElapsed = 0.0;
  static const double _landingDuration = 1.0;
  double _landingStartOrbitRadius = 0.0;

  // Current animated orbit radius (may differ from entity.orbitRadius during
  // the landing animation).
  double _currentOrbitRadius = 0.0;
  double _opacity = 1.0;

  MoonComponent({required this.entity})
      : super(
          position: Vector2.zero(),
          size: Vector2.all(_radius * 2),
          anchor: Anchor.center,
        ) {
    _currentOrbitRadius = entity.orbitRadius;
  }

  void updateEntity(Moon updated) {
    entity = updated;
    if (!_isLanding) {
      _currentOrbitRadius = updated.orbitRadius;
    }
  }

  /// Start the "landing" animation: orbit radius shrinks to 0, moon fades out,
  /// then the component removes itself.
  void triggerLanding() {
    if (_isLanding) return;
    _isLanding = true;
    _landingElapsed = 0.0;
    _landingStartOrbitRadius = _currentOrbitRadius;
  }

  /// Update position based on parent's world position and the current
  /// (possibly animated) orbit radius.
  void updateOrbitalPosition(double parentX, double parentY) {
    final rad = entity.orbitAngle * math.pi / 180.0;
    position = Vector2(
      parentX + _currentOrbitRadius * math.cos(rad),
      parentY + _currentOrbitRadius * math.sin(rad),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_isLanding) {
      _landingElapsed += dt;
      final t = (_landingElapsed / _landingDuration).clamp(0.0, 1.0);
      _currentOrbitRadius = _landingStartOrbitRadius * (1.0 - t);
      _opacity = (1.0 - t).clamp(0.0, 1.0);
      if (t >= 1.0) {
        removeFromParent();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (_opacity <= 0.0) return;

    // LOD: skip moons at galaxy and system zoom levels.
    final lod = game.galaxyComponent.currentLod;
    if (lod == LodLevel.galaxy || lod == LodLevel.system) return;

    final center = Offset(size.x / 2, size.y / 2);

    if (entity.isCompleted) {
      // Completed: dimmer body with a checkmark.
      final paint = Paint()
        ..color = const Color(0xFFCCCCCC).withValues(alpha: 0.4 * _opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, _radius, paint);

      final checkPaint = Paint()
        ..color =
            const Color(0xFF44FF88).withValues(alpha: 0.9 * _opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      final path = Path()
        ..moveTo(center.dx - 2.5, center.dy)
        ..lineTo(center.dx - 0.5, center.dy + 2.0)
        ..lineTo(center.dx + 2.5, center.dy - 2.0);
      canvas.drawPath(path, checkPaint);
    } else {
      // Incomplete: bright circle with a small center dot.
      final paint = Paint()
        ..color = const Color(0xFFCCCCCC).withValues(alpha: _opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, _radius, paint);

      final dotPaint = Paint()
        ..color = const Color(0xFF333355).withValues(alpha: _opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, 1.5, dotPaint);
    }
  }
}
