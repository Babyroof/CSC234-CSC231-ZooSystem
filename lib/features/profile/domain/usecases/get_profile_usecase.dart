import '../../../auth/domain/entities/user_entity.dart';
import '../repositories/profile_repository.dart';

class GetProfileUseCase {
  const GetProfileUseCase(this._repository);
  final ProfileRepository _repository;

  Future<UserEntity?> call() => _repository.getProfile();
}
