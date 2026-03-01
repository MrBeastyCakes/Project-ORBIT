import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../repositories/celestial_body_repository.dart';
import '../repositories/note_content_repository.dart';

class DeleteStar extends UseCase<void, DeleteStarParams> {
  final CelestialBodyRepository celestialBodyRepository;
  final NoteContentRepository noteContentRepository;

  DeleteStar({
    required this.celestialBodyRepository,
    required this.noteContentRepository,
  });

  @override
  Future<Either<Failure, void>> call(DeleteStarParams params) async {
    final planetsResult = await celestialBodyRepository.getAllPlanets();
    final planetsFailure = planetsResult.fold<Failure?>((f) => f, (_) => null);
    if (planetsFailure != null) return Left(planetsFailure);

    final childPlanets = planetsResult
        .getOrElse(() => [])
        .where((p) => p.parentStarId == params.starId);

    for (final planet in childPlanets) {
      await noteContentRepository.deleteNoteContent(planet.id);
      await celestialBodyRepository.deletePlanet(planet.id);
    }
    return celestialBodyRepository.deleteStar(params.starId);
  }
}

class DeleteStarParams extends Equatable {
  final String starId;

  const DeleteStarParams({required this.starId});

  @override
  List<Object?> get props => [starId];
}
