import 'package:equatable/equatable.dart';
import 'black_hole.dart';
import 'star.dart';
import 'planet.dart';
import 'moon.dart';
import 'asteroid.dart';

class Galaxy extends Equatable {
  final List<BlackHole> blackHoles;
  final List<Star> stars;
  final List<Planet> planets;
  final List<Moon> moons;
  final List<Asteroid> asteroids;

  const Galaxy({
    required this.blackHoles,
    required this.stars,
    required this.planets,
    required this.moons,
    required this.asteroids,
  });

  List<Star> starsForBlackHole(String blackHoleId) =>
      stars.where((s) => s.parentBlackHoleId == blackHoleId).toList();

  List<Planet> planetsForStar(String starId) =>
      planets.where((p) => p.parentStarId == starId).toList();

  List<Moon> moonsForPlanet(String planetId) =>
      moons.where((m) => m.parentPlanetId == planetId).toList();

  @override
  List<Object?> get props => [blackHoles, stars, planets, moons, asteroids];
}
