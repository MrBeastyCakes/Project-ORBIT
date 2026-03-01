import 'package:hive/hive.dart';
import 'package:orbit_app/domain/entities/star.dart';

part 'star_model.g.dart';

@HiveType(typeId: 1)
class StarModel extends HiveObject {
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
  final String parentBlackHoleId;

  @HiveField(6)
  final double orbitRadius;

  @HiveField(7)
  final double orbitAngle;

  @HiveField(8)
  final int color;

  @HiveField(9)
  final DateTime createdAt;

  @HiveField(10)
  final DateTime updatedAt;

  StarModel({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    required this.mass,
    required this.parentBlackHoleId,
    required this.orbitRadius,
    required this.orbitAngle,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StarModel.fromEntity(Star entity) {
    return StarModel(
      id: entity.id,
      name: entity.name,
      x: entity.x,
      y: entity.y,
      mass: entity.mass,
      parentBlackHoleId: entity.parentBlackHoleId,
      orbitRadius: entity.orbitRadius,
      orbitAngle: entity.orbitAngle,
      color: entity.color,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Star toEntity() {
    return Star(
      id: id,
      name: name,
      x: x,
      y: y,
      mass: mass,
      parentBlackHoleId: parentBlackHoleId,
      orbitRadius: orbitRadius,
      orbitAngle: orbitAngle,
      color: color,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
