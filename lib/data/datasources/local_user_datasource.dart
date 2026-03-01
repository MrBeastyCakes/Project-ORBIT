import 'package:hive/hive.dart';
import 'package:orbit_app/core/errors/exceptions.dart';
import 'package:orbit_app/data/models/user_profile_model.dart';

class LocalUserDatasource {
  final Box<UserProfileModel> userBox;

  const LocalUserDatasource({required this.userBox});

  static const String _userKey = 'current_user';

  Future<void> saveUser(UserProfileModel model) async {
    try {
      await userBox.put(_userKey, model);
    } catch (e) {
      throw CacheException('Failed to save user: $e');
    }
  }

  Future<UserProfileModel?> getUser() async {
    try {
      return userBox.get(_userKey);
    } catch (e) {
      throw CacheException('Failed to get user: $e');
    }
  }

  Future<void> clearUser() async {
    try {
      await userBox.delete(_userKey);
    } catch (e) {
      throw CacheException('Failed to clear user: $e');
    }
  }
}
