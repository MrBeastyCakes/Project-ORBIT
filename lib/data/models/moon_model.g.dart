// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'moon_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MoonModelAdapter extends TypeAdapter<MoonModel> {
  @override
  final int typeId = 3;

  @override
  MoonModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MoonModel(
      id: fields[0] as String,
      parentPlanetId: fields[1] as String,
      label: fields[2] as String,
      isCompleted: fields[3] as bool,
      orbitRadius: fields[4] as double,
      orbitAngle: fields[5] as double,
    );
  }

  @override
  void write(BinaryWriter writer, MoonModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.parentPlanetId)
      ..writeByte(2)
      ..write(obj.label)
      ..writeByte(3)
      ..write(obj.isCompleted)
      ..writeByte(4)
      ..write(obj.orbitRadius)
      ..writeByte(5)
      ..write(obj.orbitAngle);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoonModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
