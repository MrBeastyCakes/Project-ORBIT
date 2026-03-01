import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/wormhole.dart';
import '../repositories/wormhole_repository.dart';

class GetWormholes extends UseCase<List<Wormhole>, NoParams> {
  final WormholeRepository repository;

  GetWormholes({required this.repository});

  @override
  Future<Either<Failure, List<Wormhole>>> call(NoParams params) =>
      repository.getWormholes();
}
