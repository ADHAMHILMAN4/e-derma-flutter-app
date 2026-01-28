import 'package:cloud_firestore/cloud_firestore.dart';

class UserController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔹 Get Pengguna (Users)
  Stream<QuerySnapshot> getPengguna() {
    return _firestore.collection('pengguna').snapshots();
  }

  /// 🔹 Get Pusat Derma (Donation Centers)
  Stream<QuerySnapshot> getPusatDerma() {
    return _firestore.collection('pusat_derma').snapshots();
  }

  /// 🔹 Delete User / Pusat Derma
  Future<void> deleteUser(String userId, bool isPengguna) async {
    String collection = isPengguna ? 'pengguna' : 'pusat_derma';
    await _firestore.collection(collection).doc(userId).delete();
  }
}
