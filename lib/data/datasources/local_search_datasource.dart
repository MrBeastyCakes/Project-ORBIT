import 'package:hive/hive.dart';
import 'package:orbit_app/core/errors/exceptions.dart';
import 'package:orbit_app/data/models/note_content_model.dart';

class LocalSearchDatasource {
  final Box<NoteContentModel> noteContentsBox;

  const LocalSearchDatasource({required this.noteContentsBox});

  Future<List<String>> searchNotes(String query) async {
    try {
      final lowerQuery = query.toLowerCase();
      return noteContentsBox.values
          .where((n) => n.plainText.toLowerCase().contains(lowerQuery))
          .map((n) => n.id)
          .toList();
    } catch (e) {
      throw CacheException('Failed to search notes: $e');
    }
  }
}
