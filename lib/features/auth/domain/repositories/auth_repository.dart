import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<String?> login({required String email, required String password});

  Future<String?> register({
    required String email,
    required String password,
    required String firstname,
    required String lastname,
    required String phoneNumber,
    required String username,
  });

  Future<void> logout();

  Future<UserEntity?> getCurrentUser();
}
