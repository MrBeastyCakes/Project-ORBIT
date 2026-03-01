# Project ORBIT -- MVP Implementation Plan

**Created:** 2026-03-01
**Status:** Draft
**Architecture:** Clean Architecture (domain/data/presentation) with Riverpod + Flame
**Target Platforms:** Android, iOS
**Performance Budget:** 500 notes rendering smoothly

---

## Clean Architecture Directory Structure

```
lib/
  main.dart                          # App entry, ProviderScope, router setup
  app.dart                           # MaterialApp / GameWidget bootstrap

  core/
    constants/
      orbit_constants.dart           # Physics constants, max notes, tier limits
      theme_constants.dart           # Dark theme colors, text styles
      animation_constants.dart       # Durations, curves for transitions
    errors/
      failures.dart                  # Failure sealed class hierarchy
      exceptions.dart                # Cache/server exception types
    usecases/
      usecase.dart                   # Abstract UseCase<Type, Params> base
    extensions/
      vector2_extensions.dart        # Flame Vector2 helpers
      color_extensions.dart          # Atmosphere color utilities
    utils/
      id_generator.dart              # UUID generation wrapper
      debouncer.dart                 # Input debouncing for search/editor

  domain/
    entities/
      galaxy.dart                    # Galaxy aggregate root
      black_hole.dart                # Top-level category entity
      star.dart                      # Sub-category entity
      planet.dart                    # Note entity (content, metadata, visual state)
      moon.dart                      # Sub-task entity
      asteroid.dart                  # Quick-capture fragment
      wormhole.dart                  # Navigation shortcut link
      constellation_link.dart        # Backlink between two bodies
      celestial_body.dart            # Abstract base: id, position, mass, parentId, orbitRadius, color
      note_content.dart              # Rich text document model (Delta or similar)
      user_profile.dart              # Auth user, tier (free/paid)
    repositories/
      celestial_body_repository.dart # Abstract: CRUD for all body types
      note_content_repository.dart   # Abstract: read/write rich text
      user_repository.dart           # Abstract: auth state, profile, tier
      search_repository.dart         # Abstract: full-text search index
    usecases/
      # Black Hole
      create_black_hole.dart
      delete_black_hole.dart
      get_all_black_holes.dart
      # Star
      create_star.dart
      delete_star.dart
      get_stars_for_black_hole.dart
      # Planet
      create_planet.dart
      delete_planet.dart
      get_planets_for_star.dart
      update_planet_content.dart
      # Moon
      add_moon.dart
      toggle_moon_completed.dart
      get_moons_for_planet.dart
      # Asteroid
      create_asteroid.dart
      accrete_asteroid.dart          # Merge asteroid into planet or promote to planet
      get_all_asteroids.dart
      # Navigation
      create_wormhole.dart
      delete_wormhole.dart
      get_wormholes.dart
      create_constellation_link.dart
      get_constellation_links.dart
      # Search
      search_notes.dart              # Full-text search across all note content
      # Drag/reorganize
      reparent_body.dart             # Move planet to different star, star to different black hole
      # Auth
      sign_in_with_google.dart
      sign_out.dart
      get_current_user.dart
      # Tier gating
      check_black_hole_limit.dart

  data/
    models/
      black_hole_model.dart          # Hive/Isar serialization for BlackHole
      star_model.dart
      planet_model.dart
      moon_model.dart
      asteroid_model.dart
      wormhole_model.dart
      constellation_link_model.dart
      note_content_model.dart
      user_profile_model.dart
    datasources/
      local_celestial_datasource.dart    # Isar DB operations for celestial bodies
      local_note_content_datasource.dart # Isar DB for rich text documents
      local_search_datasource.dart       # Isar full-text index queries
      local_user_datasource.dart         # Isar for cached user profile
      firebase_auth_datasource.dart      # Google Auth via Firebase Auth
    repositories/
      celestial_body_repository_impl.dart
      note_content_repository_impl.dart
      user_repository_impl.dart
      search_repository_impl.dart

  presentation/
    game/
      orbit_game.dart                # FlameGame subclass: the root game world
      components/
        galaxy_component.dart        # Top-level container, manages all systems
        black_hole_component.dart    # Renders black hole with accretion disk visual
        star_component.dart          # Renders star with glow/pulse
        planet_component.dart        # Renders planet with atmosphere, size variation
        moon_component.dart          # Small orbiting body for sub-tasks
        asteroid_component.dart      # Small fragment at galaxy edge
        wormhole_component.dart      # Portal visual with entry/exit animation
        constellation_line.dart      # Glowing line between linked bodies
        orbit_path_component.dart    # Circular orbit trail renderer
        nebula_component.dart        # Post-supernova deletion remnant
      systems/
        orbit_system.dart            # Updates orbital positions each tick
        camera_system.dart           # Handles pan, pinch-zoom, zoom-to-body
        drag_system.dart             # Drag-to-reorganize + accretion detection
        collision_system.dart        # Detects asteroid-planet collisions for accretion
        visual_state_system.dart     # Updates protostar/gas-giant/dwarf-planet visuals
        tidal_lock_system.dart       # Moves locked pairs together
      effects/
        supernova_effect.dart        # Explosion particle effect on deletion
        wormhole_warp_effect.dart    # Camera warp transition
        accretion_effect.dart        # Asteroid merge animation
        glow_effect.dart             # Pulsing glow for protostars, search highlights

    providers/
      game_provider.dart             # Provides OrbitGame instance
      galaxy_provider.dart           # StateNotifier: all celestial bodies
      navigation_provider.dart       # Current zoom level, focused body
      editor_provider.dart           # Current note content being edited
      search_provider.dart           # Search query, results, telescope mode
      auth_provider.dart             # Auth state, user profile
      tier_provider.dart             # Free/paid, black hole count check
      asteroid_provider.dart         # Quick-capture state

    screens/
      galaxy_screen.dart             # Main screen: GameWidget + overlay buttons
      surface_screen.dart            # Rich text editor (Planet Surface)
      telescope_screen.dart          # Search overlay with darkened background
      auth_screen.dart               # Google sign-in screen
      settings_screen.dart           # Planet color customization, account info

    widgets/
      context_menu.dart              # Radial/popup menu on body tap
      formatting_toolbar.dart        # Rich text formatting bar on Surface
      quick_capture_fab.dart         # Floating action button for asteroid creation
      zoom_indicator.dart            # Shows current hierarchy level
      black_hole_limit_banner.dart   # Free tier limit warning

    router/
      app_router.dart                # GoRouter or auto_route configuration

test/
  domain/usecases/                   # Unit tests for each use case
  data/repositories/                 # Unit tests for repository impls with mocked datasources
  data/datasources/                  # Integration tests for Isar operations
  presentation/providers/            # Unit tests for Riverpod providers
  presentation/game/systems/         # Unit tests for physics/orbit systems
  integration/                       # End-to-end flow tests
  widget/                            # Widget tests for screens and overlays
```

