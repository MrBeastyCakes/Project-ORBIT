import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../data/datasources/local_celestial_datasource.dart';
import '../../data/datasources/local_constellation_datasource.dart';
import '../../data/datasources/local_note_content_datasource.dart';
import '../../data/datasources/local_search_datasource.dart';
import '../../data/datasources/local_wormhole_datasource.dart';
import '../../data/models/black_hole_model.dart';
import '../../data/models/star_model.dart';
import '../../data/models/planet_model.dart';
import '../../data/models/moon_model.dart';
import '../../data/models/asteroid_model.dart';
import '../../data/models/note_content_model.dart';
import '../../data/models/wormhole_model.dart';
import '../../data/models/constellation_link_model.dart';
import '../../data/repositories/celestial_body_repository_impl.dart';
import '../../data/repositories/constellation_repository_impl.dart';
import '../../data/repositories/note_content_repository_impl.dart';
import '../../data/repositories/search_repository_impl.dart';
import '../../data/repositories/wormhole_repository_impl.dart';
import '../../domain/repositories/celestial_body_repository.dart';
import '../../domain/repositories/constellation_repository.dart';
import '../../domain/repositories/note_content_repository.dart';
import '../../domain/repositories/search_repository.dart';
import '../../domain/repositories/wormhole_repository.dart';

// ---------------------------------------------------------------------------
// Hive box providers
// ---------------------------------------------------------------------------

final blackHolesBoxProvider = Provider<Box<BlackHoleModel>>(
  (ref) => Hive.box<BlackHoleModel>('blackHoles'),
);

final starsBoxProvider = Provider<Box<StarModel>>(
  (ref) => Hive.box<StarModel>('stars'),
);

final planetsBoxProvider = Provider<Box<PlanetModel>>(
  (ref) => Hive.box<PlanetModel>('planets'),
);

final moonsBoxProvider = Provider<Box<MoonModel>>(
  (ref) => Hive.box<MoonModel>('moons'),
);

final asteroidsBoxProvider = Provider<Box<AsteroidModel>>(
  (ref) => Hive.box<AsteroidModel>('asteroids'),
);

final noteContentsBoxProvider = Provider<Box<NoteContentModel>>(
  (ref) => Hive.box<NoteContentModel>('noteContents'),
);

final wormholesBoxProvider = Provider<Box<WormholeModel>>(
  (ref) => Hive.box<WormholeModel>('wormholes'),
);

final constellationLinksBoxProvider = Provider<Box<ConstellationLinkModel>>(
  (ref) => Hive.box<ConstellationLinkModel>('constellationLinks'),
);

// ---------------------------------------------------------------------------
// Datasource providers
// ---------------------------------------------------------------------------

final localCelestialDatasourceProvider = Provider<LocalCelestialDatasource>(
  (ref) => LocalCelestialDatasource(
    blackHolesBox: ref.watch(blackHolesBoxProvider),
    starsBox: ref.watch(starsBoxProvider),
    planetsBox: ref.watch(planetsBoxProvider),
    moonsBox: ref.watch(moonsBoxProvider),
    asteroidsBox: ref.watch(asteroidsBoxProvider),
  ),
);

final localNoteContentDatasourceProvider =
    Provider<LocalNoteContentDatasource>(
  (ref) => LocalNoteContentDatasource(
    noteContentsBox: ref.watch(noteContentsBoxProvider),
  ),
);

final localSearchDatasourceProvider = Provider<LocalSearchDatasource>(
  (ref) => LocalSearchDatasource(
    noteContentsBox: ref.watch(noteContentsBoxProvider),
    planetsBox: ref.watch(planetsBoxProvider),
    starsBox: ref.watch(starsBoxProvider),
  ),
);

// ---------------------------------------------------------------------------
// Repository providers
// ---------------------------------------------------------------------------

final celestialBodyRepositoryImplProvider =
    Provider<CelestialBodyRepository>(
  (ref) => CelestialBodyRepositoryImpl(
    datasource: ref.watch(localCelestialDatasourceProvider),
    wormholeDatasource: ref.watch(localWormholeDatasourceProvider),
    constellationDatasource: ref.watch(localConstellationDatasourceProvider),
    noteContentDatasource: ref.watch(localNoteContentDatasourceProvider),
  ),
);

final noteContentRepositoryImplProvider =
    Provider<NoteContentRepository>(
  (ref) => NoteContentRepositoryImpl(
    datasource: ref.watch(localNoteContentDatasourceProvider),
  ),
);

final searchRepositoryImplProvider = Provider<SearchRepository>(
  (ref) => SearchRepositoryImpl(
    datasource: ref.watch(localSearchDatasourceProvider),
  ),
);

final localWormholeDatasourceProvider = Provider<LocalWormholeDatasource>(
  (ref) => LocalWormholeDatasource(
    wormholesBox: ref.watch(wormholesBoxProvider),
  ),
);

final localConstellationDatasourceProvider =
    Provider<LocalConstellationDatasource>(
  (ref) => LocalConstellationDatasource(
    constellationLinksBox: ref.watch(constellationLinksBoxProvider),
  ),
);

final wormholeRepositoryProvider = Provider<WormholeRepository>(
  (ref) => WormholeRepositoryImpl(
    datasource: ref.watch(localWormholeDatasourceProvider),
  ),
);

final constellationRepositoryProvider = Provider<ConstellationRepository>(
  (ref) => ConstellationRepositoryImpl(
    datasource: ref.watch(localConstellationDatasourceProvider),
  ),
);
