import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:orbit_app/core/errors/exceptions.dart';
import 'package:orbit_app/core/errors/failures.dart';
import 'package:orbit_app/data/datasources/local_user_datasource.dart';
import 'package:orbit_app/data/models/user_profile_model.dart';
import 'package:orbit_app/domain/entities/user_profile.dart';
import 'package:orbit_app/domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final LocalUserDatasource localDatasource;
  final fb.FirebaseAuth firebaseAuth;
  final GoogleSignIn _googleSignIn;

  UserRepositoryImpl({
    required this.localDatasource,
    required this.firebaseAuth,
    GoogleSignIn? googleSignIn,
  }) : _googleSignIn = googleSignIn ?? GoogleSignIn();

  @override
  Future<Either<Failure, UserProfile?>> getCachedUser() async {
    try {
      final model = await localDatasource.getUser();
      return Right(model?.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> cacheUser(UserProfile user) async {
    try {
      await localDatasource.saveUser(UserProfileModel.fromEntity(user));
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _googleSignIn.signOut();
      await firebaseAuth.signOut();
      await localDatasource.clearUser();
      return const Right(null);
    } on fb.FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.message ?? 'Sign out failed.'));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(AuthFailure('Sign out failed: $e'));
    }
  }

  @override
  Future<Either<Failure, UserProfile?>> getCurrentFirebaseUser() async {
    try {
      final fbUser = firebaseAuth.currentUser;
      if (fbUser == null) return const Right(null);
      return Right(_profileFromFirebaseUser(fbUser));
    } on fb.FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.message ?? 'Failed to get current user.'));
    }
  }

  @override
  Future<Either<Failure, UserProfile?>> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the sign-in flow.
        return const Right(null);
      }

      final googleAuth = await googleUser.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await firebaseAuth.signInWithCredential(credential);
      final fbUser = userCredential.user;
      if (fbUser == null) {
        return Left(AuthFailure('Sign in succeeded but no user returned.'));
      }

      final profile = _profileFromFirebaseUser(fbUser);
      // Cache the profile locally so it's available in local-only mode.
      await localDatasource.saveUser(UserProfileModel.fromEntity(profile));
      return Right(profile);
    } on fb.FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.message ?? 'Google sign-in failed.'));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(AuthFailure('Google sign-in failed: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    try {
      final fbUser = firebaseAuth.currentUser;
      if (fbUser == null) {
        return Left(AuthFailure('No authenticated user to delete.'));
      }
      await fbUser.delete();
      await _googleSignIn.signOut();
      await localDatasource.clearUser();
      return const Right(null);
    } on fb.FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.message ?? 'Account deletion failed.'));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(AuthFailure('Account deletion failed: $e'));
    }
  }

  UserProfile _profileFromFirebaseUser(fb.User fbUser) {
    return UserProfile(
      id: fbUser.uid,
      email: fbUser.email ?? '',
      displayName: fbUser.displayName ?? '',
      photoUrl: fbUser.photoURL,
      tier: UserTier.free,
      createdAt: fbUser.metadata.creationTime ?? DateTime.now(),
    );
  }
}
