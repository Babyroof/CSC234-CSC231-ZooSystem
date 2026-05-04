import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/models/auth_model.dart';

class ProfileService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserModel?> getUserProfile() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return null;
      final doc = await _firestore.collection('user').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<String> updateProfile(Map<String, dynamic> updatedData) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return "Not logged in";
      await _firestore.collection('user').doc(uid).update(updatedData);
      return "Success";
    } catch (_) {
      return "Update failed. Please try again.";
    }
  }

  Future<String> updatePhoneWithAuth(
    String currentPassword,
    String newPhoneNumber,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) return "Not logged in";
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      final uid = user.uid;
      await _firestore
          .collection('user')
          .doc(uid)
          .update({'phoneNumber': newPhoneNumber});
      return "Success";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return "wrong-password";
      }
      return e.message ?? "Failed to update phone number";
    } catch (_) {
      return "Update failed. Please try again.";
    }
  }

  Future<String> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) return "Not logged in";
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      return "Success";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return "wrong-password";
      }
      return e.message ?? "Failed to change password";
    } catch (_) {
      return "Failed to change password. Please try again.";
    }
  }
}