---

## Phase 1: Project Scaffold and Flame Canvas

**Goal:** A running Flutter app with Flame engine rendering an infinite pannable, zoomable dark canvas with a single static circle (placeholder Black Hole). Clean Architecture directories exist. Riverpod is wired.

### Deliverables

1. **Flutter project initialization** via `flutter create --org com.orbit project_orbit` with Android + iOS targets.
2. **Dependency installation:** Add `flame`, `flutter_riverpod`, `riverpod_annotation`, `go_router`, `isar`, `isar_flutter_libs`, `isar_generator`, `build_runner`, `google_fonts`, `uuid` to `pubspec.yaml`.
3. **Directory scaffold:** Create every directory in the structure above (empty files with TODO markers are fine for directories not yet populated).
4. **`main.dart`:** Wraps the app in `ProviderScope`. Initializes Isar DB asynchronously before `runApp`.
5. **`app.dart`:** `MaterialApp.router` with dark `ThemeData` (pure black background, white/grey text, accent colors for celestial bodies). Uses `GoRouter`.
6. **`orbit_game.dart`:** A `FlameGame` subclass with:
   - `CameraComponent` with unbounded world (no fixed boundaries).
   - Pan gesture via `PanDetector` mixin: translates camera position.
   - Pinch-to-zoom via `ScaleDetector`: scales camera zoom between 0.05 (galaxy view) and 5.0 (surface approach).
   - Dark background (`Color(0xFF0A0A1A)`).
7. **`galaxy_screen.dart`:** A `StatelessWidget` that renders `GameWidget(game: ref.watch(gameProvider))` filling the screen.
8. **`game_provider.dart`:** A `Provider<OrbitGame>` that creates and holds the game instance.
9. **One static test body:** A `CircleComponent` with radius 40, white fill, positioned at `Vector2(0, 0)` added to the game world on load. This proves rendering works.
10. **`orbit_constants.dart`:** Physics constants stub: `minZoom = 0.05`, `maxZoom = 5.0`, `defaultOrbitSpeed = 0.5`, `maxNotes = 500`, `freeBlackHoleLimit = 2`.
11. **`celestial_body.dart` (domain entity):** Abstract class with fields: `id` (String), `name` (String), `position` (x, y doubles), `mass` (double), `parentId` (String?), `orbitRadius` (double), `color` (int, ARGB).

### Acceptance Criteria

- [ ] `flutter run` launches on Android emulator or iOS simulator without errors.
- [ ] A dark screen appears with a white circle at center.
- [ ] Dragging with one finger pans the camera (circle moves relative to viewport).
- [ ] Pinch gesture zooms in/out. Zoom stops at min (0.05) and max (5.0) bounds.
- [ ] `flutter analyze` returns zero issues.
- [ ] All directories from the structure above exist in `lib/`.

### Dependencies
- None (first phase).

---

## Phase 2: Domain Entities, Isar Persistence, and CRUD

**Goal:** Full domain entity model stored in Isar. Can create, read, update, and delete Black Holes, Stars, and Planets through use cases. Data survives app restart.

### Deliverables

1. **Domain entities (complete):**
   - `BlackHole`: extends `CelestialBody`. Fields: `id`, `name`, `position`, `mass`, `color`, `createdAt`, `updatedAt`.
   - `Star`: extends `CelestialBody`. Additional: `parentBlackHoleId`, `orbitRadius`, `orbitAngle`.
   - `Planet`: extends `CelestialBody`. Additional: `parentStarId`, `orbitRadius`, `orbitAngle`, `wordCount` (int), `lastOpenedAt` (DateTime), `visualState` (enum: `protostar`, `normal`, `gasGiant`, `dwarfPlanet`).
   - `NoteContent`: `id` (matches Planet id), `deltaJson` (String -- Quill Delta JSON), `plainText` (String -- for search indexing), `updatedAt`.
   - `Moon`: `id`, `parentPlanetId`, `label` (String), `isCompleted` (bool), `orbitRadius`, `orbitAngle`.
   - `Asteroid`: `id`, `text` (String, max 280 chars), `position`, `createdAt`.

2. **Isar schemas (data/models/):**
   - `BlackHoleModel`, `StarModel`, `PlanetModel`, `MoonModel`, `AsteroidModel`, `NoteContentModel` each with `@collection` annotation and `toEntity()` / `fromEntity()` mappers.
   - Isar indexes: `PlanetModel` has index on `parentStarId`; `StarModel` on `parentBlackHoleId`; `NoteContentModel` has full-text index on `plainText`.

3. **Local datasource (`local_celestial_datasource.dart`):**
   - Methods: `insertBlackHole`, `getAllBlackHoles`, `deleteBlackHole`, `insertStar`, `getStarsForBlackHole`, `deleteStar`, `insertPlanet`, `getPlanetsForStar`, `deletePlanet`, `updatePlanet`.
   - Each method operates on Isar via the injected `Isar` instance.

4. **Repository implementation (`celestial_body_repository_impl.dart`):**
   - Implements `CelestialBodyRepository` (domain interface).
   - Wraps datasource calls, maps models to entities, returns `Either<Failure, T>` (or throws domain `Failure` -- choose one pattern and stick to it project-wide, recommend sealed Failure classes with pattern matching).

