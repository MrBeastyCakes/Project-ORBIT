import 'celestial_body.dart';

enum PlanetVisualState { protostar, normal, gasGiant, dwarfPlanet }

class Planet extends CelestialBody {
  final int wordCount;
  final DateTime? lastOpenedAt;
  final PlanetVisualState visualState;

  String get parentStarId => parentId!;

  const Planet({
    required super.id,
    required super.name,
    required super.x,
    required super.y,
    required super.mass,
    required String parentStarId,
    required super.orbitRadius,
    required super.orbitAngle,
    required super.color,
    required super.createdAt,
    required super.updatedAt,
    required this.wordCount,
    this.lastOpenedAt,
    required this.visualState,
  }) : super(parentId: parentStarId);

  @override
  List<Object?> get props => [
        ...super.props,
        wordCount,
        lastOpenedAt,
        visualState,
      ];
}
