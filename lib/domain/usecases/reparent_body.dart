import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/planet.dart';
import '../entities/star.dart';
import '../repositories/celestial_body_repository.dart';

enum ReparentBodyType { planet, star }

class ReparentBody extends UseCase<void, ReparentBodyParams> {
  final CelestialBodyRepository repository;

  ReparentBody({required this.repository});

  @override
  Future<Either<Failure, void>> call(ReparentBodyParams params) async {
    switch (params.bodyType) {
      case ReparentBodyType.planet:
        return _reparentPlanet(params.bodyId, params.newParentId);
      case ReparentBodyType.star:
        return _reparentStar(params.bodyId, params.newParentId);
    }
  }

  Future<Either<Failure, void>> _reparentPlanet(
      String planetId, String newStarId) async {
    final starsResult = await repository.getAllStars();
    final starsFailure = starsResult.fold<Failure?>((f) => f, (_) => null);
    if (starsFailure != null) return Left(starsFailure);

    final starExists =
        starsResult.getOrElse(() => []).any((s) => s.id == newStarId);
    if (!starExists) {
      return const Left(NotFoundFailure('Target star not found.'));
    }

    final planetsResult = await repository.getAllPlanets();
    return planetsResult.fold(
      Left.new,
      (planets) async {
        final planet = planets.where((p) => p.id == planetId).firstOrNull;
        if (planet == null) {
          return const Left(NotFoundFailure('Planet not found.'));
        }
        final updated = Planet(
          id: planet.id,
          name: planet.name,
          x: planet.x,
          y: planet.y,
          mass: planet.mass,
          parentStarId: newStarId,
          orbitRadius: planet.orbitRadius,
          orbitAngle: planet.orbitAngle,
          color: planet.color,
          createdAt: planet.createdAt,
          updatedAt: DateTime.now(),
          wordCount: planet.wordCount,
          lastOpenedAt: planet.lastOpenedAt,
          visualState: planet.visualState,
        );
        return repository.insertPlanet(updated);
      },
    );
  }

  Future<Either<Failure, void>> _reparentStar(
      String starId, String newBlackHoleId) async {
    final bhResult = await repository.getAllBlackHoles();
    final bhFailure = bhResult.fold<Failure?>((f) => f, (_) => null);
    if (bhFailure != null) return Left(bhFailure);

    final bhExists =
        bhResult.getOrElse(() => []).any((bh) => bh.id == newBlackHoleId);
    if (!bhExists) {
      return const Left(NotFoundFailure('Target black hole not found.'));
    }

    final starsResult = await repository.getAllStars();
    return starsResult.fold(
      Left.new,
      (stars) async {
        final star = stars.where((s) => s.id == starId).firstOrNull;
        if (star == null) {
          return const Left(NotFoundFailure('Star not found.'));
        }
        final updated = Star(
          id: star.id,
          name: star.name,
          x: star.x,
          y: star.y,
          mass: star.mass,
          parentBlackHoleId: newBlackHoleId,
          orbitRadius: star.orbitRadius,
          orbitAngle: star.orbitAngle,
          color: star.color,
          createdAt: star.createdAt,
          updatedAt: DateTime.now(),
        );
        return repository.insertStar(updated);
      },
    );
  }
}

class ReparentBodyParams extends Equatable {
  final String bodyId;
  final String newParentId;
  final ReparentBodyType bodyType;

  const ReparentBodyParams({
    required this.bodyId,
    required this.newParentId,
    required this.bodyType,
  });

  @override
  List<Object?> get props => [bodyId, newParentId, bodyType];
}