5. **Use cases (domain/usecases/):**
   - `CreateBlackHole`: validates name non-empty, checks free-tier limit (max 2), calls repository.
   - `GetAllBlackHoles`: returns `List<BlackHole>`.
   - `DeleteBlackHole`: cascades delete to child Stars, their Planets, and their NoteContents.
   - `CreateStar`: validates parent Black Hole exists, assigns default orbit radius.
   - `GetStarsForBlackHole`: returns `List<Star>` for a given Black Hole id.
   - `DeleteStar`: cascades to child Planets.
   - `CreatePlanet`: validates parent Star exists, creates empty `NoteContent`, sets `visualState = protostar`.
   - `GetPlanetsForStar`: returns `List<Planet>`.
   - `DeletePlanet`: deletes Planet and its NoteContent.

6. **Riverpod providers:**
   - `isarProvider`: `FutureProvider<Isar>` that opens the database.
   - `celestialBodyRepositoryProvider`: provides the repository impl with Isar injected.
   - `galaxyProvider`: `AsyncNotifierProvider` that loads all Black Holes, Stars, Planets into a `GalaxyState` record. Exposes methods: `addBlackHole`, `addStar`, `addPlanet`, `deleteBlackHole`, etc.

### Acceptance Criteria

- [ ] Unit test: `CreateBlackHole` use case creates a Black Hole and `GetAllBlackHoles` returns it.
- [ ] Unit test: `CreateBlackHole` returns a `Failure` when called with 2 existing Black Holes on free tier.
- [ ] Unit test: `DeleteBlackHole` cascades -- deleting a Black Hole also deletes its Stars and their Planets.
- [ ] Integration test: Create a Black Hole, restart the app (re-open Isar), confirm the Black Hole persists.
- [ ] Unit test: `CreatePlanet` sets `visualState` to `protostar`.
- [ ] All entity fields serialize to Isar and deserialize back without data loss.
- [ ] `flutter analyze` returns zero issues.
- [ ] `flutter test` passes all new tests.

### Dependencies
- Phase 1 (project scaffold, Isar dependency, directory structure).

---

## Phase 3: Celestial Body Rendering and Orbital Physics

**Goal:** Black Holes, Stars, and Planets render as distinct visual components in Flame. Bodies orbit their parents in simplified circular motion. The galaxy is alive and moving.

### Deliverables

1. **`black_hole_component.dart`:**
   - Renders as a dark circle (radius 50-60) with a glowing purple/blue accretion disk ring drawn via `Canvas.drawArc`.
   - Positioned at its entity's `(x, y)` in world space.
   - Receives taps (mixin `TapCallbacks`).

2. **`star_component.dart`:**
   - Renders as a bright yellow/white circle (radius 25-35) with a soft radial gradient glow.
   - Opacity pulses subtly using a sine wave in `update()`.
   - Positioned relative to parent Black Hole based on `orbitRadius` and `orbitAngle`.

3. **`planet_component.dart`:**
   - Renders as a colored circle (radius 12-20 based on `wordCount`).
   - Color from entity's `color` field. Atmosphere rendered as a larger semi-transparent circle behind the body.
   - Size formula: `baseRadius + (wordCount / 500).clamp(0, 1) * 8`. Base radius 12, max 20.
   - Visual state rendering:
     - `protostar`: pulsing glow effect, slightly transparent.
     - `gasGiant`: larger radius multiplier (1.4x), banded texture via horizontal gradient lines.
     - `dwarfPlanet`: desaturated color, smaller radius multiplier (0.8x).
     - `normal`: solid fill with atmosphere.

4. **`orbit_path_component.dart`:**
   - Draws a faint dashed circle at the orbit radius around the parent body.
   - Color: `Colors.white.withOpacity(0.08)`.

5. **`orbit_system.dart` (simplified circular orbit):**
   - On each `update(dt)`, for every orbiting body:
     ```
     angle += orbitSpeed * dt
     x = parent.x + orbitRadius * cos(angle)
     y = parent.y + orbitRadius * sin(angle)
     ```
   - `orbitSpeed` is inversely proportional to `orbitRadius` (inner orbits are faster): `orbitSpeed = baseSpeed / sqrt(orbitRadius / referenceRadius)`.
   - Operates on all Stars (orbiting Black Holes) and all Planets (orbiting Stars).

6. **`galaxy_component.dart`:**
   - On game load, reads all entities from `galaxyProvider` and spawns corresponding Flame components.
   - Listens to provider changes to add/remove components when entities change.
   - Black Holes are spaced apart by a minimum distance (e.g., 400 world units). Positions assigned on creation if not already set.

7. **`camera_system.dart` (enhanced):**
   - Smooth animated zoom-to-body: when a body is selected, camera animates (`MoveEffect` + `ScaleEffect`) to center on it at an appropriate zoom level.
   - Zoom level thresholds determine what is visible:
     - Zoom < 0.15: only Black Holes and their labels visible. Stars and Planets are dots or hidden.
     - Zoom 0.15-0.6: Black Holes + Stars visible with orbit paths. Planets are small dots.
     - Zoom 0.6-2.0: Stars + Planets visible with atmospheres and moons.
     - Zoom > 2.0: approaching Surface -- planet fills screen.

8. **Bridge: Provider to Flame sync.**
   - `galaxyProvider` holds the domain state. When it updates, `galaxy_component.dart` diffs the entity list and adds/removes Flame components accordingly.
   - Flame components read position from the orbit system each tick (the orbit system writes directly to the component positions, not back to the domain entity -- entity positions are persisted only on explicit save or app background).

### Acceptance Criteria

- [ ] App launches and displays at least one Black Hole with a visible accretion disk effect.
- [ ] Creating a Star (via provider) causes a glowing orb to appear orbiting the Black Hole.
- [ ] Creating a Planet causes a colored circle to appear orbiting the Star.
- [ ] All orbiting bodies move smoothly in circular paths. Inner orbits complete faster than outer orbits.
- [ ] Orbit path lines are visible as faint dashed circles.
- [ ] Zooming out far enough hides Planets and shows only Black Holes. Zooming in reveals Stars, then Planets.
- [ ] Tapping a Black Hole triggers a callback (logged to console for now).
- [ ] Unit test: `orbit_system` correctly computes position after N ticks for known inputs.
- [ ] Performance: 50 bodies (2 BH, 10 Stars, 38 Planets) renders at 60fps on a mid-range Android device.
- [ ] `flutter analyze` clean.

### Dependencies
- Phase 2 (entities and persistence -- components need entity data).

---

## Phase 4: Full Vertical Slice -- Create, Navigate, Edit, Save

