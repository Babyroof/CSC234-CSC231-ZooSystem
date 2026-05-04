import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/auth_model.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  Future<String?> register({
    required String email,
    required String password,
    required String firstname,
    required String lastname,
    required String phoneNumber,
    required String username,
  }) async {
    debugPrint('[AuthService] register: attempt — email=$email, username=$username');
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        debugPrint('[AuthService] register: Firebase Auth returned null user');
        return "Cannot create an account.";
      }

      final newUser = UserModel(
        uid: user.uid,
        email: email,
        firstname: firstname,
        lastname: lastname,
        phoneNumber: phoneNumber,
        username: username,
      );

      try {
        await _firestore.collection('user').doc(user.uid).set(newUser.toJson());
        debugPrint('[AuthService] register: success — uid=${user.uid}');
        return "Success";
      } catch (e) {
        debugPrint('[AuthService] register: Firestore write failed — $e');
        return "Cannot save data. Please check Firestore Rules.";
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthService] register: FirebaseAuthException — code=${e.code}, message=${e.message}');
      if (e.code == 'weak-password') {
        return "Password must be at least 6 characters.";
      }
      if (e.code == 'email-already-in-use') {
        return "This email is already in use.";
      }
      return e.message ?? "Firebase Auth Error";
    } catch (e) {
      debugPrint('[AuthService] register: unexpected error — $e');
      return "Registration failed. Please try again.";
    }
  }

  Future<String?> login(String email, String password) async {
    debugPrint('[AuthService] login: attempt — email=$email');
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      debugPrint('[AuthService] login: success — $email');
      return "Success";
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthService] login: FirebaseAuthException — code=${e.code}');
      return "Email or Password is not correct";
    } catch (e) {
      debugPrint('[AuthService] login: unexpected error — $e');
      return "Something went wrong";
    }
  }

  //Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  //Get Current User
  Future<UserModel?> getCurrentUserData() async {
    try {
      User? currentUser = _auth.currentUser;

      if (currentUser != null) {
        DocumentSnapshot doc = await _firestore
            .collection('user')
            .doc(currentUser.uid)
            .get();
        if (doc.exists) {
          return UserModel.fromJson(
            doc.data() as Map<String, dynamic>,
            currentUser.uid,
          );
        }
      }
      return null;
    } catch (e) {
      debugPrint("Error fetching user data: $e");
      return null;
    }
  }
}
