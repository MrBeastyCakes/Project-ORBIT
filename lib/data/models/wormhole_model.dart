import 'package:hive/hive.dart';
import 'package:orbit_app/domain/entities/wormhole.dart';

part 'wormhole_model.g.dart';

@HiveType(typeId: 6)
class WormholeModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String sourcePlanetId;

  @HiveField(2)
  final String targetPlanetId;

  @HiveField(3)
  final DateTime createdAt;

  WormholeModel({
    required this.id,
    required this.sourcePlanetId,
    required this.targetPlanetId,
    required this.createdAt,
  });

  factory WormholeModel.fromEntity(Wormhole entity) {
    return WormholeModel(
      id: entity.id,
      sourcePlanetId: entity.sourcePlanetId,
      targetPlanetId: entity.targetPlanetId,
      createdAt: entity.createdAt,
    );
  }

  Wormhole toEntity() {
    return Wormhole(
      id: id,
      sourcePlanetId: sourcePlanetId,
      targetPlanetId: targetPlanetId,
      createdAt: createdAt,
    );
  }
}
