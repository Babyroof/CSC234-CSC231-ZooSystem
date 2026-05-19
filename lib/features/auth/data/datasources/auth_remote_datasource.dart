import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_dto.dart';

abstract class AuthRemoteDataSource {
  Future<String?> login(String email, String password);

  Future<String?> register({
    required String email,
    required String password,
    required String firstname,
    required String lastname,
    required String phoneNumber,
    required String username,
  });

  Future<void> logout();

  Future<UserDto?> getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Future<String?> login(String email, String password) async {
    debugPrint('[AuthDataSource] login: attempt — email=$email');
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      debugPrint('[AuthDataSource] login: success');
      return 'Success';
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthDataSource] login: FirebaseAuthException — ${e.code}');
      return 'Email or Password is not correct';
    } catch (e) {
      debugPrint('[AuthDataSource] login: unexpected error — $e');
      return 'Something went wrong';
    }
  }

  @override
  Future<String?> register({
    required String email,
    required String password,
    required String firstname,
    required String lastname,
    required String phoneNumber,
    required String username,
  }) async {
    debugPrint('[AuthDataSource] register: attempt — email=$email');
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        debugPrint('[AuthDataSource] register: null user returned');
        return 'Cannot create an account.';
      }
      final dto = UserDto(
        uid: user.uid,
        email: email,
        firstname: firstname,
        lastname: lastname,
        phoneNumber: phoneNumber,
        username: username,
      );
      try {
        await _firestore.collection('user').doc(user.uid).set(dto.toJson());
        debugPrint('[AuthDataSource] register: success — uid=${user.uid}');
        return 'Success';
      } catch (e) {
        debugPrint('[AuthDataSource] register: Firestore write failed — $e');
        return 'Cannot save data. Please check Firestore Rules.';
      }
    } on FirebaseAuthException catch (e) {
      debugPrint(
        '[AuthDataSource] register: FirebaseAuthException — ${e.code}',
      );
      if (e.code == 'weak-password')
        return 'Password must be at least 6 characters.';
      if (e.code == 'email-already-in-use')
        return 'This email is already in use.';
      return e.message ?? 'Firebase Auth Error';
    } catch (e) {
      debugPrint('[AuthDataSource] register: unexpected error — $e');
      return 'Registration failed. Please try again.';
    }
  }

  @override
  Future<void> logout() => _auth.signOut();

  @override
  Future<UserDto?> getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      final doc = await _firestore.collection('user').doc(user.uid).get();
      if (!doc.exists) return null;
      return UserDto.fromJson(doc.data() as Map<String, dynamic>, user.uid);
    } catch (e) {
      debugPrint('[AuthDataSource] getCurrentUser: error — $e');
      return null;
    }
  }
}
