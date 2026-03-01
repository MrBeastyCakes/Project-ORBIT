// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'black_hole_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BlackHoleModelAdapter extends TypeAdapter<BlackHoleModel> {
  @override
  final int typeId = 0;

  @override
  BlackHoleModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BlackHoleModel(
      id: fields[0] as String,
      name: fields[1] as String,
      x: fields[2] as double,
      y: fields[3] as double,
      mass: fields[4] as double,
      color: fields[5] as int,
      createdAt: fields[6] as DateTime,
      updatedAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, BlackHoleModel obj) {
    writer
      ..writeByte(8)
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
      ..write(obj.color)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlackHoleModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
