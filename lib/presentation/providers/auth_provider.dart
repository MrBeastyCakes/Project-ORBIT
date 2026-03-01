import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../data/datasources/local_user_datasource.dart';
import '../../data/models/user_profile_model.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_repository.dart';
import '../../core/errors/failures.dart';

// ---------------------------------------------------------------------------
// Infrastructure providers (declared here to avoid modifying providers.dart)
// ---------------------------------------------------------------------------

final _userBoxProvider = Provider<Box<UserProfileModel>>(
  (ref) => Hive.box<UserProfileModel>('users'),
);

final _localUserDatasourceProvider = Provider<LocalUserDatasource>(
  (ref) => LocalUserDatasource(userBox: ref.watch(_userBoxProvider)),
);

/// Returns null when Firebase is not available (not configured / no internet).
fb.FirebaseAuth? _tryGetFirebaseAuth() {
  try {
    return fb.FirebaseAuth.instance;
  } catch (_) {
    return null;
  }
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final datasource = ref.watch(_localUserDatasourceProvider);
  final firebaseAuth = _tryGetFirebaseAuth();
  if (firebaseAuth == null) {
    // Firebase not available — return a no-op implementation that only uses
    // the local cache.
    return _LocalOnlyUserRepository(datasource);
  }
  return UserRepositoryImpl(
    localDatasource: datasource,
    firebaseAuth: firebaseAuth,
  );
});

// ---------------------------------------------------------------------------
// Auth state
// ---------------------------------------------------------------------------

class AuthState {
  final UserProfile? user;
  final bool isLoading;
  final Failure? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserProfile? user,
    bool? isLoading,
    Failure? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// Auth notifier
// ---------------------------------------------------------------------------

class AuthNotifier extends StateNotifier<AuthState> {
  final UserRepository _repo;

  AuthNotifier(this._repo) : super(const AuthState());

  /// Attempt Google sign-in. Gracefully falls back on Firebase errors.
  Future<void> signIn() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repo.getCurrentFirebaseUser();
      result.fold(
        (failure) => state = state.copyWith(
          isLoading: false,
          error: failure,
        ),
        (user) {
          if (user != null) {
            _repo.cacheUser(user);
          }
          state = state.copyWith(isLoading: false, user: user);
        },
      );
    } catch (e) {
      // Firebase not initialised or network error — allow local-only mode.
      state = state.copyWith(
        isLoading: false,
        error: AuthFailure('Sign in unavailable: $e'),
      );
    }
  }

  /// Sign out from Firebase and clear the local cache.
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repo.signOut();
      result.fold(
        (failure) => state = state.copyWith(isLoading: false, error: failure),
        (_) => state = state.copyWith(isLoading: false, clearUser: true),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: AuthFailure('Sign out failed: $e'),
      );
    }
  }

  /// Check whether a user session already exists on app start.
  Future<void> checkAuth() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // Prefer live Firebase user; fall back to cached profile.
      final liveResult = await _repo.getCurrentFirebaseUser();
      final user = liveResult.fold((_) => null, (u) => u);
      if (user != null) {
        state = state.copyWith(isLoading: false, user: user);
        return;
      }
      final cachedResult = await _repo.getCachedUser();
      final cached = cachedResult.fold((_) => null, (u) => u);
      state = state.copyWith(isLoading: false, user: cached);
    } catch (e) {
      // Firebase not available — silently fall through to local-only mode.
      state = state.copyWith(isLoading: false, clearError: true);
    }
  }

  /// Continue without signing in (free-tier local-only mode).
  void continueLocally() {
    state = state.copyWith(isLoading: false, clearUser: true, clearError: true);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.watch(userRepositoryProvider)),
);

// ---------------------------------------------------------------------------
// Local-only fallback repository (no Firebase)
// ---------------------------------------------------------------------------

class _LocalOnlyUserRepository implements UserRepository {
  final LocalUserDatasource _datasource;

  _LocalOnlyUserRepository(this._datasource);

  @override
  Future<Either<Failure, UserProfile?>> getCachedUser() async {
    try {
      final model = await _datasource.getUser();
      return Right(model?.toEntity());
    } catch (e) {
      return Left(CacheFailure('$e'));
    }
  }

  @override
  Future<Either<Failure, void>> cacheUser(UserProfile user) async {
    try {
      await _datasource.saveUser(UserProfileModel.fromEntity(user));
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('$e'));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _datasource.clearUser();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('$e'));
    }
  }

  @override
  Future<Either<Failure, UserProfile?>> getCurrentFirebaseUser() async {
    return const Right(null);
  }
}
