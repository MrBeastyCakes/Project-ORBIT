import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/moon.dart';
import '../repositories/celestial_body_repository.dart';

class GetMoonsForPlanet extends UseCase<List<Moon>, GetMoonsForPlanetParams> {
  final CelestialBodyRepository repository;

  GetMoonsForPlanet({required this.repository});

  @override
  Future<Either<Failure, List<Moon>>> call(
      GetMoonsForPlanetParams params) async {
    final result = await repository.getAllMoons();
    return result.map(
      (moons) =>
          moons.where((m) => m.parentPlanetId == params.planetId).toList(),
    );
  }
}

class GetMoonsForPlanetParams extends Equatable {
  final String planetId;

  const GetMoonsForPlanetParams({required this.planetId});

  @override
  List<Object?> get props => [planetId];
}
