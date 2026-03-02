import 'package:dartz/dartz.dart';
import 'package:orbit_app/core/errors/exceptions.dart';
import 'package:orbit_app/core/errors/failures.dart';
import 'package:orbit_app/data/datasources/local_constellation_datasource.dart';
import 'package:orbit_app/data/models/constellation_link_model.dart';
import 'package:orbit_app/domain/entities/constellation_link.dart';
import 'package:orbit_app/domain/repositories/constellation_repository.dart';

class ConstellationRepositoryImpl implements ConstellationRepository {
  final LocalConstellationDatasource datasource;

  const ConstellationRepositoryImpl({required this.datasource});

  @override
  Future<Either<Failure, ConstellationLink>> createConstellationLink(
      ConstellationLink link) async {
    try {
      final model = await datasource.insertConstellationLink(
        ConstellationLinkModel.fromEntity(link),
      );
      return Right(model.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<ConstellationLink>>>
      getConstellationLinks() async {
    try {
      final models = await datasource.getAllConstellationLinks();
      return Right(models.map((m) => m.toEntity()).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteConstellationLink(String id) async {
    try {
      await datasource.deleteConstellationLink(id);
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }
}
