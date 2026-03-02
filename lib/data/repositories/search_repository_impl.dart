import 'package:dartz/dartz.dart';
import 'package:orbit_app/core/errors/exceptions.dart';
import 'package:orbit_app/core/errors/failures.dart';
import 'package:orbit_app/data/datasources/local_search_datasource.dart';
import 'package:orbit_app/domain/repositories/search_repository.dart';

class SearchRepositoryImpl implements SearchRepository {
  final LocalSearchDatasource datasource;

  const SearchRepositoryImpl({required this.datasource});

  @override
  Future<Either<Failure, List<SearchHit>>> searchNotes(String query) async {
    try {
      final results = await datasource.searchNotes(query);
      return Right(results);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }
}
