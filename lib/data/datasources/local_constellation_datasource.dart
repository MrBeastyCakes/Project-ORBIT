import 'package:hive/hive.dart';
import 'package:orbit_app/core/errors/exceptions.dart';
import 'package:orbit_app/data/models/constellation_link_model.dart';

class LocalConstellationDatasource {
  final Box<ConstellationLinkModel> constellationLinksBox;

  const LocalConstellationDatasource({required this.constellationLinksBox});

  Future<ConstellationLinkModel> insertConstellationLink(
      ConstellationLinkModel model) async {
    try {
      await constellationLinksBox.put(model.id, model);
      return model;
    } catch (e) {
      throw CacheException('Failed to insert constellation link: $e');
    }
  }

  Future<List<ConstellationLinkModel>> getAllConstellationLinks() async {
    try {
      return constellationLinksBox.values.toList();
    } catch (e) {
      throw CacheException('Failed to get constellation links: $e');
    }
  }

  Future<void> deleteConstellationLink(String id) async {
    try {
      await constellationLinksBox.delete(id);
    } catch (e) {
      throw CacheException('Failed to delete constellation link: $e');
    }
  }

  Future<void> deleteConstellationLinksForPlanet(String planetId) async {
    try {
      final toDelete = constellationLinksBox.values
          .where((c) =>
              c.sourcePlanetId == planetId || c.targetPlanetId == planetId)
          .map((c) => c.id)
          .toList();
      await constellationLinksBox.deleteAll(toDelete);
    } catch (e) {
      throw CacheException(
          'Failed to cascade delete constellation links for planet: $e');
    }
  }
}