**Goal:** A user can create a Black Hole, create a Star inside it, create a Planet, zoom into the Planet to reach the Surface editor, type rich text, save, zoom back out, and see their planet orbiting. This is the end-to-end proof of concept.

### Deliverables

1. **Context menu (`context_menu.dart`):**
   - On tap of empty space in galaxy view (zoom < 0.15): shows "New Black Hole" option.
   - On tap of a Black Hole: shows "New Star", "Delete", "Rename".
   - On tap of a Star: shows "New Planet", "Delete", "Rename".
   - On tap of a Planet: shows "Open", "Delete", "Rename", "Change Color".
   - Implemented as a `PositionedOverlay` widget rendered above the `GameWidget` at the tap world-position projected to screen coordinates.

2. **Zoom-to-surface navigation flow:**
   - Tap a Planet -> context menu -> "Open" (or double-tap).
   - Camera animates to zoom level 3.0+ centered on the Planet.
   - At zoom > 2.5, a route transition pushes `SurfaceScreen` over the game. The transition is a fade/scale that makes it feel like "landing on the surface."
   - `navigation_provider.dart` tracks: `currentZoomLevel`, `focusedBodyId`, `isOnSurface` (bool).

3. **`surface_screen.dart` (rich text editor):**
   - Uses `flutter_quill` package for rich text editing.
   - Loads `NoteContent.deltaJson` for the focused Planet's id via `editorProvider`.
   - **Formatting toolbar (`formatting_toolbar.dart`):** Bold, Italic, Underline, Strikethrough, Heading 1/2/3, Bullet list, Numbered list, Checkbox, Quote block, Code block, Undo, Redo. Rendered as a slim bottom bar with icon buttons.
   - Auto-saves content to Isar after 2 seconds of inactivity (debounced). Updates `Planet.wordCount` and `NoteContent.plainText` on each save.
   - Back navigation (swipe down or back button) triggers save, then pops to game view. Camera zooms back out to star-system level.

4. **`editor_provider.dart`:**
   - `AsyncNotifierProvider` that loads/saves `NoteContent` for a given Planet id.
   - Exposes: `loadContent(planetId)`, `saveContent()`, `updateDelta(delta)`.
   - On save, also updates the `Planet.wordCount` and `Planet.visualState` (protostar -> normal once wordCount > 0; normal -> gasGiant once wordCount > 2000).

5. **`note_content_repository_impl.dart` and `local_note_content_datasource.dart`:**
   - `getContent(planetId)`: returns `NoteContent` or null.
   - `saveContent(noteContent)`: upserts to Isar.
   - `deleteContent(planetId)`: removes from Isar.

6. **Create flows wired end-to-end:**
   - "New Black Hole" -> name dialog -> `galaxyProvider.addBlackHole(name)` -> Flame component appears.
   - "New Star" -> name dialog -> `galaxyProvider.addStar(name, parentBlackHoleId)` -> orbiting star appears.
   - "New Planet" -> name dialog -> `galaxyProvider.addPlanet(name, parentStarId)` -> orbiting protostar planet appears.
   - "Delete" on any body -> confirmation dialog -> `galaxyProvider.deleteX(id)` -> supernova placeholder (just remove for now, animation in Phase 8).

7. **Rename flow:** Tap body -> "Rename" -> inline text field -> updates entity name in Isar.

8. **`add flutter_quill` to `pubspec.yaml`:** `flutter_quill: ^10.x` (latest stable).

### Acceptance Criteria

- [ ] User can long-press empty space -> "New Black Hole" -> type name -> black hole appears.
- [ ] User can tap Black Hole -> "New Star" -> type name -> star appears orbiting.
- [ ] User can tap Star -> "New Planet" -> type name -> protostar planet appears orbiting.
- [ ] User can tap Planet -> "Open" -> camera zooms in -> Surface editor appears.
- [ ] User can type text with Bold, Italic, Heading, and Bullet List formatting.
- [ ] User can swipe back -> text is saved -> camera zooms out -> planet is visible orbiting.
- [ ] Killing the app and reopening: all created bodies and note text persist.
- [ ] Creating a note with 0 words shows protostar visual. Writing 1+ word changes to normal on next open.
- [ ] Delete a body -> it disappears from the canvas and from Isar.
- [ ] `flutter test` covers: create flow, save/load content round-trip, delete cascade, visual state transitions.

### Dependencies
- Phase 3 (rendering and orbit physics).

---

## Phase 5: Google Auth and Tier Gating

**Goal:** Users sign in with Google. Free tier enforced (max 2 Black Holes). Paid tier placeholder. Auth state persists.

### Deliverables

