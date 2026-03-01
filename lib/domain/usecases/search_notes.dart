import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../repositories/search_repository.dart';

class SearchNotes extends UseCase<List<String>, SearchNotesParams> {
  final SearchRepository repository;

  SearchNotes({required this.repository});

  @override
  Future<Either<Failure, List<String>>> call(SearchNotesParams params) async {
    if (params.query.trim().isEmpty) return const Right([]);
    return repository.searchNotes(params.query);
  }
}

class SearchNotesParams extends Equatable {
  final String query;

  const SearchNotesParams({required this.query});

  @override
  List<Object?> get props => [query];
}
