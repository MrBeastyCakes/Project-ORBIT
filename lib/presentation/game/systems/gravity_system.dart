import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:orbit_app/presentation/game/orbit_game.dart';

/// N-body gravitational perturbation system.
///
/// Each registered body has a "base position" set by the orbit system and a
/// perturbation offset caused by gravitational pull from other bodies.
/// The final rendered position = base position + perturbation.
/// A spring-damper pulls perturbation back toward zero so orbits stay stable.
class GravitySystem extends Component with HasGameReference<OrbitGame> {
  /// Gravitational constant (tune for feel, not realism).
  static const double _G = 800.0;

  /// Spring stiffness pulling perturbation back to zero.
  static const double _springK = 3.0;

  /// Damping factor on perturbation velocity (0 = undamped, higher = more damped).
  static const double _damping = 4.0;

  /// Minimum distance squared to prevent force explosion at close range.
  static const double _minDistSq = 2500.0; // 50^2

  /// Maximum perturbation magnitude (world units) to keep orbits bounded.
  static const double _maxPerturbation = 60.0;

  final List<_GravityBody> _bodies = [];

  /// Register a body for gravitational interaction.
  void register({
    required String id,
    required double mass,
    required Vector2 Function() getBasePosition,
    required void Function(double x, double y) updatePosition,
  }) {
    _bodies.removeWhere((b) => b.id == id);
    _bodies.add(_GravityBody(
      id: id,
      mass: mass,
      getBasePosition: getBasePosition,
      updatePosition: updatePosition,
    ));
  }

  void unregister(String id) {
    _bodies.removeWhere((b) => b.id == id);
  }

  @override
  void update(double dt) {
    if (_bodies.length < 2) {
      // Still apply base positions even with a single body.
      for (final body in _bodies) {
        final base = body.getBasePosition();
        body.updatePosition(
            base.x + body.perturbation.x, base.y + body.perturbation.y);
      }
      return;
    }

    // Clamp dt to prevent instability on lag spikes.
    final clampedDt = dt.clamp(0.0, 0.05);

    // 1. Calculate gravitational forces between all pairs.
    // Reset accelerations.
    for (final body in _bodies) {
      body.acceleration.setZero();
    }

    for (int i = 0; i < _bodies.length; i++) {
      final a = _bodies[i];
      final posA = a.getBasePosition() + a.perturbation;

      for (int j = i + 1; j < _bodies.length; j++) {
        final b = _bodies[j];
        final posB = b.getBasePosition() + b.perturbation;

        final dx = posB.x - posA.x;
        final dy = posB.y - posA.y;
        var distSq = dx * dx + dy * dy;
        if (distSq < _minDistSq) distSq = _minDistSq;

        final dist = math.sqrt(distSq);
        final forceMag = _G * a.mass * b.mass / distSq;

        // Unit direction from a to b.
        final nx = dx / dist;
        final ny = dy / dist;

        // Apply force (F = ma → a = F/m).
        a.acceleration.x += forceMag * nx / a.mass;
        a.acceleration.y += forceMag * ny / a.mass;
        b.acceleration.x -= forceMag * nx / b.mass;
        b.acceleration.y -= forceMag * ny / b.mass;
      }
    }

    // 2. Apply spring-damper toward zero perturbation + gravitational acceleration.
    for (final body in _bodies) {
      // Spring force: pulls perturbation back to (0,0).
      final springX = -_springK * body.perturbation.x;
      final springY = -_springK * body.perturbation.y;

      // Damping force: resists velocity.
      final dampX = -_damping * body.velocity.x;
      final dampY = -_damping * body.velocity.y;

      // Total acceleration on perturbation.
      final totalAx = body.acceleration.x + springX + dampX;
      final totalAy = body.acceleration.y + springY + dampY;

      // Integrate velocity.
      body.velocity.x += totalAx * clampedDt;
      body.velocity.y += totalAy * clampedDt;

      // Integrate perturbation.
      body.perturbation.x += body.velocity.x * clampedDt;
      body.perturbation.y += body.velocity.y * clampedDt;

      // Clamp perturbation magnitude.
      final mag = body.perturbation.length;
      if (mag > _maxPerturbation) {
        body.perturbation.scale(_maxPerturbation / mag);
        // Remove the outward component of velocity to prevent bouncing.
        // pHat is the unit vector in the perturbation direction (after clamp).
        final pHat = body.perturbation.normalized();
        final dot = body.velocity.dot(pHat);
        if (dot > 0) {
          // Subtract the outward projection: v -= (v·pHat) * pHat
          body.velocity.sub(pHat.scaled(dot));
        }
      }

      // 3. Final position = base + perturbation.
      final base = body.getBasePosition();
      body.updatePosition(
        base.x + body.perturbation.x,
        base.y + body.perturbation.y,
      );
    }
  }
}

class _GravityBody {
  final String id;
  final double mass;
  final Vector2 Function() getBasePosition;
  final void Function(double x, double y) updatePosition;

  /// Current offset from the orbit-system's base position.
  final Vector2 perturbation = Vector2.zero();

  /// Velocity of the perturbation offset.
  final Vector2 velocity = Vector2.zero();

  /// Accumulated gravitational acceleration this frame.
  final Vector2 acceleration = Vector2.zero();

  _GravityBody({
    required this.id,
    required this.mass,
    required this.getBasePosition,
    required this.updatePosition,
  });
}