1. **Firebase project setup:**
   - Add `firebase_core`, `firebase_auth`, `google_sign_in` to `pubspec.yaml`.
   - `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) configured.
   - Firebase initialized in `main.dart` before Isar.

2. **`firebase_auth_datasource.dart`:**
   - `signInWithGoogle()`: triggers Google Sign-In flow, returns Firebase `User`.
   - `signOut()`: signs out of both Google and Firebase.
   - `getCurrentUser()`: returns current `User?` from `FirebaseAuth.instance.currentUser`.
   - `authStateChanges()`: returns `Stream<User?>`.

3. **`user_repository_impl.dart`:**
   - Wraps Firebase auth datasource.
   - Maps Firebase `User` to domain `UserProfile` entity.
   - Caches `UserProfile` in Isar for offline access.
   - Determines tier: default `free`. (Paid tier check is a stub that always returns `free` for now -- will integrate payment provider later.)

4. **`auth_provider.dart`:**
   - `StreamNotifierProvider` that listens to `authStateChanges()`.
   - Exposes: `signIn()`, `signOut()`, `currentUser` (UserProfile?), `isAuthenticated` (bool).

5. **`tier_provider.dart`:**
   - Reads `currentUser.tier` from `auth_provider`.
   - `canCreateBlackHole`: returns false if tier is `free` and Black Hole count >= 2.
   - `isPaid`: bool.

6. **`auth_screen.dart`:**
   - Centered ORBIT logo (placeholder text for now), "Sign in with Google" button.
   - On success, navigates to `galaxy_screen`.
   - If user is already authenticated (cached), skips to galaxy.

7. **Router guard:**
   - `app_router.dart` redirects unauthenticated users to `auth_screen`.
   - Authenticated users go directly to `galaxy_screen`.

8. **Free-tier enforcement in UI:**
   - `CreateBlackHole` use case returns `BlackHoleLimitReached` failure when limit hit.
   - `context_menu.dart`: "New Black Hole" option is greyed out with "(2/2 -- Upgrade)" label when limit reached.
   - `black_hole_limit_banner.dart`: a dismissible banner shown at top when user hits the limit.

9. **`local_user_datasource.dart`:**
   - Caches `UserProfileModel` in Isar for offline auth state.

### Acceptance Criteria

- [ ] App opens to sign-in screen on first launch.
- [ ] Tapping "Sign in with Google" triggers native Google sign-in.
- [ ] After signing in, user reaches the galaxy.
- [ ] Killing and reopening the app: user is still signed in (no re-auth needed).
- [ ] Signing out returns to auth screen.
- [ ] With 2 Black Holes created, attempting to create a third shows limit banner and context menu shows greyed-out option.
- [ ] Unit test: `CheckBlackHoleLimit` returns failure for free tier at 2 Black Holes, success for paid tier.
- [ ] `flutter analyze` clean.

### Dependencies
- Phase 4 (create flow must exist before gating it).

---

## Phase 6: Telescope View (Full-Text Search)

**Goal:** User activates search mode. Screen darkens. As they type, only planets matching the query illuminate. Tapping a result navigates to that planet.

### Deliverables

1. **`search_repository_impl.dart` and `local_search_datasource.dart`:**
   - `search(query)`: performs Isar full-text search on `NoteContentModel.plainText` and `PlanetModel.name`. Returns `List<Planet>` with matching planet ids.
   - Uses Isar's `.where().plainTextContains(query)` or `.filter().plainTextContains(query, caseSensitive: false)`.

2. **`search_notes.dart` (use case):**
   - Takes a query string, returns `List<Planet>` matching results.
   - Debounced: caller debounces input, use case executes immediately.

3. **`search_provider.dart`:**
   - `StateNotifierProvider` with state: `query` (String), `results` (List<Planet>), `isTelescopeActive` (bool).
   - `activateTelescope()`: sets `isTelescopeActive = true`.
   - `deactivateTelescope()`: clears query and results, sets `isTelescopeActive = false`.
   - `updateQuery(query)`: debounces 300ms, then calls `SearchNotes` use case, updates results.

4. **`telescope_screen.dart` (overlay):**
   - Rendered as a semi-transparent dark overlay (`Colors.black.withOpacity(0.85)`) on top of the game.
   - Search text field at the top with a "telescope" icon and clear button.
   - Results listed below as planet name + snippet of matching text (first 80 chars around the match).
   - Tapping a result: closes telescope, camera animates to that planet, optionally opens Surface.

5. **Flame integration -- highlight matching planets:**
   - When `isTelescopeActive` is true and results exist:
     - All non-matching components have their opacity set to 0.1.
     - Matching planet components get a bright glow effect (`glow_effect.dart`): pulsing white ring.
   - `galaxy_component.dart` listens to `search_provider` and applies/removes glow.

6. **Activation trigger:**
   - A small telescope icon button at the top-right of `galaxy_screen.dart`.
   - Also activatable via a pull-down gesture from the top of the screen.

### Acceptance Criteria

- [ ] Tapping the telescope icon darkens the screen and shows the search field.
- [ ] Typing a query that matches a planet's content highlights that planet on the canvas.
- [ ] Non-matching planets become dim (nearly invisible).
- [ ] Search results list shows planet name and content snippet.
- [ ] Tapping a result dismisses telescope and navigates camera to that planet.
- [ ] Searching for text that appears in note body (not just title) returns results.
- [ ] Empty query shows no results and all planets are dimmed.
- [ ] Dismissing telescope (X button or back gesture) restores all planet visibility.
- [ ] Unit test: `SearchNotes` use case returns correct planets for known content.
- [ ] Performance: search returns results within 200ms for 500 notes.

### Dependencies
- Phase 4 (planets with content must exist to search).

---

## Phase 7: Asteroids, Quick Capture, and Accretion

**Goal:** Users can quickly capture thoughts as asteroids (fragments). Asteroids float at the galaxy edge. Dragging an asteroid onto a planet merges the text. Dragging to a star orbit promotes it to a new planet.

### Deliverables

1. **`asteroid.dart` entity (already defined in Phase 2) -- ensure completeness:**
   - `id`, `text` (max 280 chars), `position` (galaxy edge), `createdAt`.

2. **`asteroid_component.dart`:**
   - Small irregular shape (or small circle, radius 4-6) with a rocky grey/brown color.
   - Positioned along the outer edge of the galaxy (orbit radius = largest Black Hole orbit + 300).
   - Drifts slowly in a loose orbit around the galaxy center.

3. **`quick_capture_fab.dart`:**
   - Floating action button (small "+" icon) always visible in bottom-right of `galaxy_screen.dart`.
   - Tap opens a compact text field overlay (max 280 chars) with a "Launch" button.
   - On submit: calls `CreateAsteroid` use case -> asteroid appears at galaxy edge with a brief "shooting star" entrance animation.

4. **`create_asteroid.dart` and `get_all_asteroids.dart` use cases.**

5. **`accrete_asteroid.dart` use case:**
   - **Merge mode (asteroid dragged onto existing planet):** Appends asteroid text to the planet's `NoteContent` as a new paragraph. Deletes the asteroid. Triggers `accretion_effect`.
   - **Promote mode (asteroid dragged onto a star's orbit zone):** Creates a new Planet under that Star with the asteroid text as initial content. Deletes the asteroid.

6. **`drag_system.dart` (enhanced for accretion):**
   - Detects when a dragged asteroid overlaps a planet component -> triggers merge.
   - Detects when a dragged asteroid is released near a star (within orbit zone) -> triggers promote.
   - Visual feedback during drag: target planet/star glows when asteroid is hovering over it.

7. **`accretion_effect.dart`:**
   - Brief particle burst when asteroid merges with a planet.
   - Planet briefly flashes brighter.

8. **`asteroid_provider.dart`:**
   - Manages asteroid CRUD in state.
   - Exposes: `addAsteroid(text)`, `accreteInto(asteroidId, planetId)`, `promoteToplanet(asteroidId, starId)`, `getAllAsteroids()`.

### Acceptance Criteria

- [ ] Tapping the FAB opens a quick text entry.
- [ ] Submitting text creates an asteroid visible at the galaxy edge.
- [ ] Asteroids drift slowly in a loose orbit at the outer edge.
- [ ] Dragging an asteroid onto a planet: asteroid disappears, planet's note content now contains the asteroid text at the end.
- [ ] Dragging an asteroid near a star: asteroid becomes a new planet orbiting that star with the asteroid text as content.
- [ ] Accretion shows a brief particle/flash effect.
- [ ] Asteroids persist across app restarts.
- [ ] Unit test: `AccreteAsteroid` merge mode appends text correctly.
- [ ] Unit test: `AccreteAsteroid` promote mode creates planet with correct content and parent.

### Dependencies
- Phase 4 (create and edit flow must work).
- Phase 3 (drag system foundation).

---

## Phase 8: Visual Metadata and Lifecycle

**Goal:** Planets visually communicate their state. Moons orbit planets as sub-tasks. Supernova deletion with nebula remnants. Atmosphere colors represent tags.

### Deliverables

1. **Visual state system (`visual_state_system.dart`):**
   - On each entity update, recalculates `visualState`:
     - `protostar`: wordCount == 0.
     - `normal`: wordCount 1-2000.
     - `gasGiant`: wordCount > 2000.
     - `dwarfPlanet`: `lastOpenedAt` older than 90 days.
   - `planet_component.dart` reads `visualState` and applies the correct rendering (already stubbed in Phase 3, now fully implemented).

2. **Moon components (`moon_component.dart`):**
   - Small circles (radius 3-4) orbiting a planet at close range.
   - Completed moons: grey/faded. Incomplete moons: bright white.
   - Tap a moon to toggle completion. Completed moon plays a "landing" animation (shrinks and merges into planet surface, then the moon visually sits on the planet).

3. **Moon use cases:** `AddMoon`, `ToggleMoonCompleted`, `GetMoonsForPlanet`.

4. **Moon UI:**
   - In planet context menu: "Add Sub-task" option.
   - Prompts for a label -> creates Moon orbiting the planet.
   - Sub-tasks are also visible in `surface_screen.dart` as a checklist section above the editor.

5. **Atmosphere rendering (planet_component.dart enhancement):**
   - `Planet.color` determines the atmosphere color.
   - Rendered as a radial gradient circle behind the planet body, 1.6x the planet radius, fading from the color at 30% opacity to transparent.
   - Color picker accessible from planet context menu -> "Change Color" -> shows palette of 12 preset colors + custom color wheel.

6. **Supernova deletion (`supernova_effect.dart`):**
   - When a planet (or star/black hole) is deleted:
     1. Body component plays expansion + flash animation (200ms).
     2. Particle burst: 20-30 small fragments scatter outward (300ms).
     3. Fragments fade. A faint `nebula_component.dart` remains at the position.
   - `NebulComponent`: semi-transparent cloud shape at the deletion site. Stores the deleted body's name. Tapping it shows "Remnant of [name]" tooltip. Nebula data persisted in Isar for searchability.

7. **`nebula_component.dart`:**
   - Faint, low-opacity cloud rendered as overlapping transparent circles.
   - Does not participate in physics/orbits.
   - Removed after 30 days or when user explicitly clears nebula.

### Acceptance Criteria

- [ ] A new planet with 0 words displays as a glowing protostar.
- [ ] Writing 2500 words in a planet causes it to render as a larger gas giant on next view.
- [ ] A planet not opened for 90+ days (simulate by setting `lastOpenedAt` in test) renders as a faded dwarf planet.
- [ ] Adding a Moon via context menu: small orb appears orbiting the planet.
- [ ] Tapping a Moon toggles it between bright (incomplete) and grey (completed).
- [ ] Changing planet color updates the atmosphere glow on the canvas.
- [ ] Deleting a planet plays the supernova explosion animation.
- [ ] After supernova, a faint nebula remains at the position.
- [ ] Tapping the nebula shows the name of the deleted body.
- [ ] Unit test: visual state transitions correctly for all word count / age thresholds.

### Dependencies
- Phase 4 (edit flow for word count updates).
- Phase 3 (rendering infrastructure).

---

## Phase 9: Drag-to-Reorganize Between Tiers

**Goal:** Users can drag a Planet from one Star to another. Users can drag a Star from one Black Hole to another. Physics resumes after drop.

### Deliverables

1. **`drag_system.dart` (reorganize mode):**
   - Long-press on a Planet or Star enters drag mode.
   - During drag, the body detaches from its orbit and follows the finger.
   - Orbit path of the dragged body disappears. A faint "trail" follows the body.
   - Valid drop targets highlight: for a Planet, valid targets are Stars; for a Star, valid targets are Black Holes.
   - Invalid drop (released in empty space): body animates back to its original orbit.

2. **`reparent_body.dart` use case:**
   - `reparentPlanet(planetId, newStarId)`: updates `Planet.parentStarId`, assigns new orbit radius (outermost position of new star's planets + offset), persists.
   - `reparentStar(starId, newBlackHoleId)`: updates `Star.parentBlackHoleId`, assigns new orbit radius, persists.
   - Validates that the target parent exists.

3. **Flame component updates:**
   - After reparent, `galaxy_component.dart` moves the Flame component to the new parent's children list.
   - Orbit system picks up the new parent and orbit radius on next tick.
   - Brief "warp" animation as body transitions to new orbit.

4. **Provider integration:**
   - `galaxyProvider.reparentPlanet(planetId, newStarId)` and `galaxyProvider.reparentStar(starId, newBlackHoleId)`.

### Acceptance Criteria

- [ ] Long-pressing a planet and dragging it to a different star: planet now orbits the new star.
- [ ] Long-pressing a star and dragging it to a different black hole: star now orbits the new black hole.
- [ ] Dropping a planet on empty space: planet returns to its original orbit.
- [ ] Valid drop targets glow/highlight during drag.
- [ ] After reparenting, the body's new orbit is smooth (no teleport glitch).
- [ ] Data persists: reparented body stays in new location after app restart.
- [ ] Unit test: `ReparentBody` updates parentId and assigns valid orbit radius.

### Dependencies
- Phase 3 (orbit system, drag system).
- Phase 4 (context menu for initiating drag).

---

## Phase 10: Wormholes, Constellations, and Tidal Locking

**Goal:** Users can create wormhole shortcuts between planets. Backlinks render as constellation lines. Tidally locked pairs move together.

### Deliverables

1. **Wormhole creation flow:**
   - In `surface_screen.dart` (planet editor), a toolbar button "Add Wormhole."
   - Tapping it shows a search/picker (reuses telescope search) to select a destination planet.
   - Creates a `Wormhole` entity: `id`, `sourcePlanetId`, `destinationPlanetId`.
   - On the source planet's surface, a visual wormhole icon appears (swirling portal graphic). On the destination, a reciprocal portal appears.

2. **`wormhole_component.dart`:**
   - Rendered on the galaxy canvas as a small swirling circle near its source planet.
   - On the surface screen, rendered as a tappable portal icon in the editor margin.
   - Tapping a wormhole (on canvas or surface): camera warps to the destination planet with a `wormhole_warp_effect.dart` (zoom-out, fast-pan, zoom-in, ~500ms total).

3. **`create_wormhole.dart`, `delete_wormhole.dart`, `get_wormholes.dart` use cases.**

4. **Constellation links (`constellation_line.dart`):**
   - When a wormhole connects two planets in different star systems, a faint glowing line is drawn between them on the galaxy canvas.
   - At galaxy zoom level (< 0.15), these lines form visible constellations.
   - `create_constellation_link.dart`: automatically created when a wormhole links cross-system bodies. Stores `bodyAId`, `bodyBId`.
   - `get_constellation_links.dart`: returns all links for rendering.

5. **Tidal locking (`tidal_lock_system.dart`):**
   - In planet context menu: "Tidal Lock with..." -> picker to select another planet.
   - Creates a `TidalLock` record (stored as a special `ConstellationLink` with `type: tidalLock`).
   - `tidal_lock_system.dart`: when a tidally locked body is dragged (reparented), the linked body also reparents to maintain proximity. If they are in the same star system, they share an orbit radius and maintain a fixed angular offset.
   - Visual: thick glowing line between tidally locked bodies (distinct from constellation lines).

6. **Wormhole warp effect (`wormhole_warp_effect.dart`):**
   - Camera sequence: current view zooms out slightly (100ms) -> fast pan to destination (200ms) -> zoom in to destination (200ms).
   - Subtle purple tunnel vignette during the pan phase.

### Acceptance Criteria

- [ ] User can create a wormhole from Planet A to Planet B via the editor toolbar.
- [ ] Tapping the wormhole portal on Planet A's surface warps the camera to Planet B.
- [ ] Wormhole portals appear on both source and destination planets.
- [ ] Constellation lines are visible at galaxy zoom level between wormhole-connected planets in different systems.
- [ ] User can tidally lock two planets.
- [ ] Dragging a tidally locked planet also moves its locked partner.
- [ ] Deleting a wormhole removes the constellation line and both portal visuals.
- [ ] All wormholes and tidal locks persist across app restarts.
- [ ] Unit test: `CreateWormhole` creates reciprocal portals. `DeleteWormhole` cleans up both sides.

### Dependencies
- Phase 6 (telescope/search for the wormhole destination picker).
- Phase 9 (drag system for tidal locking interaction).

---

## Phase 11: Planet Color Customization and Settings

**Goal:** Users can customize planet colors. A settings screen shows account info and preferences.

### Deliverables

1. **Color picker (in context menu):**
   - Planet context menu -> "Change Color" -> bottom sheet with:
     - 12 preset colors (red, orange, yellow, green, teal, cyan, blue, indigo, purple, pink, grey, white) displayed as colored circles.
     - "Custom" option that opens a full HSV color wheel picker (use `flutter_colorpicker` package or build a simple one with `GestureDetector` on a gradient).
   - Selected color updates `Planet.color` in Isar and immediately updates the atmosphere on the canvas.

2. **Atmosphere color meanings** (informational, not enforced):
   - Settings screen includes a legend: "Green = Urgent, Blue = Reference, Red = Important, etc."
   - These are suggestions. Users choose whatever colors they want.

3. **`settings_screen.dart`:**
   - Sections:
     - **Account:** Display name, email, sign-out button.
     - **Tier:** Current tier (Free/Paid), Black Hole usage (e.g., "2/2 Black Holes"), upgrade button (placeholder).
     - **Color Legend:** Editable list of color-to-meaning mappings. Stored in Isar as user preferences.
     - **About:** App version, credits.
   - Accessible from a small gear icon in the top-left of `galaxy_screen.dart`.

4. **Persist color preferences:**
   - `UserPreferences` Isar collection: stores color legend mappings, any future preferences.

### Acceptance Criteria

- [ ] Tapping "Change Color" on a planet shows the color picker.
- [ ] Selecting a preset color immediately updates the planet's atmosphere on the canvas.
- [ ] Custom color via HSV picker also applies correctly.
- [ ] Settings screen shows current user email and tier info.
- [ ] Sign-out from settings returns to auth screen.
- [ ] Color legend in settings is viewable.
- [ ] Selected color persists across app restarts.

### Dependencies
- Phase 5 (auth for account info display).
- Phase 3 (atmosphere rendering).

---

## Phase 12: Polish, Performance, and Edge Cases

**Goal:** App handles 500 notes at 60fps. Edge cases are handled. Animations are smooth. Error states are graceful.

### Deliverables

1. **Performance optimization for 500 notes:**
   - **Culling:** `galaxy_component.dart` only adds components to the render tree that are within the camera viewport + a margin. Components outside the viewport are removed from the tree (but kept in memory). Uses `CameraComponent.visibleWorldRect`.
   - **Level-of-detail (LOD):** At low zoom, planets render as single-pixel dots (no atmosphere, no moons). Stars render as small circles. Only at medium zoom do full details render.
   - **Batch rendering:** Orbit paths rendered as a single custom `Canvas` paint call rather than individual components.
   - **Profile and optimize:** Use Flutter DevTools to identify jank. Target: consistent 60fps with 500 bodies (2 BH, ~20 Stars, ~478 Planets).

2. **Error handling:**
   - Isar write failures: show a snackbar "Could not save. Retrying..." with automatic retry (3 attempts).
   - Auth failures: show error on auth screen with retry button.
   - Empty states: Galaxy with no bodies shows a centered "Tap and hold to create your first Black Hole" hint with a subtle animation.

3. **Animation polish:**
   - All camera transitions use `CurvedAnimation` with `Curves.easeInOutCubic`.
   - Body creation: new body fades in with a scale-up animation (0 -> 1 over 300ms).
   - Body deletion: supernova effect from Phase 8 fully polished.
   - Orbit speed: ensure no visible stutter when many bodies are updating.

4. **Edge cases:**
   - Deleting a Black Hole with Stars and Planets: confirmation dialog warns "This will delete X Stars and Y Planets."
   - Deleting a Star with Planets: same cascade warning.
   - Maximum note size enforcement: `NoteContent.deltaJson` size capped at 500KB. Editor shows a warning when approaching 80% of the limit.
   - Extremely long planet names: truncated with ellipsis in context menu and labels.
   - Two-finger pan vs. pinch disambiguation: implement gesture arena priority so two-finger gestures consistently zoom (not pan).

5. **Onboarding hint:**
   - First launch after sign-in: a brief overlay with 3 tips.
     1. "Tap and hold empty space to create a Black Hole."
     2. "Pinch to zoom between Galaxy and Planet views."
     3. "Tap a Planet and choose Open to start writing."
   - Shown once, dismissed on tap. Tracked via `UserPreferences.hasSeenOnboarding`.

6. **App lifecycle:**
   - `WidgetsBindingObserver`: on `AppLifecycleState.paused`, persist all entity positions and unsaved editor content to Isar.
   - On resume, reload positions (in case of crash between pause and save).

### Acceptance Criteria

- [ ] Performance test: create 500 notes programmatically. Pan and zoom through the galaxy at 60fps (measured via Flutter DevTools performance overlay).
- [ ] Culling verified: only visible bodies consume GPU draw calls.
- [ ] Deleting a Black Hole with children shows cascade warning with correct counts.
- [ ] Note content at 500KB limit shows a warning. Content beyond 500KB is prevented.
- [ ] First-time user sees onboarding hints. Second launch does not show them.
- [ ] App backgrounded and restored: no data loss, editor content saved.
- [ ] Empty galaxy shows helpful first-action hint.
- [ ] `flutter analyze` clean.
- [ ] `flutter test` -- all tests pass.
- [ ] No console errors or unhandled exceptions in a 10-minute manual test session.

### Dependencies
- All previous phases (this is the polish pass).

---

## Summary of Key Packages

| Package | Version (approx) | Purpose |
|---|---|---|
| `flame` | ^1.22 | 2D game engine: rendering, game loop, camera |
| `flutter_riverpod` | ^2.6 | State management with dependency injection |
| `riverpod_annotation` | ^2.6 | Code generation for Riverpod providers |
| `isar` | ^3.1 | Local NoSQL database with full-text search |
| `isar_flutter_libs` | ^3.1 | Isar native binaries for Flutter |
| `isar_generator` | ^3.1 | (dev) Code gen for Isar schemas |
| `build_runner` | ^2.4 | (dev) Code generation runner |
| `flutter_quill` | ^10.8 | Rich text editor with Delta format |
| `firebase_core` | ^3.8 | Firebase initialization |
| `firebase_auth` | ^5.3 | Firebase Authentication |
| `google_sign_in` | ^6.2 | Google Sign-In for Firebase Auth |
| `go_router` | ^14.6 | Declarative routing |
| `uuid` | ^4.5 | UUID generation for entity IDs |
| `google_fonts` | ^6.2 | Typography |
| `flutter_colorpicker` | ^1.1 | HSV color picker for planet customization |

---

## Phase Dependency Graph

```
Phase 1 (Scaffold + Canvas)
  |
