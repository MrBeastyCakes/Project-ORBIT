import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/star.dart';
import '../repositories/celestial_body_repository.dart';

class GetStarsForBlackHole
    extends UseCase<List<Star>, GetStarsForBlackHoleParams> {
  final CelestialBodyRepository repository;

  GetStarsForBlackHole({required this.repository});

  @override
  Future<Either<Failure, List<Star>>> call(
      GetStarsForBlackHoleParams params) async {
    final result = await repository.getAllStars();
    return result.map(
      (stars) =>
          stars.where((s) => s.parentBlackHoleId == params.blackHoleId).toList(),
    );
  }
}

class GetStarsForBlackHoleParams extends Equatable {
  final String blackHoleId;

  const GetStarsForBlackHoleParams({required this.blackHoleId});

  @override
  List<Object?> get props => [blackHoleId];
}
