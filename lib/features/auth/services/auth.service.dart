import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/auth.model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestor = FirebaseFirestore.instance;

  Future<String?> register ({
    required String email,
    required String password,
    required String firstname,
    required String lastname,
    required String phoneNumber,
    required String username,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;

      if(user != null) {
        UserModel newUser = UserModel(uid: user.uid, email: email, firstname: firstname, lastname: lastname, phoneNumber: phoneNumber, username: username);

        await _firestor.collection('user').doc(user.uid).set(newUser.toJson());

        return "Success";
      }
      return "Cannot create an account.";
    } on FirebaseAuthException catch(e) {
      if (e.code == 'weak-password') return "Your pass word need to up to 6 characters.";
      if (e.code == 'email-alreadyUsed') return "This email is used already!";
      return e.message;
    } catch(e) {
      return e.toString();
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return "Success";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'userNotFound' || e.code == 'wrongPassword' || e.code == 'invalidCredential') {
        return "Email or Password is not correct";
      }
      return e.message;
    } catch(e) {
      return e.toString();
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}