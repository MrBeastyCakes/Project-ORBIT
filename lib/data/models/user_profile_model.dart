import 'package:hive/hive.dart';
import 'package:orbit_app/domain/entities/user_profile.dart';

part 'user_profile_model.g.dart';

@HiveType(typeId: 8)
class UserProfileModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String email;

  @HiveField(2)
  final String displayName;

  @HiveField(3)
  final String? photoUrl;

  @HiveField(4)
  final int tier; // stored as int

  @HiveField(5)
  final DateTime createdAt;

  UserProfileModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.tier,
    required this.createdAt,
  });

  factory UserProfileModel.fromEntity(UserProfile entity) {
    return UserProfileModel(
      id: entity.id,
      email: entity.email,
      displayName: entity.displayName,
      photoUrl: entity.photoUrl,
      tier: entity.tier.index,
      createdAt: entity.createdAt,
    );
  }

  UserProfile toEntity() {
    return UserProfile(
      id: id,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      tier: UserTier.values[tier],
      createdAt: createdAt,
    );
  }
}
