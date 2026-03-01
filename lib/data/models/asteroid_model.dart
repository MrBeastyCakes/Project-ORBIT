import 'package:hive/hive.dart';
import 'package:orbit_app/domain/entities/asteroid.dart';

part 'asteroid_model.g.dart';

@HiveType(typeId: 4)
class AsteroidModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String text;

  @HiveField(2)
  final double x;

  @HiveField(3)
  final double y;

  @HiveField(4)
  final DateTime createdAt;

  AsteroidModel({
    required this.id,
    required this.text,
    required this.x,
    required this.y,
    required this.createdAt,
  });

  factory AsteroidModel.fromEntity(Asteroid entity) {
    return AsteroidModel(
      id: entity.id,
      text: entity.text,
      x: entity.x,
      y: entity.y,
      createdAt: entity.createdAt,
    );
  }

  Asteroid toEntity() {
    return Asteroid(
      id: id,
      text: text,
      x: x,
      y: y,
      createdAt: createdAt,
    );
  }
}
