import 'package:flame/components.dart';
import 'package:orbit_app/core/constants/orbit_constants.dart';
import 'package:orbit_app/domain/entities/planet.dart';
import 'package:orbit_app/presentation/game/components/galaxy_component.dart';
import 'package:orbit_app/presentation/game/components/planet_component.dart';

/// Periodically derives the correct [PlanetVisualState] for each planet
/// and notifies the [PlanetComponent] when its state has changed.
///
/// Runs every [_checkInterval] seconds rather than every frame to keep
/// CPU cost negligible.
class VisualStateSystem extends Component {
  static const double _checkInterval = 5.0;

  final GalaxyComponent galaxy;
  double _timer = 0.0;

  VisualStateSystem({required this.galaxy});

  @override
  void update(double dt) {
    _timer += dt;
    if (_timer >= _checkInterval) {
      _timer = 0.0;
      _evaluateAll();
    }
  }

  /// Force an immediate evaluation – call this after a planet's data changes.
  void evaluateNow() => _evaluateAll();

  void _evaluateAll() {
    for (final component in galaxy.allPlanets) {
      final derived = _derive(component.entity);
      if (derived != component.entity.visualState) {
        component.applyVisualState(derived);
      }
    }
  }

  PlanetVisualState _derive(Planet planet) {
    if (planet.wordCount == 0) {
      return PlanetVisualState.protostar;
    }
    if (planet.wordCount >= OrbitConstants.gasGiantWordCount) {
      return PlanetVisualState.gasGiant;
    }
    final lastOpened = planet.lastOpenedAt;
    if (lastOpened != null) {
      final daysSince = DateTime.now().difference(lastOpened).inDays;
      if (daysSince >= OrbitConstants.dwarfPlanetInactiveDays) {
        return PlanetVisualState.dwarfPlanet;
      }
    }
    return PlanetVisualState.normal;
  }
}
