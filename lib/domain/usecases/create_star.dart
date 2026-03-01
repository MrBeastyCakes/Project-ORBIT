import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/star.dart';
import '../repositories/celestial_body_repository.dart';

class CreateStar extends UseCase<void, CreateStarParams> {
  final CelestialBodyRepository repository;

  CreateStar({required this.repository});

  @override
  Future<Either<Failure, void>> call(CreateStarParams params) async {
    // Validate parent black hole exists by checking the full list
    final bhResult = await repository.getAllBlackHoles();
    return bhResult.fold(
      Left.new,
      (blackHoles) async {
        final exists =
            blackHoles.any((bh) => bh.id == params.star.parentBlackHoleId);
        if (!exists) {
          return const Left(NotFoundFailure('Parent black hole not found.'));
        }
        return repository.insertStar(params.star);
      },
    );
  }
}

class CreateStarParams extends Equatable {
  final Star star;

  const CreateStarParams({required this.star});

  @override
  List<Object?> get props => [star];
}
