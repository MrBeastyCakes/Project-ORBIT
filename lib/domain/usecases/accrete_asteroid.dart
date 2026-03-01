import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../../core/utils/id_generator.dart';
import '../entities/asteroid.dart';
import '../entities/planet.dart';
import '../entities/note_content.dart';
import '../repositories/celestial_body_repository.dart';
import '../repositories/note_content_repository.dart';

/// Result of accreting an asteroid.
class AccreteResult extends Equatable {
  final Planet planet;
  final bool wasPromoted;

  const AccreteResult({required this.planet, required this.wasPromoted});

  @override
  List<Object?> get props => [planet, wasPromoted];
}

class AccreteAsteroid extends UseCase<AccreteResult, AccreteAsteroidParams> {
  final CelestialBodyRepository celestialBodyRepository;
  final NoteContentRepository noteContentRepository;

  AccreteAsteroid({
    required this.celestialBodyRepository,
    required this.noteContentRepository,
  });

  @override
  Future<Either<Failure, AccreteResult>> call(
      AccreteAsteroidParams params) async {
    if (params.targetPlanetId != null) {
      return _mergeIntoPlanet(params.asteroid, params.targetPlanetId!);
    } else if (params.promotionParams != null) {
      return _promoteToNewPlanet(params.asteroid, params.promotionParams!);
    }
    return const Left(ValidationFailure(
        'Must supply either targetPlanetId or promotionParams.'));
  }

  Future<Either<Failure, AccreteResult>> _mergeIntoPlanet(
      Asteroid asteroid, String planetId) async {
    final noteResult = await noteContentRepository.getNoteContent(planetId);
    return noteResult.fold(
      Left.new,
      (existing) async {
        final appendedText =
            existing != null ? '${existing.plainText}\n\n${asteroid.text}' : asteroid.text;
        final updatedNote = NoteContent(
          id: planetId,
          deltaJson: existing?.deltaJson ?? '{"ops":[{"insert":"\\n"}]}',
          plainText: appendedText,
          updatedAt: DateTime.now(),
        );
        final saveResult =
            await noteContentRepository.saveNoteContent(updatedNote);
        final saveFailure = saveResult.fold<Failure?>((f) => f, (_) => null);
        if (saveFailure != null) return Left(saveFailure);

        final planetsResult = await celestialBodyRepository.getAllPlanets();
        return planetsResult.fold(
          Left.new,
          (planets) async {
            final planet = planets.where((p) => p.id == planetId).firstOrNull;
            if (planet == null) {
              return const Left(NotFoundFailure('Planet not found.'));
            }
            await celestialBodyRepository.deleteAsteroid(asteroid.id);
            return Right(AccreteResult(planet: planet, wasPromoted: false));
          },
        );
      },
    );
  }

  Future<Either<Failure, AccreteResult>> _promoteToNewPlanet(
      Asteroid asteroid, AsteroidPromotionParams promo) async {
    final newPlanet = Planet(
      id: generateId(),
      name: promo.name,
      x: asteroid.x,
      y: asteroid.y,
      mass: 1.0,
      parentStarId: promo.parentStarId,
      orbitRadius: promo.orbitRadius,
      orbitAngle: promo.orbitAngle,
      color: promo.color,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      wordCount: asteroid.text.trim().split(RegExp(r'\s+')).length,
      lastOpenedAt: null,
      visualState: PlanetVisualState.protostar,
    );

    final insertResult = await celestialBodyRepository.insertPlanet(newPlanet);
    final insertFailure = insertResult.fold<Failure?>((f) => f, (_) => null);
    if (insertFailure != null) return Left(insertFailure);

    final noteContent = NoteContent(
      id: newPlanet.id,
      deltaJson: '{"ops":[{"insert":"${_escape(asteroid.text)}\\n"}]}',
      plainText: asteroid.text,
      updatedAt: DateTime.now(),
    );
    final saveResult =
        await noteContentRepository.saveNoteContent(noteContent);
    final saveFailure = saveResult.fold<Failure?>((f) => f, (_) => null);
    if (saveFailure != null) return Left(saveFailure);

    await celestialBodyRepository.deleteAsteroid(asteroid.id);
    return Right(AccreteResult(planet: newPlanet, wasPromoted: true));
  }

  String _escape(String s) =>
      s.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
}

class AsteroidPromotionParams extends Equatable {
  final String name;
  final String parentStarId;
  final double orbitRadius;
  final double orbitAngle;
  final int color;

  const AsteroidPromotionParams({
    required this.name,
    required this.parentStarId,
    required this.orbitRadius,
    required this.orbitAngle,
    required this.color,
  });

  @override
  List<Object?> get props =>
      [name, parentStarId, orbitRadius, orbitAngle, color];
}

class AccreteAsteroidParams extends Equatable {
  final Asteroid asteroid;
  final String? targetPlanetId;
  final AsteroidPromotionParams? promotionParams;

  const AccreteAsteroidParams({
    required this.asteroid,
    this.targetPlanetId,
    this.promotionParams,
  });

  @override
  List<Object?> get props => [asteroid, targetPlanetId, promotionParams];
}
