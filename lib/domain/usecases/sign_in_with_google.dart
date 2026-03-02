import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/user_profile.dart';
import '../repositories/user_repository.dart';

class SignInWithGoogle extends UseCase<UserProfile?, NoParams> {
  final UserRepository repository;

  SignInWithGoogle({required this.repository});

  @override
  Future<Either<Failure, UserProfile?>> call(NoParams params) =>
      repository.signInWithGoogle();
}
