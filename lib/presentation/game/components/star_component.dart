import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart';
import 'package:orbit_app/domain/entities/star.dart';
import 'package:orbit_app/presentation/game/components/galaxy_component.dart';
import 'package:orbit_app/presentation/game/orbit_game.dart';

class StarComponent extends PositionComponent
    with TapCallbacks, DragCallbacks, HasGameReference<OrbitGame> {
  final Star entity;

  static const double _radius = 30.0;

  /// Long-press threshold in seconds before drag is activated.
  static const double _longPressThreshold = 0.5;

  double _pulseTimer = 0.0;

  /// Set by DragSystem to indicate this star is a valid drop target.
  bool isDragTarget = false;

  // ── Drag state ─────────────────────────────────────────────────────────────

  bool _isDragging = false;
  double _holdTimer = 0.0;
  bool _holdActive = false;

  // Scale factor applied during drag for visual feedback.
  double _dragScale = 1.0;

  StarComponent({required this.entity})
      : super(
          position: Vector2(entity.x, entity.y),
          size: Vector2.all(_radius * 2 + 20),
          anchor: Anchor.center,
        );

  @override
  void update(double dt) {
    super.update(dt);
    _pulseTimer += dt;

    // Long-press timer: accumulate while pointer is held.
    if (_holdActive && !_isDragging) {
      _holdTimer += dt;
      if (_holdTimer >= _longPressThreshold) {
        _beginDrag();
      }
    }

    // Animate drag scale.
    final targetScale = _isDragging ? 1.15 : 1.0;
    _dragScale += (targetScale - _dragScale) * (dt * 10.0).clamp(0.0, 1.0);
  }

  /// Returns the current LOD level from the parent galaxy component.
  LodLevel get _lod => game.galaxyComponent.currentLod;

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);

    // LOD: galaxy view -- render as small bright circle, skip glow/gradient.
    if (_lod == LodLevel.galaxy) {
      final dotPaint = Paint()
        ..color = const Color(0xFFFFEE88)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, _radius * 0.5, dotPaint);
      return;
    }

    final pulseOpacity = 0.3 + 0.15 * sin(_pulseTimer * 2.0);

    canvas.save();
    // Apply drag scale around center.
    if (_dragScale != 1.0) {
      canvas.translate(center.dx, center.dy);
      canvas.scale(_dragScale);
      canvas.translate(-center.dx, -center.dy);
    }

    // Drop shadow during drag.
    if (_isDragging) {
      final shadowPaint = Paint()
        ..color = const Color(0x66000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
      canvas.drawCircle(
        Offset(center.dx + 6, center.dy + 6),
        _radius + 4,
        shadowPaint,
      );
    }

    // Radial gradient glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Color(0xFFFFFFFF).withValues(alpha: pulseOpacity),
          Color(0xFFFFDD88).withValues(alpha: pulseOpacity * 0.5),
          const Color(0x00FFDD88),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: _radius + 10));
    canvas.drawCircle(center, _radius + 10, glowPaint);

    // Star body
    final bodyPaint = Paint()
      ..color = const Color(0xFFFFEE88)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, _radius, bodyPaint);

    canvas.restore();

    // Drag-target highlight rendered outside the scale transform so it stays
    // at a consistent visual size.
    if (isDragTarget) {
      final highlightPaint = Paint()
        ..color = const Color(0x88FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(center, _radius + 14, highlightPaint);
    }
  }

  // ── Tap ────────────────────────────────────────────────────────────────────

  @override
  void onTapUp(TapUpEvent event) {
    if (_isDragging) return;
    game.onBodyTapped?.call(
      entity.id,
      'star',
      event.canvasPosition,
    );
  }

  // ── Drag callbacks ─────────────────────────────────────────────────────────

  @override
  bool onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    // Begin holding the timer; drag only activates after long-press threshold.
    _holdActive = true;
    _holdTimer = 0.0;
    return true;
  }

  @override
  bool onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (!_isDragging) return true;

    // Move the component.
    final delta = event.localDelta;
    position += delta;

    // Also move all child planets to follow the star.
    final dragSystem = game.dragSystem;
    if (dragSystem != null) {
      for (final planet in dragSystem.planets.values) {
        if (planet.entity.parentStarId == entity.id) {
          planet.position += delta;
        }
      }
      dragSystem.updateDrag(position.clone());
    }

    return true;
  }

  @override
  bool onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _holdActive = false;
    if (!_isDragging) return true;

    _isDragging = false;
    game.dragSystem?.endDrag(position.clone());
    return true;
  }

  @override
  bool onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _holdActive = false;
    if (_isDragging) {
      _isDragging = false;
      game.dragSystem?.cancelDrag();
    }
    return true;
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  void _beginDrag() {
    _isDragging = true;
    _holdActive = false;
    final dragSystem = game.dragSystem;
    if (dragSystem != null) {
      dragSystem.startDragStar(entity.id, position.clone());
    }
  }
}
