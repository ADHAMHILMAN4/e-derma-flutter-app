import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TransactionRecordsScreen extends StatelessWidget {
  final String pusatDermaUid;
  final String pusatDermaName;
  final DateTime startDate;
  final DateTime endDate;

  const TransactionRecordsScreen({
    Key? key,
    required this.pusatDermaUid,
    required this.pusatDermaName,
    required this.startDate,
    required this.endDate,
  }) : super(key: key);

  Future<List<Map<String, dynamic>>> getTransactions() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('derma')
          .where('pusatDermaUid', isEqualTo: pusatDermaUid)
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp',
              isLessThan:
                  Timestamp.fromDate(endDate.add(const Duration(days: 1))))
          .orderBy('timestamp',
              descending: true) // Sort by timestamp descending
          .get();

      List<Map<String, dynamic>> transactions = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final userUid = data['userUid']; // Get userUid

        // Fetch user name from pengguna collection using userUid
        String? userName;
        String? profilePicture;
        final userQuery = await FirebaseFirestore.instance
            .collection('pengguna')
            .where('uid', isEqualTo: userUid)
            .limit(1)
            .get();

        if (userQuery.docs.isNotEmpty) {
          userName = userQuery.docs.first.data()['name'];
          profilePicture = userQuery.docs.first.data()['profile_picture'];
        }

        transactions.add({
          'amount': (data['amount'] as num?)?.toDouble() ?? 0.0,
          'userName':
              userName ?? 'Tidak diketahui', // Fallback to 'Tidak diketahui'
          'pusatDermaName': data['pusatDermaName'] ?? '',
          'timestamp': (data['timestamp'] as Timestamp?)?.toDate(),
          'profile_picture': profilePicture,
        });
      }

      return transactions;
    } catch (e) {
      print("❌ Error in getTransactions: $e");
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: Color(0xFF512D13)),
        title: const Text(
          "Rekod Transaksi",
          style: TextStyle(
            color: Color(0xFFFFB800),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: getTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Gagal memuatkan transaksi"));
          }

          final transactions = snapshot.data;
          if (transactions == null || transactions.isEmpty) {
            return const Center(child: Text("Tiada transaksi dijumpai."));
          }

          return ListView.separated(
            itemCount: transactions.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final tx = transactions[index];
              final formattedDate = tx['timestamp'] != null
                  ? DateFormat('dd MMM yyyy, hh:mm a').format(tx['timestamp'])
                  : "Tarikh tidak diketahui";
              final imageUrl = tx['profile_picture'] ??
                  'https://res.cloudinary.com/dc1mmjp5m/image/upload/v1743734561/default_propic-removebg-preview_jhorbs.png';

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(imageUrl),
                  radius: 24,
                ),
                title: Text(
                  tx['userName'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF512D13),
                  ),
                ),
                subtitle: Text(
                  formattedDate,
                  style: const TextStyle(color: Color(0xFF512D13)),
                ),
                trailing: Text(
                  "RM ${tx['amount'].toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0BE914),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
