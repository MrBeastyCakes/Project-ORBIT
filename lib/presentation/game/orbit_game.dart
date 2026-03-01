import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:orbit_app/presentation/game/components/galaxy_component.dart';
import 'package:orbit_app/presentation/game/systems/camera_system.dart';
import 'package:orbit_app/presentation/game/systems/drag_system.dart';
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

/// Callback for when a wormhole is tapped; [targetPlanetId] is the
/// destination planet to warp the camera to.
typedef WormholeTappedCallback = void Function(String targetPlanetId);

class OrbitGame extends FlameGame with ScaleDetector, TapCallbacks {
  static const double minZoom = 0.05;
  static const double maxZoom = 5.0;

  late final GalaxyComponent _galaxyComponent;
  late final OrbitSystem _orbitSystem;
  late final DragSystem _dragSystem;
  late final TidalLockSystem _tidalLockSystem;
  late final CameraSystem _cameraSystem;

  double _currentZoom = 1.0;
  Vector2 _lastFocalPoint = Vector2.zero();

  /// Set by the widget layer to receive body tap events.
  BodyTappedCallback? onBodyTapped;

  /// Set by the widget layer to receive empty canvas tap events.
  CanvasTappedCallback? onCanvasTapped;

  /// Set by the widget layer to handle drag-to-reparent events.
  /// Called after a successful drop with (bodyId, bodyType, newParentId).
  ReparentCallback? onReparent;

  /// Set by the widget layer to receive wormhole tap events.
  /// The callback receives the target planet id; use it to trigger
  /// a [WormholeWarpEffect] or [CameraSystem.zoomToBody] call.
  WormholeTappedCallback? onWormholeTapped;

  GalaxyComponent get galaxyComponent => _galaxyComponent;

  /// Exposed so components can unregister from orbit during drag.
  OrbitSystem get orbitSystem => _orbitSystem;

  /// Exposed so components can notify the drag system.
  DragSystem? get dragSystem => _dragSystem;

  /// Exposes the tidal lock system for external pair registration.
  TidalLockSystem get tidalLockSystem => _tidalLockSystem;

  /// Exposes the camera system for smooth transitions.
  CameraSystem get cameraSystem => _cameraSystem;

  @override
  Color backgroundColor() => const Color(0xFF0A0A1A);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _orbitSystem = OrbitSystem();
    await world.add(_orbitSystem);

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

    _tidalLockSystem = TidalLockSystem(galaxy: _galaxyComponent);
    await world.add(_tidalLockSystem);

    _cameraSystem = CameraSystem(camera: camera);
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Advance any smooth camera transition in progress.
    _cameraSystem.updateTransition(dt);
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
    _dragSystem.planets = Map.of(_galaxyComponent.allPlanetComponents);
  }

  @override
  void onScaleStart(ScaleStartInfo info) {
    _lastFocalPoint = info.eventPosition.global;
  }

  @override
  void onScaleUpdate(ScaleUpdateInfo info) {
    // Pan: translate camera by focal point delta
    final currentFocal = info.eventPosition.global;
    final panDelta = currentFocal - _lastFocalPoint;
    _lastFocalPoint = currentFocal;
    camera.viewfinder.position =
        camera.viewfinder.position - panDelta / _currentZoom;

    // Zoom: scale.global.x holds horizontal scale factor
    final scaleX = info.scale.global.x;
    if (scaleX != 0.0 && scaleX != 1.0) {
      _currentZoom = (_currentZoom * scaleX).clamp(minZoom, maxZoom);
      camera.viewfinder.zoom = _currentZoom;
    }
  }

  @override
  void onScaleEnd(ScaleEndInfo info) {}

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
