import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'butiran_pusat_derma_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int totalPusatDerma = 0;
  double totalDerma = 0.0;
  List<Map<String, dynamic>> notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchTotalPusatDerma();
    _fetchTotalDermaByUser();
    _fetchNotifications();
  }

  Future<void> _fetchTotalPusatDerma() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('pusat_derma').get();
      setState(() {
        totalPusatDerma = snapshot.size;
      });
    } catch (e) {
      print("❌ Error fetching pusat derma count: $e");
    }
  }

  Future<void> _fetchTotalDermaByUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('derma')
            .where('userEmail', isEqualTo: user.email)
            .get();

        double total = 0.0;
        for (var doc in snapshot.docs) {
          total += (doc['amount'] as num).toDouble();
        }

        setState(() {
          totalDerma = total;
        });
      }
    } catch (e) {
      print("❌ Error fetching total derma: $e");
    }
  }

  Future<void> _fetchNotifications() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('notifikasi')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      setState(() {
        notifications = snapshot.docs
            .map((doc) => {
                  ...doc.data() as Map<String, dynamic>,
                  'id': doc['pusatDermaId'],
                })
            .toList();
      });
    } catch (e) {
      print("❌ Error fetching notifications: $e");
    }
  }

  Future<Map<String, String>> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('pengguna')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data();
        return {
          'name': data?['name'] ?? 'Pengguna',
          'profilePicture': data?['profile_picture'] ??
              'https://res.cloudinary.com/dc1mmjp5m/image/upload/v1743734561/default_propic-removebg-preview_jhorbs.png',
        };
      }
    }
    return {
      'name': 'Pengguna',
      'profilePicture':
          'https://res.cloudinary.com/dc1mmjp5m/image/upload/v1743734561/default_propic-removebg-preview_jhorbs.png',
    };
  }

  Future<Map<String, dynamic>?> _getPusatDermaData(String id) async {
    final doc = await FirebaseFirestore.instance
        .collection('pusat_derma')
        .doc(id)
        .get();

    if (!doc.exists) return null;

    final data = doc.data()!;
    data['profileImageUrl'] = data.containsKey('profileImageUrl') &&
            data['profileImageUrl'] != null &&
            data['profileImageUrl'].toString().isNotEmpty
        ? data['profileImageUrl']
        : 'https://res.cloudinary.com/dc1mmjp5m/image/upload/v1743734561/default_propic-removebg-preview_jhorbs.png';

    return data;
  }

  Future<void> _refreshData() async {
    await Future.wait([
      _fetchTotalPusatDerma(),
      _fetchTotalDermaByUser(),
      _fetchNotifications(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: FutureBuilder<Map<String, String>>(
          future: _getUserData(),
          builder: (context, snapshot) {
            final userData = snapshot.data ??
                {
                  'name': 'Pengguna',
                  'profilePicture':
                      'https://res.cloudinary.com/dc1mmjp5m/image/upload/v1743734561/default_propic-removebg-preview_jhorbs.png',
                };

            return Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(userData['profilePicture']!),
                  radius: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      const Text(
                        "Hello, ",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.normal),
                      ),
                      Expanded(
                        // 👈 Wrap name in another Expanded to allow flexible width
                        child: Text(
                          userData['name']! + "!",
                          overflow: TextOverflow.ellipsis, // 👈 Add ellipsis
                          maxLines: 1,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/');
                    }
                  },
                  child: const Text(
                    "Logout",
                    style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(), // Required for refresh gesture
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 🔹 Total Derma Card
// 🔹 Total Derma Card
              Card(
                color: Color(0xFF512D13),
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 24, horizontal: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "RM ${totalDerma.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Jumlah Derma Anda",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

// 🔹 Total Pusat Derma Card
              Card(
                color: Color(0xFF512D13),
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 24, horizontal: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          totalPusatDerma.toString(),
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Pusat Derma Berdaftar",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // 🔹 Notification Section
              if (notifications.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 190,
                      child: PageView.builder(
                        itemCount: notifications.length,
                        controller: PageController(viewportFraction: 0.9),
                        itemBuilder: (context, index) {
                          final notif = notifications[index];
                          return Card(
                            elevation: 5,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    FutureBuilder<Map<String, dynamic>?>(
                                      future:
                                          _getPusatDermaData(notif['id'] ?? ''),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                                ConnectionState.done &&
                                            snapshot.data != null) {
                                          final pusatDermaName =
                                              snapshot.data!['name'] ??
                                                  'Pusat Derma';

                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                pusatDermaName,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.brown,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                notif['tajuk'] ?? "Tiada Tajuk",
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                notif['penerangan'] ??
                                                    "Tiada penerangan.",
                                                maxLines: 4,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 8),
                                              Align(
                                                alignment:
                                                    Alignment.centerRight,
                                                child: ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Color(0xFFFFB800),
                                                  ),
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            ButiranPusatDermaPage(
                                                          pusatDermaData:
                                                              snapshot.data!,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  child: const Text(
                                                      "Lihat Butiran"),
                                                ),
                                              ),
                                            ],
                                          );
                                        }
                                        return const SizedBox(); // Or loading indicator if you prefer
                                      },
                                    )
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
