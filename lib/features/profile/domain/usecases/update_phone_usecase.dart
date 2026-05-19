import '../repositories/profile_repository.dart';

class UpdatePhoneUseCase {
  const UpdatePhoneUseCase(this._repository);
  final ProfileRepository _repository;

  Future<String> call(String currentPassword, String newPhoneNumber) =>
      _repository.updatePhoneWithAuth(currentPassword, newPhoneNumber);
}
