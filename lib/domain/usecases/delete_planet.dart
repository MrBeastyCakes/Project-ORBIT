import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../repositories/celestial_body_repository.dart';
import '../repositories/note_content_repository.dart';

class DeletePlanet extends UseCase<void, DeletePlanetParams> {
  final CelestialBodyRepository celestialBodyRepository;
  final NoteContentRepository noteContentRepository;

  DeletePlanet({
    required this.celestialBodyRepository,
    required this.noteContentRepository,
  });

  @override
  Future<Either<Failure, void>> call(DeletePlanetParams params) async {
    await noteContentRepository.deleteNoteContent(params.planetId);
    return celestialBodyRepository.deletePlanet(params.planetId);
  }
}

class DeletePlanetParams extends Equatable {
  final String planetId;

  const DeletePlanetParams({required this.planetId});

  @override
  List<Object?> get props => [planetId];
}
