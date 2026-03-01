import 'package:flame/components.dart';

import '../components/planet_component.dart';

/// Simple distance-based collision detection for asteroid accretion.
///
/// Returns the [PlanetComponent] that is within [accretionDistance] of
/// [worldPosition], or null if none qualifies.
class CollisionSystem {
  /// World-unit radius within which an asteroid is considered to collide
  /// with a planet and can be accreted.
  static const double accretionDistance = 50.0;

  /// Find the nearest planet to [worldPosition] that is within
  /// [accretionDistance] world units.
  ///
  /// [planets] is the current map of planet id → PlanetComponent.
  PlanetComponent? findAccretionTarget(
    Vector2 worldPosition,
    Map<String, PlanetComponent> planets,
  ) {
    PlanetComponent? nearest;
    double nearestDist = double.infinity;

    for (final planet in planets.values) {
      final dist = worldPosition.distanceTo(planet.position);
      if (dist < accretionDistance && dist < nearestDist) {
        nearestDist = dist;
        nearest = planet;
      }
    }
    return nearest;
  }
}
