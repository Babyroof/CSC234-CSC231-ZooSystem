import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile_admin_model.dart';

class ProfileAdminService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<ProfileAdminModel?> getProfile() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return null;
      final doc = await _firestore.collection('user').doc(uid).get();
      if (!doc.exists) return null;
      return ProfileAdminModel.fromMap(doc.id, doc.data()!);
    } catch (_) {
      return null;
    }
  }

  Future<void> updateProfile({
    required String firstname,
    required String lastname,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not logged in');
    await _firestore.collection('user').doc(uid).update({
      'firstname': firstname,
      'lastname': lastname,
    });
  }

  Future<String> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) return 'Not logged in';
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      return 'Success';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return 'wrong-password';
      }
      return e.message ?? 'Failed to change password';
    } catch (_) {
      return 'Failed to change password. Please try again.';
    }
  }
}

final profileAdminServiceProvider = Provider<ProfileAdminService>(
  (ref) => ProfileAdminService(),
);
