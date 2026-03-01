import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../../core/constants/orbit_constants.dart';
import '../entities/black_hole.dart';
import '../entities/user_profile.dart';
import '../repositories/celestial_body_repository.dart';

class CreateBlackHole extends UseCase<void, CreateBlackHoleParams> {
  final CelestialBodyRepository repository;
  final UserTier userTier;

  CreateBlackHole({required this.repository, required this.userTier});

  @override
  Future<Either<Failure, void>> call(CreateBlackHoleParams params) async {
    if (params.blackHole.name.trim().isEmpty) {
      return const Left(ValidationFailure('Name cannot be empty.'));
    }
    if (userTier == UserTier.free) {
      final countResult = await repository.getBlackHoleCount();
      final countFailure = countResult.fold<Failure?>((f) => f, (_) => null);
      if (countFailure != null) return Left(countFailure);
      final count = countResult.getOrElse(() => 0);
      if (count >= OrbitConstants.freeBlackHoleLimit) {
        return const Left(TierLimitFailure(
          'Free tier allows a maximum of ${OrbitConstants.freeBlackHoleLimit} black holes.',
        ));
      }
    }
    return repository.insertBlackHole(params.blackHole);
  }
}

class CreateBlackHoleParams extends Equatable {
  final BlackHole blackHole;

  const CreateBlackHoleParams({required this.blackHole});

  @override
  List<Object?> get props => [blackHole];
}
