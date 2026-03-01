# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Status

Project ORBIT is an **MVP implementation complete** Flutter app. All core features (galaxy canvas, celestial hierarchy, note editing, search, drag-to-reparent, viewport culling, LOD rendering) are implemented and functional.

## What Is Project ORBIT

A spatial, physics-driven note-taking app where notes are celestial bodies on an infinite 2D canvas instead of items in folder hierarchies. Users navigate by panning and pinch-to-zoom through a macro-to-micro hierarchy:

- **Galaxy** (all notes) -> **Black Hole** (top-level category) -> **Star/Sun** (sub-category) -> **Planet** (note) -> **Surface** (text editor)

A lightweight 2D physics engine drives the spatial layout. The UI is intentionally minimal -- no sidebars, no dropdown menus. Context menus appear only when interacting with a celestial body.

## Architecture

Clean Architecture with four layers:

- **Domain** (`lib/domain/`): Entities, repository interfaces, use cases. Pure Dart, no framework dependencies.
- **Data** (`lib/data/`): Hive-backed repository implementations, data models with type adapters, local datasources.
- **Presentation** (`lib/presentation/`): Flutter widgets, Flame game components, Riverpod providers, screens.
- **Core** (`lib/core/`): Constants, error types, utilities, extensions.

State management: **Riverpod** (StateNotifier pattern). Galaxy state, editor state, navigation, search, and tier management each have dedicated providers.

## Tech Stack

- **Frontend**: Flutter -- single codebase for iOS, Android, web, and desktop.
- **Rendering**: Flame (Flutter 2D game engine) -- game loop, orbit simulation, canvas rendering.
- **Local Storage**: Hive (lightweight NoSQL) -- all data persisted locally with typed boxes.
- **Rich Text Editor**: flutter_quill -- Delta-based rich text editing on the planet surface.
- **State Management**: Riverpod -- dependency injection and reactive state.

### Hive Boxes

| Box Name | Type | Purpose |
|---|---|---|
| `blackHoles` | `BlackHoleModel` | Top-level categories |
| `stars` | `StarModel` | Sub-categories |
| `planets` | `PlanetModel` | Notes |
| `moons` | `MoonModel` | Sub-tasks / checkboxes |
| `asteroids` | `AsteroidModel` | Quick capture fragments |
| `noteContents` | `NoteContentModel` | Rich text content (Delta JSON) |
| `wormholes` | `WormholeModel` | Cross-system shortcuts |
| `constellationLinks` | `ConstellationLinkModel` | Backlinks between notes |
| `users` | `UserProfileModel` | User profile |
| `preferences` | `dynamic` | App preferences |

## Build & Development Commands

```bash
# Get dependencies
flutter pub get

# Run on connected device / emulator
flutter run

# Run on specific platform
flutter run -d chrome          # web
flutter run -d macos           # macOS desktop
flutter run -d windows         # Windows desktop

# Run a single test file
flutter test test/path/to_test.dart

# Run all tests
flutter test

# Analyze / lint
flutter analyze

# Build release
flutter build apk              # Android
flutter build ios               # iOS
flutter build web               # Web
```

## Core Metaphor Map

| Concept | Metaphor | Behavior |
|---|---|---|
| Top-level category | Black Hole | Anchors an entire system (e.g., "Work", "Personal") |
| Sub-category | Star / Sun | Orbits a Black Hole |
| Note | Planet | Document orbiting its parent Star |
| Quick capture | Asteroid | Unorganized fragments at the galaxy edge |
| Filing a thought | Accretion | Drag asteroid into a planet or orbit |
| Sub-tasks | Moons | Orbit a planet; "land" on it when completed |
| Tags | Atmosphere color | Visual aura (green = urgent, blue = reference) |
| Backlinks | Constellations | Glowing lines between linked notes |
| Shortcuts | Wormholes | Portals that warp the camera to another system |
| Search | Telescope View | Screen darkens; matching planets illuminate |
| Deletion | Supernova | Explosion animation; leaves searchable nebula |

## Key Design Constraints

- **Physics-first layout**: Gravity and mass determine spatial arrangement.
- **No traditional UI chrome**: No persistent sidebars, toolbars, or folder trees.
- **Navigation is zoom-based**: Pinch-to-zoom is the primary navigation mechanism.
- **Metadata is visual**: Status, tags, and priority are communicated through planetary visual features.
- **Performance budget**: 500 notes at 60fps via viewport culling and level-of-detail rendering.
- **Dark theme only** in v1.

## v1.0 Tier Limits

- **Free tier**: local-only, max 2 Black Holes.
- **Paid tier**: cloud sync, unlimited Black Holes.
