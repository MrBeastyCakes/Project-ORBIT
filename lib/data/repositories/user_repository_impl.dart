import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:orbit_app/core/errors/exceptions.dart';
import 'package:orbit_app/core/errors/failures.dart';
import 'package:orbit_app/data/datasources/local_user_datasource.dart';
import 'package:orbit_app/data/models/user_profile_model.dart';
import 'package:orbit_app/domain/entities/user_profile.dart';
import 'package:orbit_app/domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final LocalUserDatasource localDatasource;
  final fb.FirebaseAuth firebaseAuth;

  const UserRepositoryImpl({
    required this.localDatasource,
    required this.firebaseAuth,
  });

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
      await firebaseAuth.signOut();
      await localDatasource.clearUser();
      return const Right(null);
    } on fb.FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.message ?? 'Sign out failed.'));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, UserProfile?>> getCurrentFirebaseUser() async {
    try {
      final fbUser = firebaseAuth.currentUser;
      if (fbUser == null) return const Right(null);
      final profile = UserProfile(
        id: fbUser.uid,
        email: fbUser.email ?? '',
        displayName: fbUser.displayName ?? '',
        photoUrl: fbUser.photoURL,
        tier: UserTier.free,
        createdAt: fbUser.metadata.creationTime ?? DateTime.now(),
      );
      return Right(profile);
    } on fb.FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.message ?? 'Failed to get current user.'));
    }
  }
}
