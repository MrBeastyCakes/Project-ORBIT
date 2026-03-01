import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/wormhole.dart';

abstract class WormholeRepository {
  Future<Either<Failure, Wormhole>> createWormhole(Wormhole wormhole);
  Future<Either<Failure, List<Wormhole>>> getWormholes();
  Future<Either<Failure, Unit>> deleteWormhole(String id);
}
