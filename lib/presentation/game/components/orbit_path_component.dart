import 'dart:ui';

import 'package:flame/components.dart';

class OrbitPathComponent extends PositionComponent {
  final double orbitRadius;

  OrbitPathComponent({
    required Vector2 parentPosition,
    required this.orbitRadius,
  }) : super(
          position: parentPosition,
          size: Vector2.all(orbitRadius * 2 + 4),
          anchor: Anchor.center,
        );

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);

    final paint = Paint()
      ..color = const Color(0x14FFFFFF) // white at ~8% opacity
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Dashed circle
    const dashLength = 8.0;
    const gapLength = 6.0;
    const totalDash = dashLength + gapLength;
    final circumference = 2 * 3.14159265 * orbitRadius;
    final dashCount = (circumference / totalDash).floor();

    for (int i = 0; i < dashCount; i++) {
      final startAngle = (i * totalDash / orbitRadius);
      final sweepAngle = dashLength / orbitRadius;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: orbitRadius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }
}
