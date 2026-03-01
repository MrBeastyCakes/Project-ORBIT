import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/black_hole.dart';
import '../entities/star.dart';
import '../entities/planet.dart';
import '../entities/moon.dart';
import '../entities/asteroid.dart';

abstract class CelestialBodyRepository {
  // BlackHole
  Future<Either<Failure, void>> insertBlackHole(BlackHole entity);
  Future<Either<Failure, List<BlackHole>>> getAllBlackHoles();
  Future<Either<Failure, void>> deleteBlackHole(String id);
  Future<Either<Failure, int>> getBlackHoleCount();

  // Star
  Future<Either<Failure, void>> insertStar(Star entity);
  Future<Either<Failure, List<Star>>> getAllStars();
  Future<Either<Failure, void>> deleteStar(String id);
  Future<Either<Failure, int>> getStarCount();

  // Planet
  Future<Either<Failure, void>> insertPlanet(Planet entity);
  Future<Either<Failure, List<Planet>>> getAllPlanets();
  Future<Either<Failure, void>> deletePlanet(String id);
  Future<Either<Failure, int>> getPlanetCount();

  // Moon
  Future<Either<Failure, void>> insertMoon(Moon entity);
  Future<Either<Failure, List<Moon>>> getAllMoons();
  Future<Either<Failure, void>> deleteMoon(String id);
  Future<Either<Failure, int>> getMoonCount();

  // Asteroid
  Future<Either<Failure, void>> insertAsteroid(Asteroid entity);
  Future<Either<Failure, List<Asteroid>>> getAllAsteroids();
  Future<Either<Failure, void>> deleteAsteroid(String id);
  Future<Either<Failure, int>> getAsteroidCount();
}
