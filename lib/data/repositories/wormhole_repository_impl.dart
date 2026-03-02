import 'package:dartz/dartz.dart';
import 'package:orbit_app/core/errors/exceptions.dart';
import 'package:orbit_app/core/errors/failures.dart';
import 'package:orbit_app/data/datasources/local_wormhole_datasource.dart';
import 'package:orbit_app/data/models/wormhole_model.dart';
import 'package:orbit_app/domain/entities/wormhole.dart';
import 'package:orbit_app/domain/repositories/wormhole_repository.dart';

class WormholeRepositoryImpl implements WormholeRepository {
  final LocalWormholeDatasource datasource;

  const WormholeRepositoryImpl({required this.datasource});

  @override
  Future<Either<Failure, Wormhole>> createWormhole(Wormhole wormhole) async {
    try {
      final model = await datasource.insertWormhole(
        WormholeModel.fromEntity(wormhole),
      );
      return Right(model.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<Wormhole>>> getWormholes() async {
    try {
      final models = await datasource.getAllWormholes();
      return Right(models.map((m) => m.toEntity()).toList());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteWormhole(String id) async {
    try {
      await datasource.deleteWormhole(id);
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }
}
