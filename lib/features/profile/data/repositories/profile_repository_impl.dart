import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._dataSource);
  final ProfileRemoteDataSource _dataSource;

  @override
  Future<UserEntity?> getProfile() async {
    final dto = await _dataSource.getProfile();
    return dto?.toEntity();
  }

  @override
  Future<String> updateProfile(Map<String, dynamic> data) =>
      _dataSource.updateProfile(data);

  @override
  Future<String> updatePhoneWithAuth(
    String currentPassword,
    String newPhoneNumber,
  ) => _dataSource.updatePhoneWithAuth(currentPassword, newPhoneNumber);

  @override
  Future<String> changePassword(String currentPassword, String newPassword) =>
      _dataSource.changePassword(currentPassword, newPassword);
}
