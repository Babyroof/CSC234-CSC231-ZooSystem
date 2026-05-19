import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/profile_dto.dart';

abstract class ProfileRemoteDataSource {
  Future<ProfileDto?> getProfile();
  Future<String> updateProfile(Map<String, dynamic> data);
  Future<String> updatePhoneWithAuth(
    String currentPassword,
    String newPhoneNumber,
  );
  Future<String> changePassword(String currentPassword, String newPassword);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<ProfileDto?> getProfile() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return null;
      final doc = await _firestore.collection('user').doc(uid).get();
      if (doc.exists) {
        return ProfileDto.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      debugPrint('[ProfileDataSource] getProfile failed: $e');
      return null;
    }
  }

  @override
  Future<String> updateProfile(Map<String, dynamic> data) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return 'Not logged in';
      await _firestore.collection('user').doc(uid).update(data);
      return 'Success';
    } catch (e) {
      debugPrint('[ProfileDataSource] updateProfile failed: $e');
      return 'Update failed. Please try again.';
    }
  }

  @override
  Future<String> updatePhoneWithAuth(
    String currentPassword,
    String newPhoneNumber,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) return 'Not logged in';
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await _firestore.collection('user').doc(user.uid).update({
        'phoneNumber': newPhoneNumber,
      });
      return 'Success';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return 'wrong-password';
      }
      return e.message ?? 'Failed to update phone number';
    } catch (e) {
      debugPrint('[ProfileDataSource] updatePhoneWithAuth failed: $e');
      return 'Update failed. Please try again.';
    }
  }

  @override
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
    } catch (e) {
      debugPrint('[ProfileDataSource] changePassword failed: $e');
      return 'Failed to change password. Please try again.';
    }
  }
}