Phase 2 (Entities + Isar)
  |
Phase 3 (Rendering + Orbits)
  |
Phase 4 (Full Vertical Slice) ----+----+----+
  |                                |    |    |
Phase 5 (Auth + Tiers)       Phase 6  Phase 7  Phase 8
  |                           (Search) (Asteroids) (Visual Meta)
  |                                |    |    |
Phase 9 (Drag Reorganize) --------+----+    |
  |                                         |
Phase 10 (Wormholes + Constellations) -----+
  |
Phase 11 (Colors + Settings)
  |
Phase 12 (Polish + Performance)
```

Phases 5, 6, 7, and 8 can be developed in parallel after Phase 4. Phase 9 depends on the drag system from Phase 3 but can run alongside 5-8. Phase 10 requires Phase 6 (search for wormhole picker) and Phase 9 (drag for tidal locking). Phase 11 requires Phase 5 (auth). Phase 12 is the final pass.

---

## Risk Flags

1. **Flame + Riverpod bridge complexity.** Keeping Flame game state in sync with Riverpod providers is non-trivial. The plan separates domain state (Riverpod) from render state (Flame components) with a one-directional flow: Riverpod -> Flame. Flame never writes back to Riverpod directly; user interactions go through providers which trigger component updates. If this becomes unwieldy, consider a dedicated `GameNotifier` that Flame components read from directly.

2. **Isar deprecation risk.** Isar 3.x is stable but the maintainer has signaled focus on Isar 4 (rewrite). If Isar 4 ships before ORBIT v1, a migration may be needed. Mitigation: the repository pattern isolates Isar behind an interface, so swapping to Isar 4 or another DB (Drift, Hive) requires changing only `data/datasources/` and `data/models/`.

3. **500-note performance.** Flame handles 500 simple sprites easily, but with atmospheres, glow effects, orbit paths, and particle effects, GPU budget may be tight on low-end Android. Mitigation: aggressive culling and LOD in Phase 12. Profile early -- if Phase 3 shows <60fps at 100 bodies, simplify effects before proceeding.

4. **flutter_quill stability.** flutter_quill has frequent breaking changes between major versions. Pin the exact version and test editor save/load thoroughly. The Delta JSON format is the persistence contract -- if flutter_quill changes its Delta format, a migration is needed.

5. **Gesture conflict: pan vs. zoom vs. drag.** Three gesture types compete on the same canvas. Flame's gesture system uses a priority arena but tuning it to feel natural (especially pan-to-drag handoff for reorganizing) will require iteration. Budget extra time in Phase 9.
