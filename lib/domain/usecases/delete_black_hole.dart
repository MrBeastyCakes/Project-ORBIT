import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../repositories/celestial_body_repository.dart';
import '../repositories/note_content_repository.dart';

class DeleteBlackHole extends UseCase<void, DeleteBlackHoleParams> {
  final CelestialBodyRepository celestialBodyRepository;
  final NoteContentRepository noteContentRepository;

  DeleteBlackHole({
    required this.celestialBodyRepository,
    required this.noteContentRepository,
  });

  @override
  Future<Either<Failure, void>> call(DeleteBlackHoleParams params) async {
    // Get all stars, then cascade through planets -> note contents
    final starsResult = await celestialBodyRepository.getAllStars();
    final starsFailure = starsResult.fold<Failure?>((f) => f, (_) => null);
    if (starsFailure != null) return Left(starsFailure);

    final allStars = starsResult.getOrElse(() => []);
    final childStars =
        allStars.where((s) => s.parentBlackHoleId == params.blackHoleId).toList();

    final planetsResult = await celestialBodyRepository.getAllPlanets();
    final planetsFailure = planetsResult.fold<Failure?>((f) => f, (_) => null);
    if (planetsFailure != null) return Left(planetsFailure);

    final allPlanets = planetsResult.getOrElse(() => []);
    final starIds = childStars.map((s) => s.id).toSet();
    final childPlanets = allPlanets.where((p) => starIds.contains(p.parentStarId));

    for (final planet in childPlanets) {
      await noteContentRepository.deleteNoteContent(planet.id);
      await celestialBodyRepository.deletePlanet(planet.id);
    }
    for (final star in childStars) {
      await celestialBodyRepository.deleteStar(star.id);
    }
    return celestialBodyRepository.deleteBlackHole(params.blackHoleId);
  }
}

class DeleteBlackHoleParams extends Equatable {
  final String blackHoleId;

  const DeleteBlackHoleParams({required this.blackHoleId});

  @override
  List<Object?> get props => [blackHoleId];
}
