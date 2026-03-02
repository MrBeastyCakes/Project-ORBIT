import 'package:hive/hive.dart';
import 'package:orbit_app/core/errors/exceptions.dart';
import 'package:orbit_app/data/models/note_content_model.dart';
import 'package:orbit_app/data/models/planet_model.dart';
import 'package:orbit_app/data/models/star_model.dart';

/// A single search hit: the planet id and an optional text snippet.
class SearchHit {
  final String planetId;
  final String? snippet;

  const SearchHit({required this.planetId, this.snippet});
}

class LocalSearchDatasource {
  final Box<NoteContentModel> noteContentsBox;
  final Box<PlanetModel> planetsBox;
  final Box<StarModel> starsBox;

  const LocalSearchDatasource({
    required this.noteContentsBox,
    required this.planetsBox,
    required this.starsBox,
  });

  Future<List<SearchHit>> searchNotes(String query) async {
    try {
      final lowerQuery = query.toLowerCase();
      final hits = <String, SearchHit>{};

      // 1. Match planet names
      for (final planet in planetsBox.values) {
        if (planet.name.toLowerCase().contains(lowerQuery)) {
          hits[planet.id] = SearchHit(planetId: planet.id, snippet: null);
        }
      }

      // 2. Match star names — all planets under that star become results
      for (final star in starsBox.values) {
        if (star.name.toLowerCase().contains(lowerQuery)) {
          for (final planet in planetsBox.values) {
            if (planet.parentStarId == star.id && !hits.containsKey(planet.id)) {
              hits[planet.id] = SearchHit(
                planetId: planet.id,
                snippet: 'In star: ${star.name}',
              );
            }
          }
        }
      }

      // 3. Match note content — produces snippet around first match
      for (final note in noteContentsBox.values) {
        final lowerText = note.plainText.toLowerCase();
        final index = lowerText.indexOf(lowerQuery);
        if (index >= 0 && !hits.containsKey(note.id)) {
          final snippet = _extractSnippet(note.plainText, index, lowerQuery.length);
          hits[note.id] = SearchHit(planetId: note.id, snippet: snippet);
        }
      }

      return hits.values.toList();
    } catch (e) {
      throw CacheException('Failed to search notes: $e');
    }
  }

  /// Extracts a ~120-char snippet centred on the match at [matchStart].
  String _extractSnippet(String text, int matchStart, int matchLen) {
    const contextChars = 50;
    final start = (matchStart - contextChars).clamp(0, text.length);
    final end = (matchStart + matchLen + contextChars).clamp(0, text.length);
    final raw = text.substring(start, end).replaceAll('\n', ' ').trim();
    final prefix = start > 0 ? '...' : '';
    final suffix = end < text.length ? '...' : '';
    return '$prefix$raw$suffix';
  }
}
