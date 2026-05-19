import '../../../auth/domain/entities/user_entity.dart';

abstract class ProfileRepository {
  Future<UserEntity?> getProfile();
  Future<String> updateProfile(Map<String, dynamic> data);
  Future<String> updatePhoneWithAuth(
    String currentPassword,
    String newPhoneNumber,
  );
  Future<String> changePassword(String currentPassword, String newPassword);
}
