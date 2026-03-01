import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/planet.dart';
import '../repositories/celestial_body_repository.dart';

class GetPlanetsForStar extends UseCase<List<Planet>, GetPlanetsForStarParams> {
  final CelestialBodyRepository repository;

  GetPlanetsForStar({required this.repository});

  @override
  Future<Either<Failure, List<Planet>>> call(
      GetPlanetsForStarParams params) async {
    final result = await repository.getAllPlanets();
    return result.map(
      (planets) =>
          planets.where((p) => p.parentStarId == params.starId).toList(),
    );
  }
}

class GetPlanetsForStarParams extends Equatable {
  final String starId;

  const GetPlanetsForStarParams({required this.starId});

  @override
  List<Object?> get props => [starId];
}
