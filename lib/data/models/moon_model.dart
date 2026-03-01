import 'package:hive/hive.dart';
import 'package:orbit_app/domain/entities/moon.dart';

part 'moon_model.g.dart';

@HiveType(typeId: 3)
class MoonModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String parentPlanetId;

  @HiveField(2)
  final String label;

  @HiveField(3)
  final bool isCompleted;

  @HiveField(4)
  final double orbitRadius;

  @HiveField(5)
  final double orbitAngle;

  MoonModel({
    required this.id,
    required this.parentPlanetId,
    required this.label,
    required this.isCompleted,
    required this.orbitRadius,
    required this.orbitAngle,
  });

  factory MoonModel.fromEntity(Moon entity) {
    return MoonModel(
      id: entity.id,
      parentPlanetId: entity.parentPlanetId,
      label: entity.label,
      isCompleted: entity.isCompleted,
      orbitRadius: entity.orbitRadius,
      orbitAngle: entity.orbitAngle,
    );
  }

  Moon toEntity() {
    return Moon(
      id: id,
      parentPlanetId: parentPlanetId,
      label: label,
      isCompleted: isCompleted,
      orbitRadius: orbitRadius,
      orbitAngle: orbitAngle,
    );
  }
}
