import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/asteroid.dart';
import '../repositories/celestial_body_repository.dart';

class GetAllAsteroids extends UseCase<List<Asteroid>, NoParams> {
  final CelestialBodyRepository repository;

  GetAllAsteroids({required this.repository});

  @override
  Future<Either<Failure, List<Asteroid>>> call(NoParams params) =>
      repository.getAllAsteroids();
}
