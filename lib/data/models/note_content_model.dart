import 'package:hive/hive.dart';
import 'package:orbit_app/domain/entities/note_content.dart';

part 'note_content_model.g.dart';

@HiveType(typeId: 5)
class NoteContentModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String deltaJson;

  @HiveField(2)
  final String plainText;

  @HiveField(3)
  final DateTime updatedAt;

  NoteContentModel({
    required this.id,
    required this.deltaJson,
    required this.plainText,
    required this.updatedAt,
  });

  factory NoteContentModel.fromEntity(NoteContent entity) {
    return NoteContentModel(
      id: entity.id,
      deltaJson: entity.deltaJson,
      plainText: entity.plainText,
      updatedAt: entity.updatedAt,
    );
  }

  NoteContent toEntity() {
    return NoteContent(
      id: id,
      deltaJson: deltaJson,
      plainText: plainText,
      updatedAt: updatedAt,
    );
  }
}
