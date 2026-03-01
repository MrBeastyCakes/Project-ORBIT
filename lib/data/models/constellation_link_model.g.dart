// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'constellation_link_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ConstellationLinkModelAdapter
    extends TypeAdapter<ConstellationLinkModel> {
  @override
  final int typeId = 7;

  @override
  ConstellationLinkModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ConstellationLinkModel(
      id: fields[0] as String,
      sourcePlanetId: fields[1] as String,
      targetPlanetId: fields[2] as String,
      createdAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ConstellationLinkModel obj) {
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
      other is ConstellationLinkModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
