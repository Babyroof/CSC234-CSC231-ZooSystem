import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/models/auth_model.dart';
import 'profile_service.dart';

class ProfileNotifier extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    return ProfileService().getUserProfile();
  }

  Future<String> updateProfile(Map<String, dynamic> data) async {
    final result = await ProfileService().updateProfile(data);
    if (result == 'Success') {
      ref.invalidateSelf();
      await future;
    }
    return result;
  }

  Future<String> updatePhoneWithAuth(
    String currentPassword,
    String newPhoneNumber,
  ) async {
    final result = await ProfileService().updatePhoneWithAuth(
      currentPassword,
      newPhoneNumber,
    );
    if (result == 'Success') {
      ref.invalidateSelf();
      await future;
    }
    return result;
  }

  Future<String> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    return ProfileService().changePassword(currentPassword, newPassword);
  }
}

final profileNotifierProvider =
    AsyncNotifierProvider<ProfileNotifier, UserModel?>(ProfileNotifier.new);
