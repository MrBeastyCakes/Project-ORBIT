import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/wormhole.dart';
import '../repositories/wormhole_repository.dart';

class CreateWormhole extends UseCase<Wormhole, CreateWormholeParams> {
  final WormholeRepository repository;

  CreateWormhole({required this.repository});

  @override
  Future<Either<Failure, Wormhole>> call(CreateWormholeParams params) async {
    if (params.wormhole.sourcePlanetId == params.wormhole.targetPlanetId) {
      return const Left(
          ValidationFailure('Wormhole source and target cannot be the same planet.'));
    }
    return repository.createWormhole(params.wormhole);
  }
}

class CreateWormholeParams extends Equatable {
  final Wormhole wormhole;

  const CreateWormholeParams({required this.wormhole});

  @override
  List<Object?> get props => [wormhole];
}
