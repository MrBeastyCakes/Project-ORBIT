import 'celestial_body.dart';

class BlackHole extends CelestialBody {
  const BlackHole({
    required super.id,
    required super.name,
    required super.x,
    required super.y,
    required super.mass,
    super.parentId,
    required super.orbitRadius,
    required super.orbitAngle,
    required super.color,
    required super.createdAt,
    required super.updatedAt,
  });

}
