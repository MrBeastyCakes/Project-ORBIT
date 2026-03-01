// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_content_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NoteContentModelAdapter extends TypeAdapter<NoteContentModel> {
  @override
  final int typeId = 5;

  @override
  NoteContentModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NoteContentModel(
      id: fields[0] as String,
      deltaJson: fields[1] as String,
      plainText: fields[2] as String,
      updatedAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, NoteContentModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.deltaJson)
      ..writeByte(2)
      ..write(obj.plainText)
      ..writeByte(3)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteContentModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
