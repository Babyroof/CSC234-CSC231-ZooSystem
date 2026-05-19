import '../repositories/auth_repository.dart';

class RegisterUseCase {
  const RegisterUseCase(this._repository);

  final AuthRepository _repository;

  Future<String?> call({
    required String email,
    required String password,
    required String firstname,
    required String lastname,
    required String phoneNumber,
    required String username,
  }) => _repository.register(
    email: email,
    password: password,
    firstname: firstname,
    lastname: lastname,
    phoneNumber: phoneNumber,
    username: username,
  );
}
