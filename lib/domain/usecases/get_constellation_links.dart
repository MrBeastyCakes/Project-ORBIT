import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/constellation_link.dart';
import '../repositories/constellation_repository.dart';

class GetConstellationLinks
    extends UseCase<List<ConstellationLink>, NoParams> {
  final ConstellationRepository repository;

  GetConstellationLinks({required this.repository});

  @override
  Future<Either<Failure, List<ConstellationLink>>> call(NoParams params) =>
      repository.getConstellationLinks();
}
