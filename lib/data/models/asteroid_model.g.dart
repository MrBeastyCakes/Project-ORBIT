// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asteroid_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AsteroidModelAdapter extends TypeAdapter<AsteroidModel> {
  @override
  final int typeId = 4;

  @override
  AsteroidModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AsteroidModel(
      id: fields[0] as String,
      text: fields[1] as String,
      x: fields[2] as double,
      y: fields[3] as double,
      createdAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, AsteroidModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.text)
      ..writeByte(2)
      ..write(obj.x)
      ..writeByte(3)
      ..write(obj.y)
      ..writeByte(4)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AsteroidModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
