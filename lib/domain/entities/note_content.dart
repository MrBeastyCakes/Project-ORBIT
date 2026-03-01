import 'package:equatable/equatable.dart';

class NoteContent extends Equatable {
  final String id; // matches planet id
  final String deltaJson; // Quill Delta JSON string
  final String plainText; // for search
  final DateTime updatedAt;

  const NoteContent({
    required this.id,
    required this.deltaJson,
    required this.plainText,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, deltaJson, plainText, updatedAt];
}
