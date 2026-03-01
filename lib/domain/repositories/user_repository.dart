import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/user_profile.dart';

abstract class UserRepository {
  Future<Either<Failure, UserProfile?>> getCachedUser();
  Future<Either<Failure, void>> cacheUser(UserProfile user);
  Future<Either<Failure, void>> signOut();
  Future<Either<Failure, UserProfile?>> getCurrentFirebaseUser();
}
