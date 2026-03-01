import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../../core/constants/orbit_constants.dart';
import '../entities/planet.dart';
import '../entities/note_content.dart';
import '../repositories/celestial_body_repository.dart';
import '../repositories/note_content_repository.dart';

class UpdatePlanetContent extends UseCase<void, UpdatePlanetContentParams> {
  final CelestialBodyRepository celestialBodyRepository;
  final NoteContentRepository noteContentRepository;

  UpdatePlanetContent({
    required this.celestialBodyRepository,
    required this.noteContentRepository,
  });

  @override
  Future<Either<Failure, void>> call(UpdatePlanetContentParams params) async {
    final saveResult =
        await noteContentRepository.saveNoteContent(params.noteContent);
    final saveFailure = saveResult.fold<Failure?>((f) => f, (_) => null);
    if (saveFailure != null) return Left(saveFailure);

    final planetsResult = await celestialBodyRepository.getAllPlanets();
    return planetsResult.fold(
      Left.new,
      (planets) async {
        final planetIndex =
            planets.indexWhere((p) => p.id == params.noteContent.id);
        if (planetIndex == -1) {
          return const Left(NotFoundFailure('Planet not found.'));
        }
        final planet = planets[planetIndex];
        final wordCount = _countWords(params.noteContent.plainText);
        final visualState = _deriveVisualState(planet, wordCount);

        final updated = Planet(
          id: planet.id,
          name: planet.name,
          x: planet.x,
          y: planet.y,
          mass: planet.mass,
          parentStarId: planet.parentStarId,
          orbitRadius: planet.orbitRadius,
          orbitAngle: planet.orbitAngle,
          color: planet.color,
          createdAt: planet.createdAt,
          updatedAt: DateTime.now(),
          wordCount: wordCount,
          lastOpenedAt: planet.lastOpenedAt,
          visualState: visualState,
        );
        return celestialBodyRepository.insertPlanet(updated);
      },
    );
  }

  int _countWords(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed.split(RegExp(r'\s+')).length;
  }

  PlanetVisualState _deriveVisualState(Planet planet, int wordCount) {
    if (wordCount >= OrbitConstants.gasGiantWordCount) {
      return PlanetVisualState.gasGiant;
    }
    final inactiveCutoff = DateTime.now().subtract(
      const Duration(days: OrbitConstants.dwarfPlanetInactiveDays),
    );
    if (planet.lastOpenedAt != null &&
        planet.lastOpenedAt!.isBefore(inactiveCutoff) &&
        wordCount > 0) {
      return PlanetVisualState.dwarfPlanet;
    }
    if (wordCount == 0) return PlanetVisualState.protostar;
    return PlanetVisualState.normal;
  }
}

class UpdatePlanetContentParams extends Equatable {
  final NoteContent noteContent;

  const UpdatePlanetContentParams({required this.noteContent});

  @override
  List<Object?> get props => [noteContent];
}
