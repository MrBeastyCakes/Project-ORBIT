import 'package:hive/hive.dart';
import 'package:orbit_app/domain/entities/planet.dart';

part 'planet_model.g.dart';

@HiveType(typeId: 2)
class PlanetModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double x;

  @HiveField(3)
  final double y;

  @HiveField(4)
  final double mass;

  @HiveField(5)
  final String parentStarId;

  @HiveField(6)
  final double orbitRadius;

  @HiveField(7)
  final double orbitAngle;

  @HiveField(8)
  final int color;

  @HiveField(9)
  final int wordCount;

  @HiveField(10)
  final DateTime? lastOpenedAt;

  @HiveField(11)
  final String visualState; // stored as string name

  @HiveField(12)
  final DateTime createdAt;

  @HiveField(13)
  final DateTime updatedAt;

  PlanetModel({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    required this.mass,
    required this.parentStarId,
    required this.orbitRadius,
    required this.orbitAngle,
    required this.color,
    required this.wordCount,
    this.lastOpenedAt,
    required this.visualState,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PlanetModel.fromEntity(Planet entity) {
    return PlanetModel(
      id: entity.id,
      name: entity.name,
      x: entity.x,
      y: entity.y,
      mass: entity.mass,
      parentStarId: entity.parentStarId,
      orbitRadius: entity.orbitRadius,
      orbitAngle: entity.orbitAngle,
      color: entity.color,
      wordCount: entity.wordCount,
      lastOpenedAt: entity.lastOpenedAt,
      visualState: entity.visualState.name,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Planet toEntity() {
    return Planet(
      id: id,
      name: name,
      x: x,
      y: y,
      mass: mass,
      parentStarId: parentStarId,
      orbitRadius: orbitRadius,
      orbitAngle: orbitAngle,
      color: color,
      wordCount: wordCount,
      lastOpenedAt: lastOpenedAt,
      visualState: PlanetVisualState.values.firstWhere(
        (e) => e.name == visualState,
        orElse: () => PlanetVisualState.normal,
      ),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
