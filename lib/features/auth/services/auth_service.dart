import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/auth_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestor = FirebaseFirestore.instance;

  Future<String?> register({
    required String email,
    required String password,
    required String firstname,
    required String lastname,
    required String phoneNumber,
    required String username,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) return "Cannot create an account.";

      final newUser = UserModel(
        uid: user.uid,
        email: email,
        firstname: firstname,
        lastname: lastname,
        phoneNumber: phoneNumber,
        username: username,
      );

      try {
        await _firestor.collection('user').doc(user.uid).set(newUser.toJson());
        return "Success";
      } catch (_) {
        return "Cannot save data. Please check Firestore Rules.";
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        return "Password must be at least 6 characters.";
      }
      if (e.code == 'email-already-in-use') {
        return "This email is already in use.";
      }
      return e.message ?? "Firebase Auth Error";
    } catch (_) {
      return "Registration failed. Please try again.";
    }
  }

  //Login
  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return "Success";
    } on FirebaseAuthException catch (e) {
      return "Email or Password is not correct";
    } catch (e) {
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
        DocumentSnapshot doc = await _firestor
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
      print("Error fetiching user data: $e");
      return null;
    }
  }
}
