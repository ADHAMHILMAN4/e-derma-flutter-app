import 'package:cloud_firestore/cloud_firestore.dart';

class AdminController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ✅ Fetch total number of Pengguna
  Future<int> getTotalPengguna() async {
    try {
      QuerySnapshot penggunaSnapshot =
          await _firestore.collection('pengguna').get();
      return penggunaSnapshot.size;
    } catch (e) {
      print("Error fetching pengguna count: $e");
      return 0;
    }
  }

  /// ✅ Fetch total number of Pusat Derma
  Future<int> getTotalPusatDerma() async {
    try {
      QuerySnapshot pusatDermaSnapshot =
          await _firestore.collection('pusat_derma').get();
      return pusatDermaSnapshot.size;
    } catch (e) {
      print("Error fetching pusat derma count: $e");
      return 0;
    }
  }

  /// ✅ Fetch total derma amount from all donations
  Future<double> getTotalDerma() async {
    try {
      QuerySnapshot dermaSnapshot = await _firestore.collection('derma').get();

      double total = 0.0;
      for (var doc in dermaSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final amount = (data['amount'] ?? 0).toDouble();
        total += amount;
      }

      return total;
    } catch (e) {
      print("Error fetching total derma: $e");
      return 0.0;
    }
  }
}
