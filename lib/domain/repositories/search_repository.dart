import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../data/datasources/local_search_datasource.dart';

abstract class SearchRepository {
  Future<Either<Failure, List<SearchHit>>> searchNotes(String query);
}
