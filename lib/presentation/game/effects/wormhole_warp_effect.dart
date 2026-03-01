import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

/// Phases of the warp animation.
enum _WarpPhase { zoomIn, flash, snap, zoomOut, done }

/// Camera warp transition played when a wormhole is tapped.
///
/// Timeline:
///   0.0 – 0.5 s  → zoom camera from current zoom to 3× at wormhole position
///   0.5 – 0.8 s  → brief cyan flash / distortion overlay
///   0.8 s        → instant snap camera to target planet position
///   0.8 – 1.4 s  → smooth zoom-out to original zoom level
///
/// Usage:
/// ```dart
/// final warp = WormholeWarpEffect(
///   camera: game.camera,
///   wormholeWorld: wormholeWorldPos,
///   targetWorld: targetPlanetWorldPos,
///   normalZoom: game.currentZoom,
/// );
/// game.world.add(warp);
/// ```
class WormholeWarpEffect extends Component {
  final CameraComponent camera;

  /// World position of the wormhole (zoom-in target).
  final Vector2 wormholeWorld;

  /// World position of the destination planet (snap target).
  final Vector2 targetWorld;

  /// Zoom level before the warp — restored at the end.
  final double normalZoom;

  /// Called when the entire warp animation completes.
  void Function()? onComplete;

  static const double _zoomInDuration = 0.5;
  static const double _flashDuration = 0.3;
  static const double _zoomOutDuration = 0.6;
  static const double _warpZoom = 3.0;

  double _elapsed = 0.0;
  _WarpPhase _phase = _WarpPhase.zoomIn;

  late double _startZoom;
  late Vector2 _startPos;

  WormholeWarpEffect({
    required this.camera,
    required this.wormholeWorld,
    required this.targetWorld,
    required this.normalZoom,
    this.onComplete,
  });

  @override
  Future<void> onLoad() async {
    _startZoom = camera.viewfinder.zoom;
    _startPos = camera.viewfinder.position.clone();
  }

  @override
  void update(double dt) {
    _elapsed += dt;

    switch (_phase) {
      case _WarpPhase.zoomIn:
        final t = (_elapsed / _zoomInDuration).clamp(0.0, 1.0);
        final easedT = _easeInCubic(t);
        camera.viewfinder.zoom =
            _lerp(_startZoom, _warpZoom, easedT).clamp(0.05, 5.0);
        camera.viewfinder.position = Vector2(
          _lerp(_startPos.x, wormholeWorld.x, easedT),
          _lerp(_startPos.y, wormholeWorld.y, easedT),
        );
        if (_elapsed >= _zoomInDuration) {
          _elapsed = 0.0;
          _phase = _WarpPhase.flash;
        }

      case _WarpPhase.flash:
        // Flash overlay is rendered in render(); just wait out the duration.
        if (_elapsed >= _flashDuration) {
          _elapsed = 0.0;
          _phase = _WarpPhase.snap;
        }

      case _WarpPhase.snap:
        // Instant snap to target position; keep warp zoom temporarily.
        camera.viewfinder.position = targetWorld.clone();
        _elapsed = 0.0;
        _phase = _WarpPhase.zoomOut;

      case _WarpPhase.zoomOut:
        final t = (_elapsed / _zoomOutDuration).clamp(0.0, 1.0);
        final easedT = _easeOutCubic(t);
        camera.viewfinder.zoom =
            _lerp(_warpZoom, normalZoom, easedT).clamp(0.05, 5.0);
        if (_elapsed >= _zoomOutDuration) {
          camera.viewfinder.zoom = normalZoom;
          _phase = _WarpPhase.done;
          onComplete?.call();
          removeFromParent();
        }

      case _WarpPhase.done:
        break;
    }
  }

  @override
  void render(Canvas canvas) {
    if (_phase != _WarpPhase.flash) return;

    // Flash intensity peaks at midpoint via a sin curve (0 → 1 → 0).
    final t = (_elapsed / _flashDuration).clamp(0.0, 1.0);
    final intensity = math.sin(t * math.pi);

    final screenSize = camera.viewport.size;
    final paint = Paint()
      ..color = const Color(0xFF00FFEE).withValues(alpha: 0.7 * intensity);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, screenSize.x, screenSize.y),
      paint,
    );
  }

  // ── Math helpers ────────────────────────────────────────────────────────────

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  double _easeInCubic(double t) => t * t * t;

  double _easeOutCubic(double t) {
    final u = 1.0 - t;
    return 1.0 - u * u * u;
  }
}
