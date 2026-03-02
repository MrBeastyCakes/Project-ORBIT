import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/orbit_game.dart';
import '../providers/game_provider.dart';
import '../providers/galaxy_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/search_provider.dart';
import '../providers/tier_provider.dart';
import '../widgets/black_hole_limit_banner.dart';
import '../widgets/color_picker_dialog.dart';
import '../widgets/context_menu.dart';
import '../widgets/quick_capture_fab.dart';
import '../widgets/zoom_indicator.dart';
import 'settings_screen.dart';
import 'surface_screen.dart';
import 'telescope_screen.dart';

class GalaxyScreen extends ConsumerStatefulWidget {
  const GalaxyScreen({super.key});

  @override
  ConsumerState<GalaxyScreen> createState() => _GalaxyScreenState();
}

class _GalaxyScreenState extends ConsumerState<GalaxyScreen> {
  // Context menu state
  bool _showContextMenu = false;
  Offset _contextMenuPosition = Offset.zero;
  String? _tappedBodyId;
  CelestialBodyType? _tappedBodyType;

  // Create black hole dialog
  bool _showCreateDialog = false;

  // Black hole limit banner
  bool _showLimitBanner = false;

  @override
  void initState() {
    super.initState();
    // Load all persisted data on first launch
    Future.microtask(() {
      ref.read(galaxyProvider.notifier).loadAll();
    });
  }

  void _setupGameCallbacks(OrbitGame game) {
    game.onBodyTapped = (id, type, screenPos) {
      if (!mounted) return;
      final bodyType = switch (type) {
        'blackHole' => CelestialBodyType.blackHole,
        'star' => CelestialBodyType.star,
        'planet' => CelestialBodyType.planet,
        'moon' => CelestialBodyType.moon,
        _ => null,
      };
      if (bodyType == null) return;
      setState(() {
        _tappedBodyId = id;
        _tappedBodyType = bodyType;
        _contextMenuPosition = Offset(screenPos.x, screenPos.y);
        _showContextMenu = true;
      });
    };

    game.onReparent = (bodyId, bodyType, newParentId) {
      if (!mounted) return;
      ref.read(galaxyProvider.notifier).reparentBody(bodyId, newParentId);
    };

    game.onOrbitRadiusChanged = (bodyId, bodyType, newRadius) {
      if (!mounted) return;
      ref.read(galaxyProvider.notifier).updateOrbitRadius(
        bodyId, bodyType, newRadius,
      );
    };

    game.onCanvasTapped = (screenPos) {
      if (!mounted) return;
      if (_showContextMenu) {
        setState(() => _showContextMenu = false);
        return;
      }
      // Empty canvas tap -- offer to create a black hole
      setState(() {
        _contextMenuPosition = Offset(screenPos.x, screenPos.y);
        _showCreateDialog = true;
      });
    };
  }

  void _dismissContextMenu() {
    setState(() {
      _showContextMenu = false;
      _tappedBodyId = null;
      _tappedBodyType = null;
    });
  }

  void _dismissCreateDialog() {
    setState(() => _showCreateDialog = false);
  }

