import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/auth_model.dart';

class ProfileService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //GET Profile
  Future<UserModel?> getUserProfile() async {
    try {
      //Pull UID
      String uid = _auth.currentUser!.uid;
      //Fetch Data
      DocumentSnapshot doc = await _firestore.collection('user').doc(uid).get();

      if (doc.exists) {
        //Turn JSON to Usermodel format
        return UserModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print("Cannot fetch the data from firebase: $e");
      return null;
    }
  }

  //UPDATE Profile
  Future<String> updateProfile(Map<String, dynamic> updatedData) async {
    try {
      String uid = _auth.currentUser!.uid;

      await _firestore.collection('user').doc(uid).update(updatedData);
      return "Update Success";
    } catch (e) {
      print("Cannot update the profile: $e");
      return e.toString();
    }
  }
}
