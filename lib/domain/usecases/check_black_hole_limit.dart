import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../../core/constants/orbit_constants.dart';
import '../entities/user_profile.dart';
import '../repositories/celestial_body_repository.dart';

class CheckBlackHoleLimit extends UseCase<bool, CheckBlackHoleLimitParams> {
  final CelestialBodyRepository repository;
  final UserTier userTier;

  CheckBlackHoleLimit({required this.repository, required this.userTier});

  /// Returns [true] if the user can create another black hole.
  @override
  Future<Either<Failure, bool>> call(CheckBlackHoleLimitParams params) async {
    if (userTier == UserTier.paid) return const Right(true);
    final countResult = await repository.getBlackHoleCount();
    return countResult.map(
        (count) => count < OrbitConstants.freeBlackHoleLimit);
  }
}

class CheckBlackHoleLimitParams extends Equatable {
  const CheckBlackHoleLimitParams();

  @override
  List<Object?> get props => [];
}
