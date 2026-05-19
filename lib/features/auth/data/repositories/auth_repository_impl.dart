import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._dataSource);

  final AuthRemoteDataSource _dataSource;

  @override
  Future<String?> login({required String email, required String password}) =>
      _dataSource.login(email, password);

  @override
  Future<String?> register({
    required String email,
    required String password,
    required String firstname,
    required String lastname,
    required String phoneNumber,
    required String username,
  }) => _dataSource.register(
    email: email,
    password: password,
    firstname: firstname,
    lastname: lastname,
    phoneNumber: phoneNumber,
    username: username,
  );

  @override
  Future<void> logout() => _dataSource.logout();

  @override
  Future<UserEntity?> getCurrentUser() async {
    final dto = await _dataSource.getCurrentUser();
    return dto?.toEntity();
  }
}
