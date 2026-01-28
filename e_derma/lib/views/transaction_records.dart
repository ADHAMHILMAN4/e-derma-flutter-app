import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'admin_transaction_detail_screen.dart'; // ← import the detail screen

class AdminTransactionRecordsScreen extends StatelessWidget {
  final String? pusatDermaName;
  final DateTime startDate;
  final DateTime endDate;

  const AdminTransactionRecordsScreen({
    Key? key,
    this.pusatDermaName,
    required this.startDate,
    required this.endDate,
  }) : super(key: key);

  Future<List<Map<String, dynamic>>> getTransactions() async {
    Query query = FirebaseFirestore.instance
        .collection('derma')
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('timestamp', descending: true);

    final snapshot = await query.get();
    final docs = snapshot.docs;

    // Extract unique userIds and pusatDermaUids
    final userUids = <String>{};
    final pusatUids = <String>{};

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) continue;

      if (data['userUid'] != null) userUids.add(data['userUid']);
      if (data['pusatDermaUid'] != null) pusatUids.add(data['pusatDermaUid']);
    }

    // Batch fetch user and pusat derma names
    final userFutures = userUids.map((uid) async {
      final doc = await FirebaseFirestore.instance
          .collection('pengguna')
          .doc(uid)
          .get();
      String name = 'Tidak diketahui';
      if (doc.exists) {
        final data = doc.data(); // returns Map<String, dynamic>?
        if (data != null && data['name'] != null) {
          name = data['name'];
        }
      }
      return MapEntry<String, String>(uid, name);
    });

    final pusatFutures = pusatUids.map((uid) async {
      final doc = await FirebaseFirestore.instance
          .collection('pusat_derma')
          .doc(uid)
          .get();
      String name = 'Tidak diketahui';
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['name'] != null) {
          name = data['name'];
        }
      }
      return MapEntry<String, String>(uid, name);
    });

    final userMap = Map.fromEntries(await Future.wait(userFutures));
    final pusatMap = Map.fromEntries(await Future.wait(pusatFutures));

    // Build result list
    return docs
        .map<Map<String, dynamic>>((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null)
            return {}; // Return an empty map (still valid Map<String, dynamic>)

          final userUid = data['userUid'] ?? '';
          final pusatUid = data['pusatDermaUid'] ?? '';

          return {
            'id': doc.id,
            'amount': (data['amount'] as num?)?.toDouble() ?? 0.0,
            'userName': userMap[userUid] ?? 'Tidak diketahui',
            'pusatDermaName': pusatMap[pusatUid] ?? 'Tidak diketahui',
            'timestamp': (data['timestamp'] as Timestamp?)?.toDate(),
          };
        })
        .where((tx) => tx.isNotEmpty)
        .toList();
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
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return const Center(child: Text("Gagal memuatkan transaksi"));

          final transactions = snapshot.data;
          if (transactions == null || transactions.isEmpty)
            return const Center(child: Text("Tiada transaksi dijumpai."));

          return ListView.separated(
            itemCount: transactions.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final tx = transactions[index];
              final formattedDate = tx['timestamp'] != null
                  ? DateFormat('dd MMM yyyy, hh:mm a').format(tx['timestamp'])
                  : "Tarikh tidak diketahui";

              return ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminTransactionDetailScreen(
                        transactionData: tx,
                      ),
                    ),
                  );
                },
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Penderma: ${tx['userName']}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF512D13),
                      ),
                    ),
                    Text(
                      "Penerima: ${tx['pusatDermaName']}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF512D13),
                      ),
                    ),
                    Text(
                      formattedDate,
                      style: const TextStyle(color: Color(0xFF512D13)),
                    ),
                  ],
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
