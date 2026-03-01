import 'package:equatable/equatable.dart';

enum UserTier { free, paid }

class UserProfile extends Equatable {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final UserTier tier;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.tier,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, email, displayName, photoUrl, tier, createdAt];
}
