import 'dart:math' as math;

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:orbit_app/presentation/game/components/galaxy_component.dart';
import 'package:orbit_app/presentation/game/systems/camera_system.dart';
import 'package:orbit_app/presentation/game/systems/drag_system.dart';
import 'package:orbit_app/presentation/game/systems/gravity_system.dart';
import 'package:orbit_app/presentation/game/systems/orbit_system.dart';
import 'package:orbit_app/presentation/game/systems/tidal_lock_system.dart';

/// Callback signature for when a celestial body is tapped.
/// [id] is the entity id, [type] is 'blackHole'|'star'|'planet'|'moon',
/// [screenPosition] is the tap position in screen coordinates.
typedef BodyTappedCallback = void Function(
  String id,
  String type,
  Vector2 screenPosition,
);

/// Callback for tapping empty canvas space.
typedef CanvasTappedCallback = void Function(Vector2 screenPosition);

/// Callback for reparenting a body via drag-and-drop.
/// [bodyId] is the dragged entity id, [bodyType] is 'planet' or 'star',
/// [newParentId] is the id of the new parent (star or black hole).
typedef ReparentCallback = void Function(
  String bodyId,
  String bodyType,
  String newParentId,
);

/// Callback for when a body's orbit radius is changed via drag.
/// [bodyId] is the entity id, [bodyType] is 'planet' or 'star',
/// [newOrbitRadius] is the new distance from its parent.
typedef OrbitRadiusChangedCallback = void Function(
  String bodyId,
  String bodyType,
  double newOrbitRadius,
);

/// Callback for when a wormhole is tapped; [targetPlanetId] is the
/// destination planet to warp the camera to.
typedef WormholeTappedCallback = void Function(String targetPlanetId);

class OrbitGame extends FlameGame with ScaleDetector, TapCallbacks {
  static const double minZoom = 0.05;
  static const double maxZoom = 5.0;

  late final GalaxyComponent _galaxyComponent;
  late final OrbitSystem _orbitSystem;
  late final GravitySystem _gravitySystem;
  late final DragSystem _dragSystem;
  late final TidalLockSystem _tidalLockSystem;
  late final CameraSystem _cameraSystem;

  double _currentZoom = 1.0;

  // ── Gesture tracking ────────────────────────────────────────────────────────

  /// Zoom level when the gesture started (for correct cumulative scale).
  double _zoomAtScaleStart = 1.0;

  /// Focal point at previous update (screen coords) for pan delta.
  Vector2 _lastFocalPoint = Vector2.zero();

  /// World-space position of the focal point at gesture start (for focal zoom).
  Vector2 _focalWorldStart = Vector2.zero();

  /// Timestamp (microseconds) of the last onScaleUpdate call, for velocity calc.
  int _lastScaleUpdateUs = 0;

  // ── Momentum / inertia ──────────────────────────────────────────────────────

  /// Current pan velocity in world units/sec, decays after release.
  Vector2 _velocity = Vector2.zero();

  /// Friction factor — velocity is multiplied by this each second.
  static const double _friction = 0.02;

  /// Minimum speed threshold to stop momentum.
  static const double _minSpeed = 5.0;

  /// Whether a gesture is currently active (suppresses momentum).
  bool _gestureActive = false;

  /// Set by the widget layer to receive body tap events.
  BodyTappedCallback? onBodyTapped;

  /// Set by the widget layer to receive empty canvas tap events.
  CanvasTappedCallback? onCanvasTapped;

  /// Set by the widget layer to handle drag-to-reparent events.
  /// Called after a successful drop with (bodyId, bodyType, newParentId).
  ReparentCallback? onReparent;

  /// Set by the widget layer to persist orbit radius changes from drag.
  OrbitRadiusChangedCallback? onOrbitRadiusChanged;

  /// Set by the widget layer to receive wormhole tap events.
  /// The callback receives the target planet id; use it to trigger
  /// a [WormholeWarpEffect] or [CameraSystem.zoomToBody] call.
  WormholeTappedCallback? onWormholeTapped;

  GalaxyComponent get galaxyComponent => _galaxyComponent;

  /// Exposed so components can unregister from orbit during drag.
  OrbitSystem get orbitSystem => _orbitSystem;

  /// Exposed so GalaxyComponent can register bodies for gravity interaction.
  GravitySystem get gravitySystem => _gravitySystem;

  /// Exposed so components can notify the drag system.
  DragSystem? get dragSystem => _dragSystem;

  /// Exposes the tidal lock system for external pair registration.
  TidalLockSystem get tidalLockSystem => _tidalLockSystem;

  /// Exposes the camera system for smooth transitions.
  CameraSystem get cameraSystem => _cameraSystem;

  /// Current zoom level (read by ZoomIndicator widget).
  double get currentZoom => _currentZoom;

  @override
  Color backgroundColor() => const Color(0xFF0A0A1A);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _orbitSystem = OrbitSystem();
    await world.add(_orbitSystem);

    _gravitySystem = GravitySystem();
    await world.add(_gravitySystem);

    _galaxyComponent = GalaxyComponent();
    await world.add(_galaxyComponent);

    _dragSystem = DragSystem();
    await world.add(_dragSystem);

    // Wire drag system callbacks.
    _dragSystem.onReparentPlanet = (planetId, newStarId) {
      onReparent?.call(planetId, 'planet', newStarId);
    };
    _dragSystem.onReparentStar = (starId, newBlackHoleId) {
      onReparent?.call(starId, 'star', newBlackHoleId);
    };
    _dragSystem.onOrbitRadiusChanged = (bodyId, bodyType, newRadius) {
      onOrbitRadiusChanged?.call(bodyId, bodyType, newRadius);
    };

