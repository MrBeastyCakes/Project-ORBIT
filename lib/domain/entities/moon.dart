import 'package:equatable/equatable.dart';

class Moon extends Equatable {
  final String id;
  final String parentPlanetId;
  final String label;
  final bool isCompleted;
  final double orbitRadius;
  final double orbitAngle;

  const Moon({
    required this.id,
    required this.parentPlanetId,
    required this.label,
    required this.isCompleted,
    required this.orbitRadius,
    required this.orbitAngle,
  });

  @override
  List<Object?> get props => [
        id,
        parentPlanetId,
        label,
        isCompleted,
        orbitRadius,
        orbitAngle,
      ];
}
