import 'package:hive/hive.dart';
import 'package:orbit_app/core/errors/exceptions.dart';
import 'package:orbit_app/data/models/asteroid_model.dart';
import 'package:orbit_app/data/models/black_hole_model.dart';
import 'package:orbit_app/data/models/moon_model.dart';
import 'package:orbit_app/data/models/planet_model.dart';
import 'package:orbit_app/data/models/star_model.dart';

class LocalCelestialDatasource {
  final Box<BlackHoleModel> blackHolesBox;
  final Box<StarModel> starsBox;
  final Box<PlanetModel> planetsBox;
  final Box<MoonModel> moonsBox;
  final Box<AsteroidModel> asteroidsBox;

  const LocalCelestialDatasource({
    required this.blackHolesBox,
    required this.starsBox,
    required this.planetsBox,
    required this.moonsBox,
    required this.asteroidsBox,
  });

  // --- BlackHole ---

  Future<void> insertBlackHole(BlackHoleModel model) async {
    try {
      await blackHolesBox.put(model.id, model);
    } catch (e) {
      throw CacheException('Failed to insert black hole: $e');
    }
  }

  Future<List<BlackHoleModel>> getAllBlackHoles() async {
    try {
      return blackHolesBox.values.toList();
    } catch (e) {
      throw CacheException('Failed to get black holes: $e');
    }
  }

  Future<void> deleteBlackHole(String id) async {
    try {
      await blackHolesBox.delete(id);
    } catch (e) {
      throw CacheException('Failed to delete black hole: $e');
    }
  }

  Future<int> getBlackHoleCount() async {
    try {
      return blackHolesBox.length;
    } catch (e) {
      throw CacheException('Failed to get black hole count: $e');
    }
  }

  // --- Star ---

  Future<void> insertStar(StarModel model) async {
    try {
      await starsBox.put(model.id, model);
    } catch (e) {
      throw CacheException('Failed to insert star: $e');
    }
  }

  Future<List<StarModel>> getAllStars() async {
    try {
      return starsBox.values.toList();
    } catch (e) {
      throw CacheException('Failed to get stars: $e');
    }
  }

  Future<void> deleteStar(String id) async {
    try {
      await starsBox.delete(id);
    } catch (e) {
      throw CacheException('Failed to delete star: $e');
    }
  }

  Future<int> getStarCount() async {
    try {
      return starsBox.length;
    } catch (e) {
      throw CacheException('Failed to get star count: $e');
    }
  }

  // --- Planet ---

  Future<void> insertPlanet(PlanetModel model) async {
    try {
      await planetsBox.put(model.id, model);
    } catch (e) {
      throw CacheException('Failed to insert planet: $e');
    }
  }

  Future<List<PlanetModel>> getAllPlanets() async {
    try {
      return planetsBox.values.toList();
    } catch (e) {
      throw CacheException('Failed to get planets: $e');
    }
  }

  Future<void> deletePlanet(String id) async {
    try {
      await planetsBox.delete(id);
    } catch (e) {
      throw CacheException('Failed to delete planet: $e');
    }
  }

  Future<int> getPlanetCount() async {
    try {
      return planetsBox.length;
    } catch (e) {
      throw CacheException('Failed to get planet count: $e');
    }
  }

  // --- Moon ---

  Future<void> insertMoon(MoonModel model) async {
    try {
      await moonsBox.put(model.id, model);
    } catch (e) {
      throw CacheException('Failed to insert moon: $e');
    }
  }

  Future<List<MoonModel>> getAllMoons() async {
    try {
      return moonsBox.values.toList();
    } catch (e) {
      throw CacheException('Failed to get moons: $e');
    }
  }

  Future<void> deleteMoon(String id) async {
    try {
      await moonsBox.delete(id);
    } catch (e) {
      throw CacheException('Failed to delete moon: $e');
    }
  }

  Future<int> getMoonCount() async {
    try {
      return moonsBox.length;
    } catch (e) {
      throw CacheException('Failed to get moon count: $e');
    }
  }

  // --- Asteroid ---

  Future<void> insertAsteroid(AsteroidModel model) async {
    try {
      await asteroidsBox.put(model.id, model);
    } catch (e) {
      throw CacheException('Failed to insert asteroid: $e');
    }
  }

  Future<List<AsteroidModel>> getAllAsteroids() async {
    try {
      return asteroidsBox.values.toList();
    } catch (e) {
      throw CacheException('Failed to get asteroids: $e');
    }
  }

  Future<void> deleteAsteroid(String id) async {
    try {
      await asteroidsBox.delete(id);
    } catch (e) {
      throw CacheException('Failed to delete asteroid: $e');
    }
  }

  Future<int> getAsteroidCount() async {
    try {
      return asteroidsBox.length;
    } catch (e) {
      throw CacheException('Failed to get asteroid count: $e');
    }
  }

  // --- Cascade delete helpers ---

  Future<void> deleteStarsForBlackHole(String blackHoleId) async {
    try {
      final toDelete = starsBox.values
          .where((s) => s.parentBlackHoleId == blackHoleId)
          .map((s) => s.id)
          .toList();
      await starsBox.deleteAll(toDelete);
    } catch (e) {
      throw CacheException('Failed to cascade delete stars: $e');
    }
  }

  Future<void> deletePlanetsForStar(String starId) async {
    try {
      final toDelete = planetsBox.values
          .where((p) => p.parentStarId == starId)
          .map((p) => p.id)
          .toList();
      await planetsBox.deleteAll(toDelete);
    } catch (e) {
      throw CacheException('Failed to cascade delete planets: $e');
    }
  }

  Future<void> deleteMoonsForPlanet(String planetId) async {
    try {
      final toDelete = moonsBox.values
          .where((m) => m.parentPlanetId == planetId)
          .map((m) => m.id)
          .toList();
      await moonsBox.deleteAll(toDelete);
    } catch (e) {
      throw CacheException('Failed to cascade delete moons: $e');
    }
  }
}
