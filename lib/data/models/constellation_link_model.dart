import 'package:hive/hive.dart';
import 'package:orbit_app/domain/entities/constellation_link.dart';

part 'constellation_link_model.g.dart';

@HiveType(typeId: 7)
class ConstellationLinkModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String sourcePlanetId;

  @HiveField(2)
  final String targetPlanetId;

  @HiveField(3)
  final DateTime createdAt;

  ConstellationLinkModel({
    required this.id,
    required this.sourcePlanetId,
    required this.targetPlanetId,
    required this.createdAt,
  });

  factory ConstellationLinkModel.fromEntity(ConstellationLink entity) {
    return ConstellationLinkModel(
      id: entity.id,
      sourcePlanetId: entity.sourcePlanetId,
      targetPlanetId: entity.targetPlanetId,
      createdAt: entity.createdAt,
    );
  }

  ConstellationLink toEntity() {
    return ConstellationLink(
      id: id,
      sourcePlanetId: sourcePlanetId,
      targetPlanetId: targetPlanetId,
      createdAt: createdAt,
    );
  }
}
