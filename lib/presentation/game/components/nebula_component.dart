import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

class _Particle {
  Offset position;
  Offset velocity;
  double life; // 0..1
  double size;
  Color color;

  _Particle({
    required this.position,
    required this.velocity,
    required this.life,
    required this.size,
    required this.color,
  });
}

class NebulaComponent extends PositionComponent {
  static const double _lifetime = 5.0;
  static const int _particleCount = 40;

  double _elapsed = 0.0;
  final List<_Particle> _particles = [];
  final math.Random _rng = math.Random();

  NebulaComponent({required Vector2 position})
      : super(
          position: position,
          size: Vector2.all(200),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _spawnParticles();
  }

  void _spawnParticles() {
    for (int i = 0; i < _particleCount; i++) {
      final angle = _rng.nextDouble() * 2 * math.pi;
      final speed = 20 + _rng.nextDouble() * 60;
      final color = _rng.nextBool()
          ? const Color(0xFFFFAA44)
          : const Color(0xFFFFFFFF);
      _particles.add(_Particle(
        position: Offset(size.x / 2, size.y / 2),
        velocity: Offset(math.cos(angle) * speed, math.sin(angle) * speed),
        life: 1.0,
        size: 2 + _rng.nextDouble() * 4,
        color: color,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;

    for (final p in _particles) {
      p.position += p.velocity * dt;
      p.life = (1.0 - _elapsed / _lifetime).clamp(0.0, 1.0);
    }

    if (_elapsed >= _lifetime) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    for (final p in _particles) {
      final paint = Paint()
        ..color = p.color.withValues(alpha: p.life)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p.position, p.size * p.life, paint);
    }
  }
}
