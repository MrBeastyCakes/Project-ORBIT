import 'celestial_body.dart';

class Star extends CelestialBody {
  String get parentBlackHoleId => parentId!;

  const Star({
    required super.id,
    required super.name,
    required super.x,
    required super.y,
    required super.mass,
    required String parentBlackHoleId,
    required super.orbitRadius,
    required super.orbitAngle,
    required super.color,
    required super.createdAt,
    required super.updatedAt,
  }) : super(parentId: parentBlackHoleId);

}
