import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/note_content.dart';
import '../../domain/repositories/note_content_repository.dart';
import '../../core/errors/failures.dart';
import 'providers.dart';

class EditorState {
  final String? planetId;
  final NoteContent? content;
  final bool isLoading;
  final bool isDirty;
  final Failure? error;

  const EditorState({
    this.planetId,
    this.content,
    this.isLoading = false,
    this.isDirty = false,
    this.error,
  });

  EditorState copyWith({
    String? planetId,
    NoteContent? content,
    bool? isLoading,
    bool? isDirty,
    Failure? error,
    bool clearPlanetId = false,
    bool clearContent = false,
    bool clearError = false,
  }) {
    return EditorState(
      planetId: clearPlanetId ? null : (planetId ?? this.planetId),
      content: clearContent ? null : (content ?? this.content),
      isLoading: isLoading ?? this.isLoading,
      isDirty: isDirty ?? this.isDirty,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class EditorNotifier extends StateNotifier<EditorState> {
  final NoteContentRepository _repository;

  EditorNotifier(this._repository) : super(const EditorState());

  Future<void> openNote(String planetId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.getNoteContent(planetId);
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: failure),
      (content) => state = state.copyWith(
        planetId: planetId,
        // content may be null if no note exists yet for this planet
        content: content,
        isLoading: false,
        isDirty: false,
      ),
    );
  }

  void updateContent(String deltaJson, String plainText) {
    if (state.planetId == null) return;
    final updated = NoteContent(
      id: state.planetId!,
      deltaJson: deltaJson,
      plainText: plainText,
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(content: updated, isDirty: true);
  }

  Future<void> saveNote() async {
    final content = state.content;
    if (content == null || !state.isDirty) return;
    final result = await _repository.saveNoteContent(content);
    result.fold(
      (failure) => state = state.copyWith(error: failure),
      // saveNoteContent returns void — fold right gives null, just clear dirty
      (_) => state = state.copyWith(isDirty: false),
    );
  }

  void closeNote() {
    state = const EditorState();
  }
}

final editorProvider = StateNotifierProvider<EditorNotifier, EditorState>(
  (ref) {
    final repository = ref.watch(noteContentRepositoryProvider);
    return EditorNotifier(repository);
  },
);

// Repository provider — wired to data layer via DI providers.
final noteContentRepositoryProvider =
    Provider<NoteContentRepository>((ref) {
  return ref.watch(noteContentRepositoryImplProvider);
});
