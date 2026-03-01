import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../repositories/user_repository.dart';

class SignOut extends UseCase<void, NoParams> {
  final UserRepository repository;

  SignOut({required this.repository});

  @override
  Future<Either<Failure, void>> call(NoParams params) =>
      repository.signOut();
}
