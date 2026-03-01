import 'package:flame/components.dart';
import 'package:orbit_app/presentation/game/components/constellation_line.dart';
import 'package:orbit_app/presentation/game/components/galaxy_component.dart';

/// A pair of planet IDs that are tidally locked together.
class TidalLockPair {
  final String planetAId;
  final String planetBId;

  /// The fixed world-space offset from A to B at the time of locking.
  Vector2 offset;

  TidalLockPair({
    required this.planetAId,
    required this.planetBId,
    required this.offset,
  });
}

/// Manages tidally locked planet pairs.
///
/// When planet A moves, planet B follows so the fixed [TidalLockPair.offset]
/// between them is preserved.  Also draws a distinct [ConstellationLine] with
/// [ConstellationLineType.tidalLock] between each pair.
///
/// Wire-up:
///   1. Add this component to the game world after [GalaxyComponent].
///   2. Call [addPair] for each locked pair loaded from domain data.
///   3. Call [applyDrag] from UI drag handlers to move locked pairs together.
class TidalLockSystem extends Component {
  final GalaxyComponent galaxy;

  final Map<String, TidalLockPair> _pairs = {};
  final Map<String, ConstellationLine> _lines = {};

  TidalLockSystem({required this.galaxy});

  // ── API ──────────────────────────────────────────────────────────────────────

  /// Register a new tidal lock pair.  Captures the current offset between A
  /// and B from [GalaxyComponent] and adds a visual line.
  Future<void> addPair(String pairId, String planetAId, String planetBId) async {
    if (_pairs.containsKey(pairId)) return;

    final compA = galaxy.getPlanet(planetAId);
    final compB = galaxy.getPlanet(planetBId);

    final posA = compA?.position ?? Vector2.zero();
    final posB = compB?.position ?? Vector2.zero();
    final offset = posB - posA;

    final pair = TidalLockPair(
      planetAId: planetAId,
      planetBId: planetBId,
      offset: offset,
    );
    _pairs[pairId] = pair;

    final line = ConstellationLine(
      startPosition: posA.clone(),
      endPosition: posB.clone(),
      lineType: ConstellationLineType.tidalLock,
    );
    _lines[pairId] = line;
    await galaxy.add(line);
  }

  /// Remove a tidal lock pair and its visual line.
  void removePair(String pairId) {
    _pairs.remove(pairId);
    final line = _lines.remove(pairId);
    line?.removeFromParent();
  }

  /// Move planet A by [delta] and mirror the same delta onto planet B,
  /// preserving the fixed offset.
  ///
  /// Call this from drag handlers when the user repositions a locked planet.
  void applyDrag(String planetId, Vector2 delta) {
    for (final entry in _pairs.entries) {
      final pair = entry.value;
      final bool isA = pair.planetAId == planetId;
      final bool isB = pair.planetBId == planetId;
      if (!isA && !isB) continue;

      // Move the dragged planet.
      final compA = galaxy.getPlanet(pair.planetAId);
      final compB = galaxy.getPlanet(pair.planetBId);

      compA?.position.add(isA ? delta : delta);
      compB?.position.add(isB ? delta : delta);
    }
  }

  // ── Update ───────────────────────────────────────────────────────────────────

  @override
  void update(double dt) {
    super.update(dt);

    for (final entry in _pairs.entries) {
      final pair = entry.value;
      final line = _lines[entry.key];

      final compA = galaxy.getPlanet(pair.planetAId);
      final compB = galaxy.getPlanet(pair.planetBId);

      if (compA == null || compB == null) continue;

      // Enforce the fixed offset: B tracks A.
      compB.position = compA.position + pair.offset;

      // Keep the visual line up-to-date.
      line?.updatePositions(compA.position.clone(), compB.position.clone());
    }
  }

  // ── Accessors ────────────────────────────────────────────────────────────────

  /// Returns all registered lock pairs as a list of [TidalLockPair].
  List<TidalLockPair> get allPairs => List.unmodifiable(_pairs.values);

  /// Returns planet ID pairs as a flat list of (A, B) tuples.
  List<(String, String)> get lockedPlanetPairs =>
      _pairs.values.map((p) => (p.planetAId, p.planetBId)).toList();
}