  void _handleContextMenuAction(ContextMenuAction action) {
    final bodyId = _tappedBodyId;
    if (bodyId == null) return;
    _dismissContextMenu();

    switch (action) {
      case ContextMenuAction.addStar:
        _showNameDialog('New Star', (name) {
          ref.read(galaxyProvider.notifier).addStar(name, bodyId);
        });
      case ContextMenuAction.addPlanet:
        _showNameDialog('New Planet', (name) {
          ref.read(galaxyProvider.notifier).addPlanet(name, bodyId);
        });
      case ContextMenuAction.open:
        // Save camera state and smoothly zoom into the planet before opening surface.
        final openGame = ref.read(gameProvider);
        openGame.cameraSystem.savePreSurfaceState();
        final planetComp = openGame.galaxyComponent.getPlanet(bodyId);
        if (planetComp != null) {
          openGame.cameraSystem.animateTo(
            targetWorld: planetComp.position,
            targetZoom: 2.5,
          );
        }
        ref.read(navigationProvider.notifier).enterSurface(bodyId);
      case ContextMenuAction.addMoon:
        _showNameDialog('New Moon', (label) {
          ref.read(galaxyProvider.notifier).addMoon(label, bodyId);
        }, confirmLabel: 'Add');
      case ContextMenuAction.createWormhole:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wormhole creation coming soon!')),
        );
      case ContextMenuAction.toggleComplete:
        ref.read(galaxyProvider.notifier).toggleMoonCompleted(bodyId);
      case ContextMenuAction.rename:
        _showRenameDialog(bodyId);
      case ContextMenuAction.changeColor:
        _handleChangeColor(bodyId);
      case ContextMenuAction.delete:
        _handleDelete(bodyId);
    }
  }

  /// Returns the current color of the tapped body, or null if unknown.
  int? _currentBodyColor() {
    final id = _tappedBodyId;
    if (id == null) return null;
    final galaxyState = ref.read(galaxyProvider);
    final bh = galaxyState.blackHoles.where((b) => b.id == id).firstOrNull;
    if (bh != null) return bh.color;
    final star = galaxyState.stars.where((s) => s.id == id).firstOrNull;
    if (star != null) return star.color;
    final planet = galaxyState.planets.where((p) => p.id == id).firstOrNull;
    if (planet != null) return planet.color;
    return null;
  }

  Future<void> _handleChangeColor(String bodyId) async {
    if (!mounted) return;
    final galaxyState = ref.read(galaxyProvider);

    // Determine current color and body type string
    int currentColor;
    String bodyType;
    final bh = galaxyState.blackHoles.where((b) => b.id == bodyId).firstOrNull;
    final star = galaxyState.stars.where((s) => s.id == bodyId).firstOrNull;
    final planet =
        galaxyState.planets.where((p) => p.id == bodyId).firstOrNull;

    if (bh != null) {
      currentColor = bh.color;
      bodyType = 'blackHole';
    } else if (star != null) {
      currentColor = star.color;
      bodyType = 'star';
    } else if (planet != null) {
      currentColor = planet.color;
      bodyType = 'planet';
    } else {
      return;
    }

    final picked = await showColorPickerDialog(
      context,
      currentColor: currentColor,
    );
    if (picked != null && mounted) {
      ref
          .read(galaxyProvider.notifier)
          .updateBodyColor(bodyId, bodyType, picked);
    }
  }

  void _handleDelete(String bodyId) {
    final galaxyState = ref.read(galaxyProvider);
    String title;
    String message;
    VoidCallback onConfirm;

    if (galaxyState.blackHoles.any((bh) => bh.id == bodyId)) {
      title = 'Delete Black Hole';
      message = 'This will delete all stars and planets inside. This cannot be undone.';
      onConfirm = () => ref.read(galaxyProvider.notifier).deleteBlackHole(bodyId);
    } else if (galaxyState.stars.any((s) => s.id == bodyId)) {
      title = 'Delete Star';
      message = 'This will delete all planets inside. This cannot be undone.';
      onConfirm = () => ref.read(galaxyProvider.notifier).deleteStar(bodyId);
    } else if (galaxyState.planets.any((p) => p.id == bodyId)) {
      title = 'Delete Planet';
      message = 'This will delete the planet and all its notes. This cannot be undone.';
      onConfirm = () => ref.read(galaxyProvider.notifier).deletePlanet(bodyId);
    } else if (galaxyState.moons.any((m) => m.id == bodyId)) {
      title = 'Delete Moon';
      message = 'Delete this moon? This cannot be undone.';
      onConfirm = () => ref.read(galaxyProvider.notifier).deleteMoon(bodyId);
    } else {
      return;
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onConfirm();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showNameDialog(
    String title,
    void Function(String) onConfirm, {
    String? initialValue,
    String confirmLabel = 'Create',
  }) {
    final controller = TextEditingController(text: initialValue ?? '');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter name...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              onConfirm(value.trim());
              Navigator.of(ctx).pop();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                onConfirm(name);
                Navigator.of(ctx).pop();
              }
            },
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(String bodyId) {
    final galaxyState = ref.read(galaxyProvider);
    final bh = galaxyState.blackHoles.where((b) => b.id == bodyId).firstOrNull;
    final star = galaxyState.stars.where((s) => s.id == bodyId).firstOrNull;
    final planet = galaxyState.planets.where((p) => p.id == bodyId).firstOrNull;

    if (bh != null) {
      _showNameDialog(
        'Rename Black Hole',
        (newName) => ref.read(galaxyProvider.notifier).renameBlackHole(bodyId, newName),
        initialValue: bh.name,
        confirmLabel: 'Rename',
      );
    } else if (star != null) {
      _showNameDialog(
        'Rename Star',
        (newName) => ref.read(galaxyProvider.notifier).renameStar(bodyId, newName),
        initialValue: star.name,
        confirmLabel: 'Rename',
      );
    } else if (planet != null) {
      _showNameDialog(
        'Rename Planet',
        (newName) => ref.read(galaxyProvider.notifier).renamePlanet(bodyId, newName),
        initialValue: planet.name,
        confirmLabel: 'Rename',
      );
    }
  }

  void _showCreateBlackHoleDialog() {
    _dismissCreateDialog();
    final canCreate = ref.read(canCreateBlackHoleProvider);
    if (!canCreate) {
      setState(() => _showLimitBanner = true);
      return;
    }
    _showNameDialog('New Black Hole', (name) {
      ref.read(galaxyProvider.notifier).addBlackHole(name);
    });
  }

  Future<void> _openTelescope(OrbitGame game) async {
    ref.read(searchProvider.notifier).activateTelescope();

    // Listen for search result changes while telescope is open and update game
    ProviderSubscription<List<String>>? sub;
    sub = ref.listenManual<List<String>>(
      searchProvider.select((s) => s.results.map((h) => h.planetId).toList()),
      (_, matchingIds) {
        game.enterTelescopeMode(matchingIds);
      },
    );

    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        pageBuilder: (_, __, ___) => const TelescopeScreen(),
      ),
    );

    // Telescope closed -- restore normal rendering and cancel subscription
    sub.close();
    game.exitTelescopeMode();
    ref.read(searchProvider.notifier).clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameProvider);
    final navState = ref.watch(navigationProvider);
    final galaxyState = ref.watch(galaxyProvider);

    // Set up game callbacks (idempotent -- just sets the closures)
    _setupGameCallbacks(game);

    // Listen to galaxy state changes and sync to Flame components
    ref.listen<GalaxyState>(galaxyProvider, (prev, next) {
      _syncGalaxyToGame(game, prev, next);
    });

    return Scaffold(
      body: Stack(
        children: [
          // Game canvas fills the entire screen
          Positioned.fill(
            child: GameWidget(game: game),
          ),

          // Loading indicator during initial data load
          if (galaxyState.isLoading)
            Positioned.fill(
              child: Container(
                color: const Color(0xCC0A0A1A),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: Color(0xFF6C63FF),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Loading galaxy...',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Error state display
          if (galaxyState.error != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D1B1B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFF6B6B).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFFF6B6B),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          galaxyState.error!.message,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white54,
                          size: 18,
                        ),
                        onPressed: () {
                          ref.read(galaxyProvider.notifier).clearError();
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Empty state / onboarding -- shown when galaxy has no black holes
          if (!galaxyState.isLoading &&
              galaxyState.error == null &&
              galaxyState.blackHoles.isEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Welcome to ORBIT',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tap + to create your first Black Hole',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Zoom level indicator -- top-left
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: const ZoomIndicator(),
          ),

          // Search / Telescope button -- top-right
          Positioned(
            top: MediaQuery.of(context).padding.top + 4,
            right: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: Colors.white),
                  tooltip: 'Settings',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsScreen(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  tooltip: 'Search notes',
                  onPressed: () => _openTelescope(game),
                ),
              ],
            ),
          ),

          // Quick capture FAB -- bottom-right
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            right: 16,
            child: const QuickCaptureFab(),
          ),

          // Black hole limit banner -- shown when free tier limit is reached
          if (_showLimitBanner)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: BlackHoleLimitBanner(
                onDismiss: () => setState(() => _showLimitBanner = false),
                onUpgrade: () {
                  setState(() => _showLimitBanner = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Upgrade coming soon!')),
                  );
                },
              ),
            ),

          // Create Black Hole FAB -- bottom-left
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 16,
            child: FloatingActionButton.small(
              heroTag: 'createBlackHole',
              onPressed: _showCreateBlackHoleDialog,
              backgroundColor: const Color(0xFF2D1B69),
              foregroundColor: Colors.white,
              tooltip: 'Create Black Hole',
              child: const Icon(Icons.add_circle_outline),
            ),
          ),

          // Context menu overlay
          if (_showContextMenu && _tappedBodyType != null)
            Positioned.fill(
              child: GestureDetector(
                onTap: _dismissContextMenu,
                behavior: HitTestBehavior.opaque,
                child: Stack(
                  children: [
                    _ClampedContextMenu(
                      position: _contextMenuPosition,
                      bodyType: _tappedBodyType!,
                      onAction: _handleContextMenuAction,
                      currentColor: _currentBodyColor(),
                    ),
                  ],
                ),
              ),
            ),

          // Create dialog on empty canvas tap
          if (_showCreateDialog)
            Positioned.fill(
              child: GestureDetector(
                onTap: _dismissCreateDialog,
                behavior: HitTestBehavior.opaque,
                child: Stack(
                  children: [
                    Positioned(
                      left: _contextMenuPosition.dx,
                      top: _contextMenuPosition.dy,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A2E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: InkWell(
                          onTap: _showCreateBlackHoleDialog,
                          borderRadius: BorderRadius.circular(12),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_circle_outline,
                                  size: 18,
                                  color: Colors.white70,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Create Black Hole',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Surface overlay when zoomed into a planet's surface
          if (navState.currentView == ViewLevel.surface &&
              navState.focusedBodyId != null)
            Positioned.fill(
              child: SurfaceScreen(planetId: navState.focusedBodyId!),
            ),
        ],
      ),
    );
  }

  /// Synchronize galaxy state changes to the Flame game's components.
  void _syncGalaxyToGame(
    OrbitGame game,
    GalaxyState? prev,
    GalaxyState next,
  ) {
    final gc = game.galaxyComponent;

    if (prev == null || prev.isLoading && !next.isLoading) {
      // Initial load or reload complete -- full sync
      gc.loadBodies(
        blackHoles: next.blackHoles,
        stars: next.stars,
        planets: next.planets,
        moons: next.moons,
        asteroids: next.asteroids,
      );
      game.frameAllBodies();
      return;
    }

    // Incremental sync: detect additions and removals

    // Black holes
    final prevBhIds = prev.blackHoles.map((bh) => bh.id).toSet();
    final nextBhIds = next.blackHoles.map((bh) => bh.id).toSet();
    for (final bh in next.blackHoles) {
      if (!prevBhIds.contains(bh.id)) gc.addBlackHole(bh);
    }
    for (final id in prevBhIds.difference(nextBhIds)) {
      gc.removeBlackHole(id);
    }

    // Stars
    final prevStarIds = prev.stars.map((s) => s.id).toSet();
    final nextStarIds = next.stars.map((s) => s.id).toSet();
    for (final s in next.stars) {
      if (!prevStarIds.contains(s.id)) gc.addStar(s);
    }
    for (final id in prevStarIds.difference(nextStarIds)) {
      gc.removeStar(id);
    }

    // Planets
    final prevPlanetIds = prev.planets.map((p) => p.id).toSet();
    final nextPlanetIds = next.planets.map((p) => p.id).toSet();
    for (final p in next.planets) {
      if (!prevPlanetIds.contains(p.id)) gc.addPlanet(p);
    }
    for (final id in prevPlanetIds.difference(nextPlanetIds)) {
      gc.removePlanet(id);
    }

    // Moons
    final prevMoonIds = prev.moons.map((m) => m.id).toSet();
    final nextMoonIds = next.moons.map((m) => m.id).toSet();
    for (final m in next.moons) {
      if (!prevMoonIds.contains(m.id)) gc.addMoon(m);
    }
    for (final id in prevMoonIds.difference(nextMoonIds)) {
      gc.removeMoon(id);
    }

    // Asteroids
    final prevAsteroidIds = prev.asteroids.map((a) => a.id).toSet();
    final nextAsteroidIds = next.asteroids.map((a) => a.id).toSet();
    for (final a in next.asteroids) {
      if (!prevAsteroidIds.contains(a.id)) gc.addAsteroid(a);
    }
    for (final id in prevAsteroidIds.difference(nextAsteroidIds)) {
      gc.removeAsteroid(id);
    }
  }
}

/// Positions a [ContextMenu] so it stays within screen bounds.
class _ClampedContextMenu extends StatelessWidget {
  final Offset position;
  final CelestialBodyType bodyType;
  final void Function(ContextMenuAction) onAction;
  final int? currentColor;

  // Estimated max dimensions for the context menu — used for clamping.
  static const double _menuWidth = 200.0;
  static const double _menuHeight = 280.0;

  const _ClampedContextMenu({
    required this.position,
    required this.bodyType,
    required this.onAction,
    this.currentColor,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final clampedLeft = position.dx.clamp(0.0, size.width - _menuWidth);
    final clampedTop = position.dy.clamp(0.0, size.height - _menuHeight);
    return Positioned(
      left: clampedLeft,
      top: clampedTop,
      child: ContextMenu(
        bodyType: bodyType,
        onAction: onAction,
        currentColor: currentColor,
      ),
    );
  }
}
