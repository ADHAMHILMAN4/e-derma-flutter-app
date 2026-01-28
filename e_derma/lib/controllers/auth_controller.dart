import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ Register a new "pengguna"
  Future<User?> registerUser(
      String name, String phone, String email, String password) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      UserModel newUser = UserModel(
        uid: userCredential.user!.uid,
        name: name.trim(),
        phone: phone.trim(),
        email: email.trim(),
        role: "pengguna",
        createdAt: DateTime.now(),
      );

      // Save user data in Firestore under "pengguna" collection
      await _firestore
          .collection('pengguna')
          .doc(newUser.uid)
          .set(newUser.toMap());

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // ✅ Login for all users (pengguna, pusat derma, pentadbir)
  Future<UserModel?> loginUser(String email, String password) async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      String uid = userCredential.user!.uid;
      print("✅ User Logged In - UID: $uid");

      DocumentSnapshot penggunaDoc = await FirebaseFirestore.instance
          .collection('pengguna')
          .doc(uid)
          .get();
      DocumentSnapshot pusatDermaDoc = await FirebaseFirestore.instance
          .collection('pusat_derma')
          .doc(uid)
          .get();
      DocumentSnapshot pentadbirDoc = await FirebaseFirestore.instance
          .collection('pentadbir')
          .doc(uid)
          .get();

      if (penggunaDoc.exists) {
        print("✅ User Role: pengguna");
        return UserModel.fromMap(penggunaDoc.data() as Map<String, dynamic>);
      } else if (pusatDermaDoc.exists) {
        print("✅ User Role: pusat_derma");
        return UserModel.fromMap(pusatDermaDoc.data() as Map<String, dynamic>);
      } else if (pentadbirDoc.exists) {
        print("✅ User Role: pentadbir");
        return UserModel.fromMap(pentadbirDoc.data() as Map<String, dynamic>);
      } else {
        print("❌ Error: User role not found in Firestore");
        throw Exception("User role not found.");
      }
    } on FirebaseAuthException catch (e) {
      print("❌ FirebaseAuthException: ${e.message}");
      throw Exception(e.message);
    }
  }

  // ✅ Get current logged-in user details
  Future<UserModel?> getUserDetails(String uid) async {
    try {
      // Check user role from different collections
      DocumentSnapshot penggunaDoc =
          await _firestore.collection('pengguna').doc(uid).get();
      DocumentSnapshot pusatDermaDoc =
          await _firestore.collection('pusat_derma').doc(uid).get();
      DocumentSnapshot pentadbirDoc =
          await _firestore.collection('pentadbir').doc(uid).get();

      if (penggunaDoc.exists) {
        return UserModel.fromMap(penggunaDoc.data() as Map<String, dynamic>);
      } else if (pusatDermaDoc.exists) {
        return UserModel.fromMap(pusatDermaDoc.data() as Map<String, dynamic>);
      } else if (pentadbirDoc.exists) {
        return UserModel.fromMap(pentadbirDoc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      print("Error fetching user details: $e");
    }
    return null;
  }

  // ✅ Logout user
  Future<void> logoutUser() async {
    await _auth.signOut();
  }
}
