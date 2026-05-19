import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../data/datasources/profile_remote_datasource.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/usecases/get_profile_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../../domain/usecases/update_phone_usecase.dart';
import '../../domain/usecases/change_password_usecase.dart';

part 'profile_providers.g.dart';

@riverpod
Stream<User?> authState(Ref ref) {
  return FirebaseAuth.instance.authStateChanges();
}

@Riverpod(keepAlive: true)
ProfileRemoteDataSource profileRemoteDataSource(Ref ref) =>
    ProfileRemoteDataSourceImpl();

@Riverpod(keepAlive: true)
ProfileRepository profileRepository(Ref ref) =>
    ProfileRepositoryImpl(ref.watch(profileRemoteDataSourceProvider));

@Riverpod(keepAlive: true)
GetProfileUseCase getProfileUseCase(Ref ref) =>
    GetProfileUseCase(ref.watch(profileRepositoryProvider));

@Riverpod(keepAlive: true)
UpdateProfileUseCase updateProfileUseCase(Ref ref) =>
    UpdateProfileUseCase(ref.watch(profileRepositoryProvider));

@Riverpod(keepAlive: true)
UpdatePhoneUseCase updatePhoneUseCase(Ref ref) =>
    UpdatePhoneUseCase(ref.watch(profileRepositoryProvider));

@Riverpod(keepAlive: true)
ChangePasswordUseCase changePasswordUseCase(Ref ref) =>
    ChangePasswordUseCase(ref.watch(profileRepositoryProvider));

@riverpod
class ProfileNotifier extends _$ProfileNotifier {
  @override
  Future<UserEntity?> build() async {
    ref.watch(authStateProvider);
    return ref.read(getProfileUseCaseProvider).call();
  }

  Future<String> updateProfile(Map<String, dynamic> data) async {
    final result = await ref.read(updateProfileUseCaseProvider).call(data);
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
    final result = await ref
        .read(updatePhoneUseCaseProvider)
        .call(currentPassword, newPhoneNumber);
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
    return ref
        .read(changePasswordUseCaseProvider)
        .call(currentPassword, newPassword);
  }
}
