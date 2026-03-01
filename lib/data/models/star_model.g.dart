// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'star_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StarModelAdapter extends TypeAdapter<StarModel> {
  @override
  final int typeId = 1;

  @override
  StarModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StarModel(
      id: fields[0] as String,
      name: fields[1] as String,
      x: fields[2] as double,
      y: fields[3] as double,
      mass: fields[4] as double,
      parentBlackHoleId: fields[5] as String,
      orbitRadius: fields[6] as double,
      orbitAngle: fields[7] as double,
      color: fields[8] as int,
      createdAt: fields[9] as DateTime,
      updatedAt: fields[10] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, StarModel obj) {
    writer
      ..writeByte(11)
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
      ..write(obj.parentBlackHoleId)
      ..writeByte(6)
      ..write(obj.orbitRadius)
      ..writeByte(7)
      ..write(obj.orbitAngle)
      ..writeByte(8)
      ..write(obj.color)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StarModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
