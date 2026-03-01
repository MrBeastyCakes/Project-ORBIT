import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/planet.dart';
import '../../domain/repositories/search_repository.dart';
import '../../core/errors/failures.dart';
import 'providers.dart';
import 'galaxy_provider.dart';

class SearchState {
  final String query;
  final List<String> results; // planet IDs returned by search
  final bool isSearching;
  final bool isTelescopeActive;
  final Failure? error;

  const SearchState({
    this.query = '',
    this.results = const [],
    this.isSearching = false,
    this.isTelescopeActive = false,
    this.error,
  });

  SearchState copyWith({
    String? query,
    List<String>? results,
    bool? isSearching,
    bool? isTelescopeActive,
    Failure? error,
    bool clearError = false,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isSearching: isSearching ?? this.isSearching,
      isTelescopeActive: isTelescopeActive ?? this.isTelescopeActive,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class SearchNotifier extends StateNotifier<SearchState> {
  final SearchRepository _repository;
  Timer? _debounce;

  SearchNotifier(this._repository) : super(const SearchState());

  void setQuery(String query) {
    state = state.copyWith(query: query);
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      state = state.copyWith(results: [], isSearching: false);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), search);
  }

  Future<void> search() async {
    if (state.query.trim().isEmpty) {
      state = state.copyWith(results: [], isSearching: false);
      return;
    }
    state = state.copyWith(isSearching: true, clearError: true);
    final result = await _repository.searchNotes(state.query);
    result.fold(
      (failure) =>
          state = state.copyWith(isSearching: false, error: failure),
      (ids) =>
          state = state.copyWith(results: ids, isSearching: false),
    );
  }

  void activateTelescope() {
    state = state.copyWith(isTelescopeActive: true);
  }

  void deactivateTelescope() {
    state = state.copyWith(isTelescopeActive: false);
  }

  void clearSearch() {
    _debounce?.cancel();
    state = const SearchState();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final searchProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  final repository = ref.watch(searchRepositoryProvider);
  return SearchNotifier(repository);
});

/// Repository provider — wired to data layer via DI providers.
final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return ref.watch(searchRepositoryImplProvider);
});

/// Derived provider: maps search result IDs to Planet entities from galaxy state.
final searchResultPlanetsProvider = Provider<List<Planet>>((ref) {
  final searchState = ref.watch(searchProvider);
  final galaxyState = ref.watch(galaxyProvider);
  if (searchState.results.isEmpty) return const [];
  final resultSet = searchState.results.toSet();
  return galaxyState.planets
      .where((p) => resultSet.contains(p.id))
      .toList();
});
