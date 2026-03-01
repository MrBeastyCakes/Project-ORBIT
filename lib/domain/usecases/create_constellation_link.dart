import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/constellation_link.dart';
import '../repositories/constellation_repository.dart';

class CreateConstellationLink
    extends UseCase<ConstellationLink, CreateConstellationLinkParams> {
  final ConstellationRepository repository;

  CreateConstellationLink({required this.repository});

  @override
  Future<Either<Failure, ConstellationLink>> call(
      CreateConstellationLinkParams params) async {
    if (params.link.sourcePlanetId == params.link.targetPlanetId) {
      return const Left(
          ValidationFailure('Constellation link source and target cannot be the same planet.'));
    }
    return repository.createConstellationLink(params.link);
  }
}

class CreateConstellationLinkParams extends Equatable {
  final ConstellationLink link;

  const CreateConstellationLinkParams({required this.link});

  @override
  List<Object?> get props => [link];
}
