import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/constellation_link.dart';

abstract class ConstellationRepository {
  Future<Either<Failure, ConstellationLink>> createConstellationLink(
      ConstellationLink link);
  Future<Either<Failure, List<ConstellationLink>>> getConstellationLinks();
  Future<Either<Failure, Unit>> deleteConstellationLink(String id);
}
