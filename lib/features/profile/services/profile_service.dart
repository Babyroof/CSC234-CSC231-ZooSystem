import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/models/auth_model.dart';

class ProfileService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //GET Profile
  Future<UserModel?> getUserProfile() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return null;

      DocumentSnapshot doc = await _firestore.collection('user').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  //UPDATE Profile
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
}
