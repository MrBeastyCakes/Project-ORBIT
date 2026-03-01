import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart' show SweepGradient;
import 'package:orbit_app/presentation/game/orbit_game.dart';

class WormholeComponent extends PositionComponent
    with TapCallbacks, HasGameReference<OrbitGame> {
  final String sourcePlanetId;
  final String targetPlanetId;
  final String targetPlanetName;

  static const double _outerRadius = 20.0;
  static const double _innerRadius = 12.0;

  double _animTimer = 0.0;

  /// Called when the wormhole is tapped; passes [targetPlanetId].
  void Function(String targetPlanetId)? onWormholeTapped;

  WormholeComponent({
    required Vector2 position,
    required this.sourcePlanetId,
    required this.targetPlanetId,
    required this.targetPlanetName,
    this.onWormholeTapped,
  }) : super(
          position: position,
          size: Vector2.all(_outerRadius * 2 + 16),
          anchor: Anchor.center,
        );

  @override
  void update(double dt) {
    super.update(dt);
    _animTimer += dt;
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);

    // Pulse factor: 0..1 oscillating
    final pulse = 0.5 + 0.5 * math.sin(_animTimer * 2.5);

    // Outer ambient glow
    final glowPaint = Paint()
      ..color = const Color(0xFF00FFEE).withValues(alpha: 0.25 + 0.15 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(center, _outerRadius + 2 * pulse, glowPaint);

    // Cyan outer ring — pulses in radius slightly
    final ringPaint = Paint()
      ..color = const Color(0xFF00FFEE).withValues(alpha: 0.7 + 0.3 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, _outerRadius, ringPaint);

    // Inner swirling gradient ring (rotates over time)
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(_animTimer * 1.8);

    final sweepPaint = Paint()
      ..shader = SweepGradient(
        colors: const [
          Color(0x0000FFEE),
          Color(0xAA00FFEE),
          Color(0x0000FFEE),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(
        Rect.fromCircle(center: Offset.zero, radius: _innerRadius),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    canvas.drawCircle(Offset.zero, _innerRadius + 1, sweepPaint);

    canvas.restore();

    // Inner dark portal
    final innerPaint = Paint()
      ..color = const Color(0xFF000510)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, _innerRadius, innerPaint);

    // Destination label "→ PlanetName" below the wormhole
    final paragraphStyle = ParagraphStyle(
      textAlign: TextAlign.center,
      fontSize: 9,
    );
    final builder = ParagraphBuilder(paragraphStyle)
      ..pushStyle(
        TextStyle(
          color: const Color(0xFF00FFEE).withValues(alpha: 0.85),
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      )
      ..addText('\u2192 $targetPlanetName');
    final paragraph = builder.build()
      ..layout(ParagraphConstraints(width: 80));

    canvas.drawParagraph(
      paragraph,
      Offset(center.dx - 40, center.dy + _outerRadius + 4),
    );
  }

  @override
  void onTapUp(TapUpEvent event) {
    onWormholeTapped?.call(targetPlanetId);
    game.onWormholeTapped?.call(targetPlanetId);
  }
}