    _tidalLockSystem = TidalLockSystem(galaxy: _galaxyComponent);
    await world.add(_tidalLockSystem);

    _cameraSystem = CameraSystem(camera: camera);

    // Wire DragSystem to live galaxy maps (must happen after both are mounted).
    syncDragSystemRefs();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Apply momentum when no gesture is active.
    if (!_gestureActive && _velocity.length > _minSpeed) {
      camera.viewfinder.position =
          camera.viewfinder.position + _velocity * dt;
      // Exponential decay: v *= friction^dt
      final decay = math.pow(_friction, dt).toDouble();
      _velocity.scale(decay);
    } else if (!_gestureActive) {
      _velocity.setZero();
    }

    // Advance any smooth camera transition in progress.
    _cameraSystem.updateTransition(dt);
    // Keep _currentZoom in sync after camera animations (Bug fix: zoom desync).
    _currentZoom = camera.viewfinder.zoom;
    // Update viewport bounds and LOD tier from current camera state.
    _galaxyComponent.updateViewportAndLod();
    // Keep constellation lines tracking their orbiting planets each frame.
    _galaxyComponent.updateConstellationPositions();
  }

  /// Called by GalaxyComponent (or the widget) after bodies are loaded so
  /// DragSystem has live references to the component maps.
  void syncDragSystemRefs() {
    _dragSystem.stars = _galaxyComponent.starsMap;
    _dragSystem.blackHoles = _galaxyComponent.blackHolesMap;
    _dragSystem.planets = _galaxyComponent.allPlanetComponents;
  }

  /// Frames the camera to show all loaded bodies.
  void frameAllBodies() {
    _galaxyComponent.frameAll();
  }

  /// Convert a screen-space point to world-space using current camera state.
  Vector2 _screenToWorld(Vector2 screenPoint) {
    final camPos = camera.viewfinder.position;
    final viewportSize = camera.viewport.size;
    return Vector2(
      camPos.x + (screenPoint.x - viewportSize.x / 2) / _currentZoom,
      camPos.y + (screenPoint.y - viewportSize.y / 2) / _currentZoom,
    );
  }

  @override
  void onScaleStart(ScaleStartInfo info) {
    _gestureActive = true;
    _velocity.setZero();
    _lastFocalPoint = info.eventPosition.global;
    _zoomAtScaleStart = _currentZoom;
    _focalWorldStart = _screenToWorld(info.eventPosition.global);
    _lastScaleUpdateUs = DateTime.now().microsecondsSinceEpoch;
  }

  @override
  void onScaleUpdate(ScaleUpdateInfo info) {
    final currentFocal = info.eventPosition.global;

    // ── Zoom (pinch) ────────────────────────────────────────────────────────
    final scaleX = info.scale.global.x;
    if (scaleX > 0.0 && scaleX != 1.0) {
      final newZoom = (_zoomAtScaleStart * scaleX).clamp(minZoom, maxZoom);
      _currentZoom = newZoom;
      camera.viewfinder.zoom = _currentZoom;

      // Adjust camera position so the focal world point stays under the finger.
      final viewportSize = camera.viewport.size;
      camera.viewfinder.position = Vector2(
        _focalWorldStart.x -
            (currentFocal.x - viewportSize.x / 2) / _currentZoom,
        _focalWorldStart.y -
            (currentFocal.y - viewportSize.y / 2) / _currentZoom,
      );
    } else {
      // ── Pan (single finger) ─────────────────────────────────────────────
      final panDelta = currentFocal - _lastFocalPoint;
      final worldDelta = panDelta / _currentZoom;
      camera.viewfinder.position =
          camera.viewfinder.position - worldDelta;

      // Track velocity for momentum using actual elapsed time between events.
      final nowUs = DateTime.now().microsecondsSinceEpoch;
      final gestureDt =
          ((nowUs - _lastScaleUpdateUs) / 1000000.0).clamp(0.001, 0.1);
      _lastScaleUpdateUs = nowUs;
      // Negative because camera moves opposite to the world delta.
      _velocity = -worldDelta / gestureDt;
    }

    _lastFocalPoint = currentFocal;
  }

  @override
  void onScaleEnd(ScaleEndInfo info) {
    _gestureActive = false;
    // Velocity is already set from the last onScaleUpdate; momentum kicks in.
  }

  @override
  void onTapUp(TapUpEvent event) {
    // This fires when the tap didn't hit any component with TapCallbacks.
    // Treat as an empty canvas tap.
    onCanvasTapped?.call(event.canvasPosition);
  }

  /// Dims all planets except those in [matchingPlanetIds], which are highlighted.
  void enterTelescopeMode(List<String> matchingPlanetIds) {
    final matchSet = matchingPlanetIds.toSet();
    for (final entry in _galaxyComponent.allPlanetComponents.entries) {
      final component = entry.value;
      if (matchSet.contains(entry.key)) {
        component.isHighlighted = true;
        component.isTelescopeDimmed = false;
      } else {
        component.isHighlighted = false;
        component.isTelescopeDimmed = matchingPlanetIds.isNotEmpty;
      }
    }
  }

  /// Restores normal rendering for all planets.
  void exitTelescopeMode() {
    for (final component in _galaxyComponent.allPlanetComponents.values) {
      component.isHighlighted = false;
      component.isTelescopeDimmed = false;
    }
  }
}
