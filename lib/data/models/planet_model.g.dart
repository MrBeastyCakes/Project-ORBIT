// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planet_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlanetModelAdapter extends TypeAdapter<PlanetModel> {
  @override
  final int typeId = 2;

  @override
  PlanetModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlanetModel(
      id: fields[0] as String,
      name: fields[1] as String,
      x: fields[2] as double,
      y: fields[3] as double,
      mass: fields[4] as double,
      parentStarId: fields[5] as String,
      orbitRadius: fields[6] as double,
      orbitAngle: fields[7] as double,
      color: fields[8] as int,
      wordCount: fields[9] as int,
      lastOpenedAt: fields[10] as DateTime?,
      visualState: fields[11] as String,
      createdAt: fields[12] as DateTime,
      updatedAt: fields[13] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PlanetModel obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.x)
      ..writeByte(3)
      ..write(obj.y)
      ..writeByte(4)
      ..write(obj.mass)
      ..writeByte(5)
      ..write(obj.parentStarId)
      ..writeByte(6)
      ..write(obj.orbitRadius)
      ..writeByte(7)
      ..write(obj.orbitAngle)
      ..writeByte(8)
      ..write(obj.color)
      ..writeByte(9)
      ..write(obj.wordCount)
      ..writeByte(10)
      ..write(obj.lastOpenedAt)
      ..writeByte(11)
      ..write(obj.visualState)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanetModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
