import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../../core/constants/orbit_constants.dart';
import '../entities/asteroid.dart';
import '../repositories/celestial_body_repository.dart';

class CreateAsteroid extends UseCase<void, CreateAsteroidParams> {
  final CelestialBodyRepository repository;

  CreateAsteroid({required this.repository});

  @override
  Future<Either<Failure, void>> call(CreateAsteroidParams params) async {
    if (params.asteroid.text.length > OrbitConstants.asteroidMaxLength) {
      return Left(ValidationFailure(
        'Asteroid text exceeds maximum length of ${OrbitConstants.asteroidMaxLength} characters.',
      ));
    }
    if (params.asteroid.text.trim().isEmpty) {
      return const Left(ValidationFailure('Asteroid text cannot be empty.'));
    }
    return repository.insertAsteroid(params.asteroid);
  }
}

class CreateAsteroidParams extends Equatable {
  final Asteroid asteroid;

  const CreateAsteroidParams({required this.asteroid});

  @override
  List<Object?> get props => [asteroid];
}
