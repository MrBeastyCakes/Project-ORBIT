import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

class _Particle {
  Offset position;
  Offset velocity;
  double life; // 1 -> 0
  final double maxSize;
  final Color color;

  _Particle({
    required this.position,
    required this.velocity,
    required this.life,
    required this.maxSize,
    required this.color,
  });
}

class SupernovaEffect extends PositionComponent {
  static const double _lifetime = 1.8;
  static const int _particleCount = 60;

  double _elapsed = 0.0;
  final List<_Particle> _particles = [];
  final math.Random _rng = math.Random();

  SupernovaEffect({required Vector2 position})
      : super(
          position: position,
          size: Vector2.all(300),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _spawnParticles();
  }

  void _spawnParticles() {
    const colors = [
      Color(0xFFFFFFFF),
      Color(0xFFFFEE88),
      Color(0xFFFF8833),
      Color(0xFFFF4400),
    ];

    for (int i = 0; i < _particleCount; i++) {
      final angle = _rng.nextDouble() * 2 * math.pi;
      final speed = 60 + _rng.nextDouble() * 140;
      final color = colors[_rng.nextInt(colors.length)];
      _particles.add(_Particle(
        position: Offset(size.x / 2, size.y / 2),
        velocity: Offset(math.cos(angle) * speed, math.sin(angle) * speed),
        life: 1.0,
        maxSize: 2 + _rng.nextDouble() * 5,
        color: color,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;

    final progress = (_elapsed / _lifetime).clamp(0.0, 1.0);
    for (final p in _particles) {
      p.position += p.velocity * dt;
      p.life = (1.0 - progress);
      // Slow down particles over time
      p.velocity *= (1.0 - dt * 1.5);
    }

    if (_elapsed >= _lifetime) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    for (final p in _particles) {
      if (p.life <= 0) continue;
      final paint = Paint()
        ..color = p.color.withValues(alpha: p.life)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p.position, p.maxSize * p.life, paint);
    }
  }
}
