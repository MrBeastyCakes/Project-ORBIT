import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/user_profile.dart';
import '../../core/constants/orbit_constants.dart';
import 'auth_provider.dart';
import 'galaxy_provider.dart';

/// Convenience provider exposing the current user's tier.
final tierProvider = Provider<UserTier>((ref) {
  return ref.watch(authProvider).user?.tier ?? UserTier.free;
});

/// Whether the current user can create another BlackHole.
final canCreateBlackHoleProvider = Provider<bool>((ref) {
  final tier = ref.watch(tierProvider);
  if (tier == UserTier.paid) return true;
  final count = ref.watch(galaxyProvider).blackHoles.length;
  return count < OrbitConstants.freeBlackHoleLimit;
});
