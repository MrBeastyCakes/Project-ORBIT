import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/moon.dart';
import '../repositories/celestial_body_repository.dart';

class AddMoon extends UseCase<void, AddMoonParams> {
  final CelestialBodyRepository repository;

  AddMoon({required this.repository});

  @override
  Future<Either<Failure, void>> call(AddMoonParams params) async {
    if (params.moon.label.trim().isEmpty) {
      return const Left(ValidationFailure('Moon label cannot be empty.'));
    }
    return repository.insertMoon(params.moon);
  }
}

class AddMoonParams extends Equatable {
  final Moon moon;

  const AddMoonParams({required this.moon});

  @override
  List<Object?> get props => [moon];
}
