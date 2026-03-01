// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wormhole_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WormholeModelAdapter extends TypeAdapter<WormholeModel> {
  @override
  final int typeId = 6;

  @override
  WormholeModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WormholeModel(
      id: fields[0] as String,
      sourcePlanetId: fields[1] as String,
      targetPlanetId: fields[2] as String,
      createdAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, WormholeModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.sourcePlanetId)
      ..writeByte(2)
      ..write(obj.targetPlanetId)
      ..writeByte(3)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WormholeModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
