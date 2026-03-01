import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../repositories/wormhole_repository.dart';

class DeleteWormhole extends UseCase<Unit, DeleteWormholeParams> {
  final WormholeRepository repository;

  DeleteWormhole({required this.repository});

  @override
  Future<Either<Failure, Unit>> call(DeleteWormholeParams params) =>
      repository.deleteWormhole(params.wormholeId);
}

class DeleteWormholeParams extends Equatable {
  final String wormholeId;

  const DeleteWormholeParams({required this.wormholeId});

  @override
  List<Object?> get props => [wormholeId];
}
