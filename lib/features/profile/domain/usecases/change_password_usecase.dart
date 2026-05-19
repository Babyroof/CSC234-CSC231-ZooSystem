import '../repositories/profile_repository.dart';

class ChangePasswordUseCase {
  const ChangePasswordUseCase(this._repository);
  final ProfileRepository _repository;

  Future<String> call(String currentPassword, String newPassword) =>
      _repository.changePassword(currentPassword, newPassword);
}
