import 'package:equatable/equatable.dart';

abstract class CelestialBody extends Equatable {
  final String id;
  final String name;
  final double x;
  final double y;
  final double mass;
  final String? parentId;
  final double orbitRadius;
  final double orbitAngle;
  final int color; // ARGB int
  final DateTime createdAt;
  final DateTime updatedAt;

  const CelestialBody({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    required this.mass,
    this.parentId,
    required this.orbitRadius,
    required this.orbitAngle,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        x,
        y,
        mass,
        parentId,
        orbitRadius,
        orbitAngle,
        color,
        createdAt,
        updatedAt,
      ];
}
