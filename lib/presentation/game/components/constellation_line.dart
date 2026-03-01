import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

/// Whether this link is a regular constellation backlink or a tidal lock.
enum ConstellationLineType {
  /// Faint glowing curved line between linked planets.
  constellation,

  /// Thicker, brighter line between tidally locked planet pairs.
  tidalLock,
}

/// A curved glowing line drawn between two world-space positions.
///
/// Positions must be updated every frame via [updatePositions] since the
/// planets move as they orbit.  The component lives in world space (added
/// directly to [GalaxyComponent]) so [startPosition] / [endPosition] are
/// already in world coordinates.
class ConstellationLine extends Component {
  Vector2 startPosition;
  Vector2 endPosition;

  final ConstellationLineType lineType;

  double _animTimer = 0.0;

  ConstellationLine({
    required this.startPosition,
    required this.endPosition,
    this.lineType = ConstellationLineType.constellation,
  });

  void updatePositions(Vector2 start, Vector2 end) {
    startPosition = start.clone();
    endPosition = end.clone();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _animTimer += dt;
  }

  @override
  void render(Canvas canvas) {
    final start = Offset(startPosition.x, startPosition.y);
    final end = Offset(endPosition.x, endPosition.y);

    // Pulsing opacity: oscillates between 0.5 and 1.0 of base alpha.
    final pulse = 0.5 + 0.5 * math.sin(_animTimer * 1.4);

    if (lineType == ConstellationLineType.tidalLock) {
      _renderTidalLockLine(canvas, start, end, pulse);
    } else {
      _renderConstellationLine(canvas, start, end, pulse);
    }
  }

  // ── Rendering helpers ────────────────────────────────────────────────────────

  void _renderConstellationLine(
      Canvas canvas, Offset start, Offset end, double pulse) {
    // Control point slightly perpendicular to midpoint for a gentle curve.
    final ctrl = _bezierControl(start, end, curvature: 0.15);
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy);

    // Soft glow pass.
    final glowAlpha = (0x22 * pulse).round().clamp(0, 255);
    final glowPaint = Paint()
      ..color = Color.fromARGB(glowAlpha, 0xAA, 0xCC, 0xFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(path, glowPaint);

    // Crisp line pass — semi-transparent white with slight blue tint.
    final lineAlpha = (0x44 * pulse).round().clamp(0, 255);
    final linePaint = Paint()
      ..color = Color.fromARGB(lineAlpha, 0xAA, 0xCC, 0xFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(path, linePaint);
  }

  void _renderTidalLockLine(
      Canvas canvas, Offset start, Offset end, double pulse) {
    // Straight line for tidal lock (distinct from curved constellation lines).
    // Thicker, brighter, electric-cyan.
    final glowAlpha = (0x55 + 0x33 * pulse).round().clamp(0, 255);
    final glowPaint = Paint()
      ..color = Color.fromARGB(glowAlpha, 0x00, 0xFF, 0xEE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawLine(start, end, glowPaint);

    final lineAlpha = (0xAA + 0x44 * pulse).round().clamp(0, 255);
    final linePaint = Paint()
      ..color = Color.fromARGB(lineAlpha, 0x00, 0xFF, 0xEE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawLine(start, end, linePaint);

    // Small perpendicular tick marks at the midpoint to signal lock.
    final mid = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len > 0) {
      final nx = -dy / len * 5;
      final ny = dx / len * 5;
      final tickPaint = Paint()
        ..color = Color.fromARGB(lineAlpha, 0x00, 0xFF, 0xEE)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(mid.dx + nx, mid.dy + ny),
        Offset(mid.dx - nx, mid.dy - ny),
        tickPaint,
      );
    }
  }

  // ── Bezier helper ────────────────────────────────────────────────────────────

  /// Returns a control point offset perpendicular to the midpoint.
  Offset _bezierControl(Offset start, Offset end,
      {required double curvature}) {
    final midX = (start.dx + end.dx) / 2;
    final midY = (start.dy + end.dy) / 2;

    // Perpendicular direction (rotated 90°).
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len < 1e-6) return Offset(midX, midY);

    final perpX = -dy / len;
    final perpY = dx / len;
    final offset = len * curvature;

    return Offset(midX + perpX * offset, midY + perpY * offset);
  }
}
