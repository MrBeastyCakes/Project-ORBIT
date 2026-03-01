import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';

abstract class SearchRepository {
  Future<Either<Failure, List<String>>> searchNotes(String query);
}
