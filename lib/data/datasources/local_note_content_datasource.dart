import 'package:hive/hive.dart';
import 'package:orbit_app/core/errors/exceptions.dart';
import 'package:orbit_app/data/models/note_content_model.dart';

class LocalNoteContentDatasource {
  final Box<NoteContentModel> noteContentsBox;

  const LocalNoteContentDatasource({required this.noteContentsBox});

  Future<NoteContentModel?> getNoteContent(String planetId) async {
    try {
      return noteContentsBox.get(planetId);
    } catch (e) {
      throw CacheException('Failed to get note content: $e');
    }
  }

  Future<void> saveNoteContent(NoteContentModel model) async {
    try {
      await noteContentsBox.put(model.id, model);
    } catch (e) {
      throw CacheException('Failed to save note content: $e');
    }
  }

  Future<void> deleteNoteContent(String planetId) async {
    try {
      await noteContentsBox.delete(planetId);
    } catch (e) {
      throw CacheException('Failed to delete note content: $e');
    }
  }
}
