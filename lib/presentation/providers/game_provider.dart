import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/orbit_game.dart';

final gameProvider = Provider<OrbitGame>((ref) => OrbitGame());
