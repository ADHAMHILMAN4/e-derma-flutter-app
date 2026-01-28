import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'donation_details_screen.dart';
import 'package:intl/intl.dart';

class DonationHistoryScreen extends StatelessWidget {
  const DonationHistoryScreen({super.key});

  Future<String?> getCurrentUserEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    return user?.email;
  }

  /// 🔍 Fetch Pusat Derma details using its UID
  Future<Map<String, dynamic>?> getPusatDermaInfoByUid(String? uid) async {
    if (uid == null || uid.isEmpty) return null;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('pusat_derma')
          .doc(uid)
          .get();
      if (doc.exists) return doc.data();
    } catch (e) {
      print('❌ Error fetching pusat derma info for $uid: $e');
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Rekod Derma",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<String?>(
        future: getCurrentUserEmail(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final email = snapshot.data;
          if (email == null) {
            return const Center(child: Text("No user logged in."));
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('derma')
                .where('userEmail', isEqualTo: email)
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text("Something went wrong."));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return const Center(child: Text("Tiada rekod derma."));
              }

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final amount = data['amount'];
                  final pusatUid = data['pusatDermaUid'];
                  final timestamp = data['timestamp']?.toDate();

                  return FutureBuilder<Map<String, dynamic>?>(
                    future: getPusatDermaInfoByUid(pusatUid),
                    builder: (context, pusatSnapshot) {
                      final pusatData = pusatSnapshot.data;
                      final pusatName =
                          pusatData?['name'] ?? 'Unknown Pusat Derma';
                      final profileImageUrl =
                          pusatData?['profileImageUrl'] ?? '';

                      return Column(
                        children: [
                          ListTile(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DonationDetailScreen(
                                    donationData: data,
                                    profileImageUrl: profileImageUrl,
                                    paymentId: docs[index].id,
                                  ),
                                ),
                              );
                            },
                            leading: CircleAvatar(
                              backgroundImage: profileImageUrl.isNotEmpty
                                  ? NetworkImage(profileImageUrl)
                                  : const AssetImage(
                                          'assets/default_profile_image.png')
                                      as ImageProvider,
                            ),
                            title: Text(
                              pusatName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            trailing: Text(
                              "RM ${(amount is num ? amount.toDouble() : 0.0).toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 20,
                                color: Color(0xFF0BE914),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              timestamp != null
                                  ? DateFormat('dd MMM yyyy, hh:mm a')
                                      .format(timestamp)
                                  : "No date available",
                            ),
                          ),
                          const Divider(),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
