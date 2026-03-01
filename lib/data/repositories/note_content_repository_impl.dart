import 'package:dartz/dartz.dart';
import 'package:orbit_app/core/errors/exceptions.dart';
import 'package:orbit_app/core/errors/failures.dart';
import 'package:orbit_app/data/datasources/local_note_content_datasource.dart';
import 'package:orbit_app/data/models/note_content_model.dart';
import 'package:orbit_app/domain/entities/note_content.dart';
import 'package:orbit_app/domain/repositories/note_content_repository.dart';

class NoteContentRepositoryImpl implements NoteContentRepository {
  final LocalNoteContentDatasource datasource;

  const NoteContentRepositoryImpl({required this.datasource});

  @override
  Future<Either<Failure, NoteContent?>> getNoteContent(String planetId) async {
    try {
      final model = await datasource.getNoteContent(planetId);
      return Right(model?.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> saveNoteContent(NoteContent entity) async {
    try {
      await datasource.saveNoteContent(NoteContentModel.fromEntity(entity));
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteNoteContent(String planetId) async {
    try {
      await datasource.deleteNoteContent(planetId);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }
}
