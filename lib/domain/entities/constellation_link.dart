import 'package:equatable/equatable.dart';

class ConstellationLink extends Equatable {
  final String id;
  final String sourcePlanetId;
  final String targetPlanetId;
  final DateTime createdAt;

  const ConstellationLink({
    required this.id,
    required this.sourcePlanetId,
    required this.targetPlanetId,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, sourcePlanetId, targetPlanetId, createdAt];
}
