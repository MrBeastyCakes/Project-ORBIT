import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:orbit_app/domain/entities/black_hole.dart';
import 'package:orbit_app/presentation/game/components/galaxy_component.dart';
import 'package:orbit_app/presentation/game/orbit_game.dart';

class BlackHoleComponent extends PositionComponent with TapCallbacks, HasGameReference<OrbitGame> {
  final BlackHole entity;

  static const double _radius = 50.0;
  static const double _ringWidth = 12.0;

  /// Set by DragSystem to indicate this black hole is a valid drop target.
  bool isDragTarget = false;

  BlackHoleComponent({required this.entity})
      : super(
          position: Vector2(entity.x, entity.y),
          size: Vector2.all((_radius + _ringWidth) * 2),
          anchor: Anchor.center,
        );

  /// Returns the current LOD level from the parent galaxy component.
  LodLevel get _lod => game.galaxyComponent.currentLod;

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);

    // LOD: galaxy view -- simple dark circle, no glow/ring.
    if (_lod == LodLevel.galaxy) {
      final bodyPaint = Paint()
        ..color = const Color(0xFF000000)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, _radius * 0.6, bodyPaint);
      // Thin accent ring
      final ringPaint = Paint()
        ..color = const Color(0x66BF00FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(center, _radius * 0.6 + 3, ringPaint);
      return;
    }

    // Accretion disk glow (outer ring)
    final glowPaint = Paint()
      ..color = const Color(0x44BF00FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _ringWidth * 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawCircle(center, _radius + _ringWidth / 2, glowPaint);

    // Accretion disk ring
    final ringPaint = Paint()
      ..color = const Color(0xFFBF00FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _ringWidth * 0.5;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: _radius + _ringWidth / 2),
      0,
      2 * pi,
      false,
      ringPaint,
    );

    // Dark body
    final bodyPaint = Paint()
      ..color = const Color(0xFF000000)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, _radius, bodyPaint);

    // Drag-target highlight: bright outer glow ring
    if (isDragTarget) {
      final highlightPaint = Paint()
        ..color = const Color(0x88FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(center, _radius + _ringWidth + 4, highlightPaint);
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    game.onBodyTapped?.call(
      entity.id,
      'blackHole',
      event.canvasPosition,
    );
  }
}
