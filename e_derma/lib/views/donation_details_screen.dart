import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DonationDetailScreen extends StatelessWidget {
  final Map<String, dynamic> donationData;
  final String? profileImageUrl;
  final String paymentId;

  const DonationDetailScreen({
    super.key,
    required this.donationData,
    required this.profileImageUrl,
    required this.paymentId,
  });

  static const List<String> _knownStates = [
    'Selangor',
    'Kuala Lumpur',
    'Johor',
    'Penang',
    'Pulau Pinang',
    'Perak',
    'Pahang',
    'Negeri Sembilan',
    'Melaka',
    'Kedah',
    'Perlis',
    'Terengganu',
    'Kelantan',
    'Sabah',
    'Sarawak',
    'Labuan',
    'Putrajaya'
  ];

  String _extractState(String address) {
    for (var state in _knownStates) {
      if (address.toLowerCase().contains(state.toLowerCase())) {
        return state;
      }
    }
    return 'Unknown';
  }

  /// Fetch pusat_derma details by UID and return both name and state
  Future<Map<String, String>> _getPusatDermaInfo(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('pusat_derma')
          .doc(uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final name = data['name'] ?? 'Unknown';
        final address = data['address'] ?? '';
        final state = _extractState(address);
        return {'name': name, 'state': state};
      }
    } catch (e) {
      print('❌ Failed to fetch pusat_derma info: $e');
    }
    return {'name': 'Unknown', 'state': 'Unknown'};
  }

  @override
  Widget build(BuildContext context) {
    final amount = (donationData['amount'] as num?)?.toDouble() ?? 0.0;
    final timestamp =
        (donationData['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    final formattedDate = DateFormat('EEEE, d/M/yyyy').format(timestamp);
    final formattedTime = DateFormat('HH:mm a').format(timestamp);

    final pusatUid = donationData['pusatDermaUid'] as String? ?? '';

    return FutureBuilder<Map<String, String>>(
      future: _getPusatDermaInfo(pusatUid),
      builder: (context, snapshot) {
        final pusatName = snapshot.data?['name'] ?? 'Loading...';
        final state = snapshot.data?['state'] ?? '';

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFFFFB800)),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              pusatName.length > 20
                  ? "${pusatName.substring(0, 20)}..."
                  : pusatName,
              style: const TextStyle(color: Color(0xFFFFB800)),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Center(
                  child: CircleAvatar(
                    radius: 70,
                    backgroundImage: profileImageUrl != null &&
                            profileImageUrl!.isNotEmpty
                        ? NetworkImage(profileImageUrl!)
                        : const AssetImage('assets/default_profile_image.png')
                            as ImageProvider,
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text(
                          'Payment ID',
                          style: TextStyle(
                            color: Color(0xFFFFB800),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: Text(
                          paymentId,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF512D13),
                          ),
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(
                          Icons.calendar_today_rounded,
                          color: Colors.brown,
                        ),
                        title: Text(formattedDate),
                        subtitle: Text(formattedTime),
                      ),
                      const Divider(),
                      ListTile(
                        leading:
                            const Icon(Icons.location_on, color: Colors.brown),
                        title: Text(pusatName,
                            style: const TextStyle(color: Color(0xFF512D13))),
                        subtitle: Text(
                          state,
                          style: const TextStyle(color: Color(0xFF512D13)),
                        ),
                      ),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Jumlah',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.brown,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              "RM ${amount.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0BE914),
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
      },
    );
  }
}
