import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../repositories/celestial_body_repository.dart';
import '../repositories/constellation_repository.dart';
import '../repositories/note_content_repository.dart';
import '../repositories/wormhole_repository.dart';

class DeletePlanet extends UseCase<void, DeletePlanetParams> {
  final CelestialBodyRepository celestialBodyRepository;
  final NoteContentRepository noteContentRepository;
  final WormholeRepository wormholeRepository;
  final ConstellationRepository constellationRepository;

  DeletePlanet({
    required this.celestialBodyRepository,
    required this.noteContentRepository,
    required this.wormholeRepository,
    required this.constellationRepository,
  });

  @override
  Future<Either<Failure, void>> call(DeletePlanetParams params) async {
    // Delete note content first
    await noteContentRepository.deleteNoteContent(params.planetId);

    // Remove any wormholes referencing this planet
    final wormholesResult = await wormholeRepository.getWormholes();
    wormholesResult.fold((_) {}, (wormholes) async {
      for (final w in wormholes) {
        if (w.sourcePlanetId == params.planetId ||
            w.targetPlanetId == params.planetId) {
          await wormholeRepository.deleteWormhole(w.id);
        }
      }
    });

    // Remove any constellation links referencing this planet
    final linksResult = await constellationRepository.getConstellationLinks();
    linksResult.fold((_) {}, (links) async {
      for (final l in links) {
        if (l.sourcePlanetId == params.planetId ||
            l.targetPlanetId == params.planetId) {
          await constellationRepository.deleteConstellationLink(l.id);
        }
      }
    });

    return celestialBodyRepository.deletePlanet(params.planetId);
  }
}

class DeletePlanetParams extends Equatable {
  final String planetId;

  const DeletePlanetParams({required this.planetId});

  @override
  List<Object?> get props => [planetId];
}
