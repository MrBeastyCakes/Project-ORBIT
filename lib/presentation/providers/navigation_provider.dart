import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ViewLevel { galaxy, system, planet, surface }

class NavigationState {
  final double zoomLevel;
  final String? focusedBodyId;
  final ViewLevel currentView;

  const NavigationState({
    this.zoomLevel = 1.0,
    this.focusedBodyId,
    this.currentView = ViewLevel.galaxy,
  });

  NavigationState copyWith({
    double? zoomLevel,
    String? focusedBodyId,
    bool clearFocusedBody = false,
    ViewLevel? currentView,
  }) {
    return NavigationState(
      zoomLevel: zoomLevel ?? this.zoomLevel,
      focusedBodyId:
          clearFocusedBody ? null : (focusedBodyId ?? this.focusedBodyId),
      currentView: currentView ?? this.currentView,
    );
  }
}

class NavigationNotifier extends StateNotifier<NavigationState> {
  NavigationNotifier() : super(const NavigationState());

  void zoomToBody(String id) {
    state = state.copyWith(
      focusedBodyId: id,
      currentView: ViewLevel.system,
    );
  }

  void zoomOut() {
    final newView = switch (state.currentView) {
      ViewLevel.surface => ViewLevel.planet,
      ViewLevel.planet => ViewLevel.system,
      ViewLevel.system => ViewLevel.galaxy,
      ViewLevel.galaxy => ViewLevel.galaxy,
    };
    state = state.copyWith(
      currentView: newView,
      clearFocusedBody: newView == ViewLevel.galaxy,
    );
  }

  void setZoomLevel(double zoom) {
    state = state.copyWith(zoomLevel: zoom);
  }

  void enterSurface(String planetId) {
    state = state.copyWith(
      focusedBodyId: planetId,
      currentView: ViewLevel.surface,
    );
  }

  void exitSurface() {
    state = state.copyWith(currentView: ViewLevel.planet);
  }
}

final navigationProvider =
    StateNotifierProvider<NavigationNotifier, NavigationState>(
  (ref) => NavigationNotifier(),
);
