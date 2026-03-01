import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

/// Pulsing glow effect attached to a parent component.
/// Used for protostars and search highlights.
class GlowEffect extends PositionComponent {
  final Color glowColor;
  final double baseRadius;
  final double pulseAmplitude;
  final double pulseFrequency;

  double _timer = 0.0;

  GlowEffect({
    required this.glowColor,
    required this.baseRadius,
    this.pulseAmplitude = 8.0,
    this.pulseFrequency = 2.0,
    Vector2? position,
  }) : super(
          position: position ?? Vector2.zero(),
          size: Vector2.all((baseRadius + pulseAmplitude + 16) * 2),
          anchor: Anchor.center,
        );

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final pulse = math.sin(_timer * pulseFrequency * math.pi);
    final currentRadius = baseRadius + pulseAmplitude * pulse;
    final alpha = 0.2 + 0.15 * pulse;

    final paint = Paint()
      ..color = glowColor.withValues(alpha: alpha.clamp(0.0, 1.0))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, currentRadius * 0.4);

    canvas.drawCircle(center, currentRadius, paint);
  }
}
