import '../repositories/profile_repository.dart';

class UpdateProfileUseCase {
  const UpdateProfileUseCase(this._repository);
  final ProfileRepository _repository;

  Future<String> call(Map<String, dynamic> data) =>
      _repository.updateProfile(data);
}
