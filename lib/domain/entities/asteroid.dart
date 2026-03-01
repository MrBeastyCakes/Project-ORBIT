import 'package:equatable/equatable.dart';

class Asteroid extends Equatable {
  final String id;
  final String text; // max 280 chars
  final double x;
  final double y;
  final DateTime createdAt;

  const Asteroid({
    required this.id,
    required this.text,
    required this.x,
    required this.y,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, text, x, y, createdAt];
}
