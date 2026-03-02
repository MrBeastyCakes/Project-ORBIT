import 'package:dartz/dartz.dart';
import 'package:orbit_app/core/errors/exceptions.dart';
import 'package:orbit_app/core/errors/failures.dart';
import 'package:orbit_app/data/datasources/local_celestial_datasource.dart';
import 'package:orbit_app/data/datasources/local_constellation_datasource.dart';
import 'package:orbit_app/data/datasources/local_note_content_datasource.dart';
import 'package:orbit_app/data/datasources/local_wormhole_datasource.dart';
import 'package:orbit_app/data/models/asteroid_model.dart';
import 'package:orbit_app/data/models/black_hole_model.dart';
import 'package:orbit_app/data/models/moon_model.dart';
import 'package:orbit_app/data/models/planet_model.dart';
import 'package:orbit_app/data/models/star_model.dart';
import 'package:orbit_app/domain/entities/asteroid.dart';
import 'package:orbit_app/domain/entities/black_hole.dart';
import 'package:orbit_app/domain/entities/moon.dart';
import 'package:orbit_app/domain/entities/planet.dart';
import 'package:orbit_app/domain/entities/star.dart';
import 'package:orbit_app/domain/repositories/celestial_body_repository.dart';

class CelestialBodyRepositoryImpl implements CelestialBodyRepository {
  final LocalCelestialDatasource datasource;
  final LocalWormholeDatasource wormholeDatasource;
  final LocalConstellationDatasource constellationDatasource;
  final LocalNoteContentDatasource noteContentDatasource;

  const CelestialBodyRepositoryImpl({
    required this.datasource,
    required this.wormholeDatasource,
    required this.constellationDatasource,
    required this.noteContentDatasource,
  });

  // --- BlackHole ---

  @override
  Future<Either<Failure, void>> insertBlackHole(BlackHole entity) async {
    try {
      await datasource.insertBlackHole(BlackHoleModel.fromEntity(entity));
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> updateBlackHole(BlackHole entity) async {
    try {
      await datasource.updateBlackHole(BlackHoleModel.fromEntity(entity));
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<BlackHole>>> getAllBlackHoles() async {
    try {
      final models = await datasource.getAllBlackHoles();
      return Right(models.map((m) => m.toEntity()).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteBlackHole(String id) async {
    try {
      await datasource.deleteStarsForBlackHole(id);
      await datasource.deleteBlackHole(id);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, int>> getBlackHoleCount() async {
    try {
      final count = await datasource.getBlackHoleCount();
      return Right(count);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  // --- Star ---

  @override
  Future<Either<Failure, void>> insertStar(Star entity) async {
    try {
      await datasource.insertStar(StarModel.fromEntity(entity));
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> updateStar(Star entity) async {
    try {
      await datasource.updateStar(StarModel.fromEntity(entity));
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<Star>>> getAllStars() async {
    try {
      final models = await datasource.getAllStars();
      return Right(models.map((m) => m.toEntity()).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteStar(String id) async {
    try {
      await datasource.deletePlanetsForStar(id);
      await datasource.deleteStar(id);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, int>> getStarCount() async {
    try {
      final count = await datasource.getStarCount();
      return Right(count);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  // --- Planet ---

  @override
  Future<Either<Failure, void>> insertPlanet(Planet entity) async {
    try {
      await datasource.insertPlanet(PlanetModel.fromEntity(entity));
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> updatePlanet(Planet entity) async {
    try {
      await datasource.updatePlanet(PlanetModel.fromEntity(entity));
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<Planet>>> getAllPlanets() async {
    try {
      final models = await datasource.getAllPlanets();
      return Right(models.map((m) => m.toEntity()).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deletePlanet(String id) async {
    try {
      await datasource.deleteMoonsForPlanet(id);
      await wormholeDatasource.deleteWormholesForPlanet(id);
      await constellationDatasource.deleteConstellationLinksForPlanet(id);
      await noteContentDatasource.deleteNoteContent(id);
      await datasource.deletePlanet(id);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, int>> getPlanetCount() async {
    try {
      final count = await datasource.getPlanetCount();
      return Right(count);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  // --- Moon ---

  @override
  Future<Either<Failure, void>> insertMoon(Moon entity) async {
    try {
      await datasource.insertMoon(MoonModel.fromEntity(entity));
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> updateMoon(Moon entity) async {
    try {
      await datasource.updateMoon(MoonModel.fromEntity(entity));
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<Moon>>> getAllMoons() async {
    try {
      final models = await datasource.getAllMoons();
      return Right(models.map((m) => m.toEntity()).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMoon(String id) async {
    try {
      await datasource.deleteMoon(id);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, int>> getMoonCount() async {
    try {
      final count = await datasource.getMoonCount();
      return Right(count);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  // --- Asteroid ---

  @override
  Future<Either<Failure, void>> insertAsteroid(Asteroid entity) async {
    try {
      await datasource.insertAsteroid(AsteroidModel.fromEntity(entity));
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> updateAsteroid(Asteroid entity) async {
    try {
      await datasource.updateAsteroid(AsteroidModel.fromEntity(entity));
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<Asteroid>>> getAllAsteroids() async {
    try {
      final models = await datasource.getAllAsteroids();
      return Right(models.map((m) => m.toEntity()).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAsteroid(String id) async {
    try {
      await datasource.deleteAsteroid(id);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, int>> getAsteroidCount() async {
    try {
      final count = await datasource.getAsteroidCount();
      return Right(count);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }
}
