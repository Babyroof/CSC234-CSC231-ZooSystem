import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile_admin_model.dart';

class ProfileAdminService {
  // TODO: Inject FirebaseFirestore and FirebaseAuth — replace all methods with real calls
  ProfileAdminModel _profile = const ProfileAdminModel(
    id: 'admin_mock',
    firstname: 'Admin',
    lastname: 'Zoo',
    email: 'admin@zoo.com',
    username: 'admin_zoo',
    phoneNumber: '0812345678',
  );

  Future<ProfileAdminModel?> getProfile() async {
    // TODO: Get UID from FirebaseAuth.instance.currentUser?.uid, then _db.collection('user').doc(uid).get()
    return _profile;
  }

  Future<void> updateProfile({
    required String firstname,
    required String lastname,
    required String email,
  }) async {
    // TODO: _db.collection('user').doc(uid).update({'firstname': firstname, 'lastname': lastname, 'email': email})
    _profile = ProfileAdminModel(
      id: _profile.id,
      firstname: firstname,
      lastname: lastname,
      email: email,
      username: _profile.username,
      phoneNumber: _profile.phoneNumber,
    );
  }

  Future<void> updatePassword(String newPassword) async {
    // TODO: FirebaseAuth.instance.currentUser?.updatePassword(newPassword)
    // Catch FirebaseAuthException and rethrow for the screen to handle
  }
}

final profileAdminServiceProvider = Provider<ProfileAdminService>(
  (ref) => ProfileAdminService(),
);
