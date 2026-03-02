import 'package:hive/hive.dart';
import 'package:orbit_app/core/errors/exceptions.dart';
import 'package:orbit_app/data/models/wormhole_model.dart';

class LocalWormholeDatasource {
  final Box<WormholeModel> wormholesBox;

  const LocalWormholeDatasource({required this.wormholesBox});

  Future<WormholeModel> insertWormhole(WormholeModel model) async {
    try {
      await wormholesBox.put(model.id, model);
      return model;
    } catch (e) {
      throw CacheException('Failed to insert wormhole: $e');
    }
  }

  Future<List<WormholeModel>> getAllWormholes() async {
    try {
      return wormholesBox.values.toList();
    } catch (e) {
      throw CacheException('Failed to get wormholes: $e');
    }
  }

  Future<void> deleteWormhole(String id) async {
    try {
      await wormholesBox.delete(id);
    } catch (e) {
      throw CacheException('Failed to delete wormhole: $e');
    }
  }

  Future<void> deleteWormholesForPlanet(String planetId) async {
    try {
      final toDelete = wormholesBox.values
          .where((w) =>
              w.sourcePlanetId == planetId || w.targetPlanetId == planetId)
          .map((w) => w.id)
          .toList();
      await wormholesBox.deleteAll(toDelete);
    } catch (e) {
      throw CacheException('Failed to cascade delete wormholes for planet: $e');
    }
  }
}
