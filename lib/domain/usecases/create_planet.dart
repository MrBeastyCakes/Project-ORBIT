import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/planet.dart';
import '../entities/note_content.dart';
import '../repositories/celestial_body_repository.dart';
import '../repositories/note_content_repository.dart';

class CreatePlanet extends UseCase<void, CreatePlanetParams> {
  final CelestialBodyRepository celestialBodyRepository;
  final NoteContentRepository noteContentRepository;

  CreatePlanet({
    required this.celestialBodyRepository,
    required this.noteContentRepository,
  });

  @override
  Future<Either<Failure, void>> call(CreatePlanetParams params) async {
    // Validate parent star exists
    final starsResult = await celestialBodyRepository.getAllStars();
    final starsFailure = starsResult.fold<Failure?>((f) => f, (_) => null);
    if (starsFailure != null) return Left(starsFailure);

    final stars = starsResult.getOrElse(() => []);
    if (!stars.any((s) => s.id == params.planet.parentStarId)) {
      return const Left(NotFoundFailure('Parent star not found.'));
    }

    // Ensure visualState = protostar on creation
    final planet = params.planet;
    final newPlanet = Planet(
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
      updatedAt: planet.updatedAt,
      wordCount: 0,
      lastOpenedAt: null,
      visualState: PlanetVisualState.protostar,
    );

    final insertResult = await celestialBodyRepository.insertPlanet(newPlanet);
    return insertResult.fold(
      Left.new,
      (_) async {
        final noteContent = NoteContent(
          id: newPlanet.id,
          deltaJson: '{"ops":[{"insert":"\\n"}]}',
          plainText: '',
          updatedAt: DateTime.now(),
        );
        return noteContentRepository.saveNoteContent(noteContent);
      },
    );
  }
}

class CreatePlanetParams extends Equatable {
  final Planet planet;

  const CreatePlanetParams({required this.planet});

  @override
  List<Object?> get props => [planet];
}
