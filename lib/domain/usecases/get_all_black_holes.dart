import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/black_hole.dart';
import '../repositories/celestial_body_repository.dart';

class GetAllBlackHoles extends UseCase<List<BlackHole>, NoParams> {
  final CelestialBodyRepository repository;

  GetAllBlackHoles({required this.repository});

  @override
  Future<Either<Failure, List<BlackHole>>> call(NoParams params) =>
      repository.getAllBlackHoles();
}
