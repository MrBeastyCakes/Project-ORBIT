import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/moon.dart';
import '../repositories/celestial_body_repository.dart';

class ToggleMoonCompleted extends UseCase<void, ToggleMoonCompletedParams> {
  final CelestialBodyRepository repository;

  ToggleMoonCompleted({required this.repository});

  @override
  Future<Either<Failure, void>> call(ToggleMoonCompletedParams params) async {
    final moonsResult = await repository.getAllMoons();
    return moonsResult.fold(
      Left.new,
      (moons) async {
        final moon = moons.where((m) => m.id == params.moonId).firstOrNull;
        if (moon == null) {
          return const Left(NotFoundFailure('Moon not found.'));
        }
        final updated = Moon(
          id: moon.id,
          parentPlanetId: moon.parentPlanetId,
          label: moon.label,
          isCompleted: !moon.isCompleted,
          orbitRadius: moon.orbitRadius,
          orbitAngle: moon.orbitAngle,
        );
        return repository.insertMoon(updated);
      },
    );
  }
}

class ToggleMoonCompletedParams extends Equatable {
  final String moonId;

  const ToggleMoonCompletedParams({required this.moonId});

  @override
  List<Object?> get props => [moonId];
}
