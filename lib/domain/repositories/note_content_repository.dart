import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/note_content.dart';

abstract class NoteContentRepository {
  Future<Either<Failure, NoteContent?>> getNoteContent(String planetId);
  Future<Either<Failure, void>> saveNoteContent(NoteContent noteContent);
  Future<Either<Failure, void>> deleteNoteContent(String planetId);
}
