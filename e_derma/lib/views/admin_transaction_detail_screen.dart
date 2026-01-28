import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminTransactionDetailScreen extends StatelessWidget {
  final Map<String, dynamic> transactionData;

  const AdminTransactionDetailScreen({
    Key? key,
    required this.transactionData,
  }) : super(key: key);

  Future<String> getPenggunaProfilePic(String userName) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('pengguna')
          .where('name', isEqualTo: userName)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first.data()['profile_picture'] ?? '';
      }
    } catch (e) {
      print('❌ Error fetching pengguna profile picture: $e');
    }
    return '';
  }

  Future<String> getPusatDermaProfilePic(String pusatName) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('pusat_derma')
          .where('name', isEqualTo: pusatName)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first.data()['profileImageUrl'] ?? '';
      }
    } catch (e) {
      print('❌ Error fetching pusat derma profile picture: $e');
    }
    return '';
  }

  String extractStateFromAddress(String address) {
    final states = [
      'Johor',
      'Kedah',
      'Kelantan',
      'Melaka',
      'Negeri Sembilan',
      'Pahang',
      'Perak',
      'Perlis',
      'Pulau Pinang',
      'Sabah',
      'Sarawak',
      'Selangor',
      'Terengganu',
      'Kuala Lumpur',
      'Labuan',
      'Putrajaya'
    ];

    for (var state in states) {
      if (address.toLowerCase().contains(state.toLowerCase())) {
        return state;
      }
    }

    return 'Negeri tidak diketahui';
  }

  @override
  Widget build(BuildContext context) {
    final id = transactionData['id'] as String;
    final userName = transactionData['userName'] as String;
    final pusatName = transactionData['pusatDermaName'] as String;
    final amount = (transactionData['amount'] as double?) ?? 0.0;
    final timestamp = transactionData['timestamp'] as DateTime?;
    final formattedDate = timestamp != null
        ? DateFormat('EEEE, d MMM yyyy').format(timestamp)
        : 'Tarikh tidak diketahui';
    final formattedTime =
        timestamp != null ? DateFormat('hh:mm a').format(timestamp) : '';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Butiran Rekod Transaksi"),
        centerTitle: true,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF512D13)),
        titleTextStyle: const TextStyle(
          color: Color(0xFFFFB800),
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ListTile(
                    title: const Text(
                      "Payment ID",
                      style: TextStyle(
                        color: Color(0xFFFFB800),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: Text(
                      id,
                      style: const TextStyle(
                        color: Color(0xFF512D13),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(),
// Penderma (User) - Show email
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('pengguna')
                        .where('name', isEqualTo: userName)
                        .limit(1)
                        .get()
                        .then((snapshot) => snapshot.docs.first),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final data =
                          snapshot.data?.data() as Map<String, dynamic>?;

                      final profilePicUrl = data?['profile_picture'] ?? '';
                      final userEmail =
                          data?['email'] ?? 'Email tidak dijumpai';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: profilePicUrl.isNotEmpty
                              ? NetworkImage(profilePicUrl)
                              : const AssetImage(
                                      'assets/default_profile_image.png')
                                  as ImageProvider,
                        ),
                        title: Text(userName),
                        subtitle: Text(userEmail),
                      );
                    },
                  ),
                  const Divider(),

// Pusat Derma (Charity Center) - Show state from address
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('pusat_derma')
                        .where('name', isEqualTo: pusatName)
                        .limit(1)
                        .get()
                        .then((snapshot) => snapshot.docs.first),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final data =
                          snapshot.data?.data() as Map<String, dynamic>?;

                      final profilePicUrl = data?['profileImageUrl'] ?? '';
                      final address = data?['address'] ?? '';
                      final extractedState = extractStateFromAddress(address);

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: profilePicUrl.isNotEmpty
                              ? NetworkImage(profilePicUrl)
                              : const AssetImage(
                                      'assets/default_profile_image.png')
                                  as ImageProvider,
                        ),
                        title: Text(pusatName),
                        subtitle: Text(extractedState),
                      );
                    },
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: Color(0xFF512D13), size: 40),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formattedDate,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              formattedTime,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Jumlah",
                          style: TextStyle(
                            color: Color(0xFF512D13),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          "RM ${amount.toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: Color(0xFF0BE914),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
