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
  final bool choseLocalMode;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.choseLocalMode = false,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserProfile? user,
    bool? isLoading,
    Failure? error,
    bool? choseLocalMode,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      choseLocalMode: choseLocalMode ?? this.choseLocalMode,
    );
  }
}

// ---------------------------------------------------------------------------
// Auth notifier
// ---------------------------------------------------------------------------

class AuthNotifier extends StateNotifier<AuthState> {
  final UserRepository _repo;

  // Start with isLoading=true so the auth gate shows a splash while we
  // check for an existing session, preventing a flash of the auth screen.
  AuthNotifier(this._repo) : super(const AuthState(isLoading: true));

  /// Trigger the real Google Sign-In flow.
  Future<void> signIn() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repo.signInWithGoogle();
      result.fold(
        (failure) => state = state.copyWith(
          isLoading: false,
          error: failure,
        ),
        (user) {
          state = state.copyWith(
            isLoading: false,
            user: user,
            // user == null means the dialog was cancelled — not an error
          );
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
        (_) => state = state.copyWith(
          isLoading: false,
          clearUser: true,
          choseLocalMode: false,
        ),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: AuthFailure('Sign out failed: $e'),
      );
    }
  }

  /// Delete the Firebase account and all local data.
  Future<void> deleteAccount() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repo.deleteAccount();
      result.fold(
        (failure) => state = state.copyWith(isLoading: false, error: failure),
        (_) => state = state.copyWith(
          isLoading: false,
          clearUser: true,
          choseLocalMode: false,
        ),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: AuthFailure('Account deletion failed: $e'),
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
    state = state.copyWith(
      isLoading: false,
      clearUser: true,
      clearError: true,
      choseLocalMode: true,
    );
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

  @override
  Future<Either<Failure, UserProfile?>> signInWithGoogle() async {
    // Firebase not available — cannot sign in.
    return Left(AuthFailure('Firebase is not configured on this device.'));
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    // No Firebase account to delete; just clear local cache.
    try {
      await _datasource.clearUser();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('$e'));
    }
  }
}
