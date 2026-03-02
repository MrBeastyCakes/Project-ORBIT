import 'package:flame/components.dart';

/// Zoom level thresholds.
enum GalaxyViewLevel {
  /// zoom < 0.2 -- full galaxy view
  galaxy,

  /// 0.2 <= zoom < 1.0 -- system view
  system,

  /// zoom >= 1.0 -- planet approach
  planet,
}

class CameraSystem {
  final CameraComponent camera;

  /// Duration of smooth zoom/pan transitions in seconds.
  static const double _transitionDuration = 0.5;

  /// Stored camera state before entering surface mode, so we can restore it.
  Vector2? _preSurfacePosition;
  double? _preSurfaceZoom;

  /// When non-null, the camera is animating toward this target.
  Vector2? _targetPosition;
  double? _targetZoom;
  double _transitionElapsed = 0.0;
  double _transitionDurationActive = _transitionDuration;
  Vector2? _startPosition;
  double? _startZoom;

  CameraSystem({required this.camera});

  GalaxyViewLevel get currentViewLevel {
    final z = camera.viewfinder.zoom;
    if (z < 0.2) return GalaxyViewLevel.galaxy;
    if (z < 1.0) return GalaxyViewLevel.system;
    return GalaxyViewLevel.planet;
  }

  /// Whether a smooth transition is currently in progress.
  bool get isTransitioning => _targetPosition != null;

  /// Smoothly moves camera to [targetWorld] and sets [targetZoom].
  void zoomToBody({
    required Vector2 targetWorld,
    required double targetZoom,
    required double dt,
  }) {
    final currentZoom = camera.viewfinder.zoom;
    final newZoom = _lerp(currentZoom, targetZoom, dt / _transitionDuration);
    camera.viewfinder.zoom = newZoom.clamp(0.05, 5.0);

    final currentPos = camera.viewfinder.position;
    camera.viewfinder.position = Vector2(
      _lerp(currentPos.x, targetWorld.x, dt / _transitionDuration),
      _lerp(currentPos.y, targetWorld.y, dt / _transitionDuration),
    );
  }

  /// Frames the camera to fit all given body positions with padding.
  void frameAllBodies(List<Vector2> positions, Vector2 viewportSize) {
    if (positions.isEmpty) return;

    // Calculate bounding box
    double minX = positions.first.x, maxX = positions.first.x;
    double minY = positions.first.y, maxY = positions.first.y;
    for (final p in positions) {
      if (p.x < minX) minX = p.x;
      if (p.x > maxX) maxX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.y > maxY) maxY = p.y;
    }

    // Center of bounding box
    final center = Vector2((minX + maxX) / 2, (minY + maxY) / 2);

    // Calculate zoom to fit with 20% padding
    final width = (maxX - minX) + 400; // add padding for body radii
    final height = (maxY - minY) + 400;
    final zoomX = viewportSize.x / width;
    final zoomY = viewportSize.y / height;
    final zoom = (zoomX < zoomY ? zoomX : zoomY).clamp(0.05, 5.0);

    // Animate to the framed view with a slightly longer duration so the
    // initial framing feels intentional.
    animateTo(targetWorld: center, targetZoom: zoom, duration: 0.8);
  }

  /// Starts a smooth animated transition to [targetWorld] at [targetZoom].
  /// Call [updateTransition] each frame to advance the animation.
  void animateTo({
    required Vector2 targetWorld,
    required double targetZoom,
    double duration = _transitionDuration,
  }) {
    _startPosition = camera.viewfinder.position.clone();
    _startZoom = camera.viewfinder.zoom;
    _targetPosition = targetWorld.clone();
    _targetZoom = targetZoom.clamp(0.05, 5.0);
    _transitionElapsed = 0.0;
    _transitionDurationActive = duration;
  }

  /// Advances the smooth transition animation. Call once per frame.
  /// Returns true if the transition is still in progress.
  bool updateTransition(double dt) {
    if (_targetPosition == null) return false;

    _transitionElapsed += dt;
    final t = (_transitionElapsed / _transitionDurationActive).clamp(0.0, 1.0);
    // Ease-out cubic for smooth deceleration.
    final eased = 1.0 - (1.0 - t) * (1.0 - t) * (1.0 - t);

    camera.viewfinder.position = Vector2(
      _lerp(_startPosition!.x, _targetPosition!.x, eased),
      _lerp(_startPosition!.y, _targetPosition!.y, eased),
    );
    camera.viewfinder.zoom = _lerp(_startZoom!, _targetZoom!, eased);

    if (t >= 1.0) {
      _targetPosition = null;
      _targetZoom = null;
      _startPosition = null;
      _startZoom = null;
      return false;
    }
    return true;
  }

  /// Saves the current camera state before entering surface mode.
  void savePreSurfaceState() {
    _preSurfacePosition = camera.viewfinder.position.clone();
    _preSurfaceZoom = camera.viewfinder.zoom;
  }

  /// Restores camera to the saved pre-surface state with a smooth transition.
  /// Returns true if a state was saved; false if there is nothing to restore.
  bool restorePreSurfaceState() {
    if (_preSurfacePosition == null || _preSurfaceZoom == null) return false;
    animateTo(
      targetWorld: _preSurfacePosition!,
      targetZoom: _preSurfaceZoom!,
    );
    _preSurfacePosition = null;
    _preSurfaceZoom = null;
    return true;
  }

  /// Instantly snaps camera to [worldPosition] at [zoom].
  void snapToBody({required Vector2 worldPosition, required double zoom}) {
    camera.viewfinder.position = worldPosition;
    camera.viewfinder.zoom = zoom.clamp(0.05, 5.0);
  }

  /// Recommended zoom for each hierarchy level.
  static double zoomForLevel(GalaxyViewLevel level) {
    switch (level) {
      case GalaxyViewLevel.galaxy:
        return 0.1;
      case GalaxyViewLevel.system:
        return 0.5;
      case GalaxyViewLevel.planet:
        return 2.0;
    }
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t.clamp(0.0, 1.0);
}
