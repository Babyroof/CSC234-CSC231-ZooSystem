import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:zoopernova_zoo_system/features/auth/presentation/models/auth_model.dart';

class AdminAuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AdminAuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  Future<String?> login(String email, String password) async {
    debugPrint('[AdminAuthService] login: attempt — email=$email');
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user?.uid;
      if (uid == null) return 'Login failed';

      final userDoc = await _firestore.collection('user').doc(uid).get();
      final data = userDoc.data();
      if (data == null || data['role'] != 'admin') {
        await _auth.signOut();
        debugPrint('[AdminAuthService] login: not an admin — uid=$uid');
        return 'Access denied. Admin account required.';
      }

      debugPrint('[AdminAuthService] login: success — uid=$uid');
      return 'Success';
    } on FirebaseAuthException catch (e) {
      debugPrint('[AdminAuthService] login: FirebaseAuthException — ${e.code}');
      return 'Email or Password is not correct';
    } catch (e) {
      debugPrint('[AdminAuthService] login: unexpected error — $e');
      return 'Something went wrong';
    }
  }

  Future<String?> register({
    required String email,
    required String password,
    required String firstname,
    required String lastname,
    required String phoneNumber,
  }) async {
    debugPrint('[AdminAuthService] register: attempt — email=$email');
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) return 'Cannot create an account.';

      final newUser = UserModel(
        uid: user.uid,
        email: email,
        firstname: firstname,
        lastname: lastname,
        phoneNumber: phoneNumber,
        username: '',
      );

      try {
        await _firestore.collection('user').doc(user.uid).set({
          ...newUser.toJson(),
          'role': 'admin',
        });
      } catch (e) {
        debugPrint('[AdminAuthService] register: user write failed — $e');
        return 'Cannot save data. Please check Firestore Rules.';
      }

      try {
        await _firestore.collection('admin').doc(user.uid).set({
          'userId': _firestore.collection('user').doc(user.uid),
        });
      } catch (e) {
        debugPrint(
          '[AdminAuthService] register: admin write failed (check Firestore rules) — $e',
        );
      }

      debugPrint('[AdminAuthService] register: success — uid=${user.uid}');
      return 'Success';
    } on FirebaseAuthException catch (e) {
      debugPrint(
        '[AdminAuthService] register: FirebaseAuthException — ${e.code}',
      );
      if (e.code == 'weak-password') {
        return 'Password must be at least 6 characters.';
      }
      if (e.code == 'email-already-in-use') {
        return 'This email is already in use.';
      }
      return e.message ?? 'Firebase Auth Error';
    } catch (e) {
      debugPrint('[AdminAuthService] register: unexpected error — $e');
      return 'Registration failed. Please try again.';
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
