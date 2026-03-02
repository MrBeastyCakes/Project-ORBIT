import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart';
import 'package:orbit_app/core/extensions/color_extensions.dart';
import 'package:orbit_app/domain/entities/planet.dart';
import 'package:orbit_app/presentation/game/components/galaxy_component.dart';
import 'package:orbit_app/presentation/game/effects/glow_effect.dart';
import 'package:orbit_app/presentation/game/orbit_game.dart';

class PlanetComponent extends PositionComponent
    with TapCallbacks, DragCallbacks, HasGameReference<OrbitGame> {
  Planet entity;

  static const double _baseRadius = 18.0;
  static const double _maxWordBonus = 8.0;

  /// Long-press threshold in seconds before drag activates.
  static const double _longPressThreshold = 0.5;

  double _pulseTimer = 0.0;
  GlowEffect? _glowEffect;

  /// When true, render a bright glow to indicate a search match.
  bool isHighlighted = false;

  /// When true, dim the planet (telescope mode, non-matching).
  bool isTelescopeDimmed = false;

  // ── Drag state ─────────────────────────────────────────────────────────────

  bool _isDragging = false;
  double _holdTimer = 0.0;
  bool _holdActive = false; // pointer is down, waiting for long-press

  /// Scale applied during drag for visual feedback (1.2x target).
  double _dragScale = 1.0;

  PlanetComponent({required this.entity})
      : super(
          position: Vector2(entity.x, entity.y),
          anchor: Anchor.center,
        ) {
    _updateSize();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (entity.visualState == PlanetVisualState.protostar) {
      _attachGlow();
    }
  }

  // ── Glow helpers ────────────────────────────────────────────────────────────

  void _attachGlow() {
    if (_glowEffect != null) return;
    final glow = GlowEffect(
      glowColor: const Color(0xFFFFD700), // golden
      baseRadius: _effectiveRadius,
      pulseAmplitude: 8.0,
      pulseFrequency: 1.8,
      position: Vector2(size.x / 2, size.y / 2),
    );
    _glowEffect = glow;
    add(glow);
  }

  void _detachGlow() {
    _glowEffect?.removeFromParent();
    _glowEffect = null;
  }

  // ── Visual state transition ─────────────────────────────────────────────────

  /// Called by [VisualStateSystem] when the derived state differs from the
  /// current one stored on the entity. Updates entity's visual state field and
  /// wires/unwires the GlowEffect accordingly.
  void applyVisualState(PlanetVisualState newState) {
    final oldState = entity.visualState;
    entity = Planet(
      id: entity.id,
      name: entity.name,
      x: entity.x,
      y: entity.y,
      mass: entity.mass,
      parentStarId: entity.parentStarId,
      orbitRadius: entity.orbitRadius,
      orbitAngle: entity.orbitAngle,
      color: entity.color,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      wordCount: entity.wordCount,
      lastOpenedAt: entity.lastOpenedAt,
      visualState: newState,
    );
    _updateSize();
    if (newState == PlanetVisualState.protostar &&
        oldState != PlanetVisualState.protostar) {
      _attachGlow();
    } else if (newState != PlanetVisualState.protostar &&
        oldState == PlanetVisualState.protostar) {
      _detachGlow();
    }
  }

  double get _effectiveRadius {
    final wordBonus = (entity.wordCount / 500).clamp(0.0, 1.0) * _maxWordBonus;
    double radius = _baseRadius + wordBonus;
    switch (entity.visualState) {
      case PlanetVisualState.gasGiant:
        radius *= 1.4;
      case PlanetVisualState.dwarfPlanet:
        radius *= 0.8;
      case PlanetVisualState.protostar:
      case PlanetVisualState.normal:
        break;
    }
    return radius;
  }

  void _updateSize() {
    final r = _effectiveRadius;
    size = Vector2.all((r + 6) * 2); // +6 for atmosphere
  }

  void updateEntity(Planet updated) {
    final oldState = entity.visualState;
    entity = updated;
    position = Vector2(updated.x, updated.y);
    _updateSize();
    if (updated.visualState == PlanetVisualState.protostar &&
        oldState != PlanetVisualState.protostar) {
      _attachGlow();
    } else if (updated.visualState != PlanetVisualState.protostar &&
        oldState == PlanetVisualState.protostar) {
      _detachGlow();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _pulseTimer += dt;

    // Long-press timer: orbit pauses on touch, drag activates after threshold.
    if (_holdActive && !_isDragging) {
      _holdTimer += dt;
      if (_holdTimer >= _longPressThreshold) {
        _beginDrag();
      }
    }

    // Animate drag scale toward target.
    final targetScale = _isDragging ? 1.2 : 1.0;
    _dragScale += (targetScale - _dragScale) * (dt * 10.0).clamp(0.0, 1.0);
  }

  /// Returns the current LOD level from the parent galaxy component.
  LodLevel get _lod => game.galaxyComponent.currentLod;

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final r = _effectiveRadius;
    final bodyColor = Color(entity.color);

    // LOD: galaxy view -- render as simple dot, skip all detail.
    if (_lod == LodLevel.galaxy) {
      final dotPaint = Paint()
        ..color = bodyColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, r * 0.6, dotPaint);
      return;
    }

    if (isTelescopeDimmed) {
      // Dim non-matching planets in telescope mode
      canvas.saveLayer(
        Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..color = const Color(0xFF000000).withValues(alpha: 0.0),
      );
      _renderByVisualState(canvas, center, r, bodyColor);
      // Apply dark overlay to reduce opacity
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()
          ..color = const Color(0xFF000000).withValues(alpha: 0.8)
          ..blendMode = BlendMode.srcOver,
      );
      canvas.restore();
      return;
    }

    // LOD: system view -- atmosphere but no labels (handled in render
    // methods that already don't draw labels at this level).

    canvas.save();

    // Apply drag scale around component center.
    if (_dragScale != 1.0) {
      canvas.translate(center.dx, center.dy);
      canvas.scale(_dragScale);
      canvas.translate(-center.dx, -center.dy);
    }

    // Drop shadow while dragging.
    if (_isDragging) {
      final shadowPaint = Paint()
        ..color = const Color(0x55000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(
        Offset(center.dx + 4, center.dy + 4),
        r + 2,
        shadowPaint,
      );
    }

    _renderByVisualState(canvas, center, r, bodyColor);

    canvas.restore();

    if (isHighlighted) {
      // Bright glow ring around matching planets
      final pulse = 0.7 + 0.3 * sin(_pulseTimer * 4.0);
      final glowPaint = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.6 * pulse)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10 + 4 * pulse);
      canvas.drawCircle(center, r + 8, glowPaint);

      final ringPaint = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.9 * pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(center, r + 4, ringPaint);
    }
  }

  void _renderByVisualState(Canvas canvas, Offset center, double r, Color bodyColor) {
    switch (entity.visualState) {
      case PlanetVisualState.protostar:
        _renderProtostar(canvas, center, r, bodyColor);
      case PlanetVisualState.gasGiant:
        _renderGasGiant(canvas, center, r, bodyColor);
      case PlanetVisualState.dwarfPlanet:
        _renderDwarfPlanet(canvas, center, r, bodyColor);
      case PlanetVisualState.normal:
        _renderNormal(canvas, center, r, bodyColor);
    }
  }

  void _renderNormal(Canvas canvas, Offset center, double r, Color color) {
    final atmPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, r + 6, atmPaint);

    final bodyPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, r, bodyPaint);
  }

  void _renderProtostar(Canvas canvas, Offset center, double r, Color color) {
    final pulse = 0.6 + 0.4 * sin(_pulseTimer * 3.0);

    // Inner canvas glow — golden hue. The GlowEffect child handles the outer.
    final glowPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.3 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(center, r + 8, glowPaint);

    // Slightly transparent body (opacity 0.7 range).
    final bodyPaint = Paint()
      ..color = color.withValues(alpha: 0.7 * pulse)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, r, bodyPaint);
  }

  void _renderGasGiant(Canvas canvas, Offset center, double r, Color color) {
    // Larger atmosphere aura.
    final auraPaint = Paint()
      ..color = color.withValues(alpha: 0.20)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, r + 10, auraPaint);

    // Clip to planet circle so bands don't bleed outside.
    canvas.save();
    canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: center, radius: r)));

    // 4 horizontal bands with slightly varying colors.
    final bandColors = [
      color,
      Color.lerp(color, const Color(0xFFFFAA44), 0.20)!,
      color.withValues(alpha: 0.80),
      Color.lerp(color, const Color(0xFF8844AA), 0.15)!,
    ];
    final bandHeight = (r * 2) / bandColors.length;
    final top = center.dy - r;
    for (int i = 0; i < bandColors.length; i++) {
      canvas.drawRect(
        Rect.fromLTWH(center.dx - r, top + i * bandHeight, r * 2, bandHeight),
        Paint()
          ..color = bandColors[i]
          ..style = PaintingStyle.fill,
      );
    }

    canvas.restore();
  }

  void _renderDwarfPlanet(Canvas canvas, Offset center, double r, Color color) {
    // Desaturate via extension, then add icy-blue tint.
    final desaturated = color.desaturated();
    const iceBlue = Color(0xFF88AACC);
    final icy = Color.lerp(desaturated, iceBlue, 0.30)!;

    // No atmosphere glow — just the bare cold body.
    final bodyPaint = Paint()
      ..color = icy
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, r, bodyPaint);
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (_isDragging) return;
    game.onBodyTapped?.call(
      entity.id,
      'planet',
      event.canvasPosition,
    );
  }

  // ── Drag callbacks ─────────────────────────────────────────────────────────

  @override
  bool onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    // Pause orbit so the body freezes — easier to long-press.
    _holdActive = true;
    _holdTimer = 0.0;
    game.orbitSystem.pause(entity.id);
    return true;
  }

  @override
  bool onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (!_isDragging) return true;
    position += event.localDelta;
    game.dragSystem?.updateDrag(position.clone());
    return true;
  }

  @override
  bool onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _holdActive = false;
    game.orbitSystem.resume(entity.id);

    if (!_isDragging) return true;
    _isDragging = false;

    final dragSystem = game.dragSystem;
    if (dragSystem == null) {
      reregisterAfterDrag();
      return true;
    }

    // Read the target parent before endDrag clears state.
    final targetParentId = dragSystem.currentTargetParentId;
    dragSystem.endDrag(position.clone());

    // Update entity with new parent + orbit radius from drag system callbacks.
    // Re-register with the (possibly new) parent.
    if (targetParentId != null && targetParentId != entity.parentStarId) {
      // Reparented — entity will be updated via the reparent callback path.
    }
    reregisterAfterDrag();
    return true;
  }

  @override
  bool onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _holdActive = false;
    game.orbitSystem.resume(entity.id);
    if (_isDragging) {
      _isDragging = false;
      game.dragSystem?.cancelDrag();
      reregisterAfterDrag();
    }
    return true;
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  void _beginDrag() {
    _isDragging = true;
    _holdActive = false;
    // Unregister from orbit/gravity so the body follows the finger.
    game.orbitSystem.unregister(entity.id);
    game.gravitySystem.unregister(entity.id);
    game.dragSystem?.startDragPlanet(
      entity.id, position.clone(), entity.parentStarId,
    );
  }

  /// Re-register this planet with the orbit and gravity systems after a drag
  /// ends without reparenting (snap-back case).
  void reregisterAfterDrag() {
    final orbitSystem = game.orbitSystem;
    orbitSystem.registerPlanet(
      component: this,
      id: entity.id,
      orbitRadius: entity.orbitRadius,
      getParentPosition: () =>
          game.galaxyComponent.getStar(entity.parentStarId)?.position ??
          Vector2.zero(),
    );
    orbitSystem.setGravityManaged(entity.id);
    game.gravitySystem.register(
      id: entity.id,
      mass: entity.mass,
      getBasePosition: () =>
          orbitSystem.basePositions[entity.id] ?? position,
      updatePosition: (x, y) => position = Vector2(x, y),
    );
  }
}
