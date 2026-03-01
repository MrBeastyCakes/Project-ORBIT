import 'package:hive/hive.dart';
import 'package:orbit_app/domain/entities/black_hole.dart';

part 'black_hole_model.g.dart';

@HiveType(typeId: 0)
class BlackHoleModel extends HiveObject {
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
  final int color;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime updatedAt;

  BlackHoleModel({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    required this.mass,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BlackHoleModel.fromEntity(BlackHole entity) {
    return BlackHoleModel(
      id: entity.id,
      name: entity.name,
      x: entity.x,
      y: entity.y,
      mass: entity.mass,
      color: entity.color,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  BlackHole toEntity() {
    return BlackHole(
      id: id,
      name: name,
      x: x,
      y: y,
      mass: mass,
      orbitRadius: 0,
      orbitAngle: 0,
      color: color,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
