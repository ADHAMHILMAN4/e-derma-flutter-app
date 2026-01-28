import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/admin_controller.dart';
import 'transaction_records.dart';
import 'manage_users.dart';

class PentadbirScreen extends StatefulWidget {
  const PentadbirScreen({super.key});

  @override
  _PentadbirScreenState createState() => _PentadbirScreenState();
}

class _PentadbirScreenState extends State<PentadbirScreen> {
  int _selectedIndex = 0;
  final AdminController _adminController = AdminController();
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    _screens = [
      _buildDashboard(),
      AdminTransactionRecordsScreen(
        startDate: now.subtract(Duration(days: 30)),
        endDate: now,
      ),
      ManageUsers(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildDashboard() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Top Row with greeting + logout
            Row(
              children: [
                const CircleAvatar(
                  backgroundImage: NetworkImage(
                    "https://res.cloudinary.com/dc1mmjp5m/image/upload/v1744813856/admin_k0acsw.png",
                  ),
                  radius: 20,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Row(
                    children: [
                      Text("Hello, ",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.normal)),
                      Text(
                        "Admin!",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
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
            ),

            const SizedBox(height: 20),

            // ✅ Total Derma Card
            FutureBuilder<double>(
              future: _adminController.getTotalDerma(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingCard("Jumlah Derma");
                } else if (snapshot.hasError) {
                  return _buildErrorCard("Jumlah Derma");
                }

                return _buildStyledCard(
                  title: "RM ${snapshot.data?.toStringAsFixed(2) ?? '0.00'}",
                  subtitle: "Jumlah Derma",
                );
              },
            ),
            const SizedBox(height: 20),

            // ✅ Total Pusat Derma
            FutureBuilder<int>(
              future: _adminController.getTotalPusatDerma(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingCard("Pusat Derma");
                } else if (snapshot.hasError) {
                  return _buildErrorCard("Pusat Derma");
                }

                return _buildStyledCard(
                  title: "${snapshot.data}",
                  subtitle: "Pusat Derma Berdaftar",
                );
              },
            ),
            const SizedBox(height: 20),

            // ✅ Total Pengguna
            FutureBuilder<int>(
              future: _adminController.getTotalPengguna(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingCard("Pengguna");
                } else if (snapshot.hasError) {
                  return _buildErrorCard("Pengguna");
                }

                return _buildStyledCard(
                  title: "${snapshot.data}",
                  subtitle: "Pengguna Berdaftar",
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyledCard({required String title, required String subtitle}) {
    return Card(
      color: const Color(0xFF512D13),
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SizedBox(
        height: 160,
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                subtitle,
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
    );
  }

  Widget _buildLoadingCard(String label) {
    return Card(
      child: ListTile(
        title: Text(label),
        subtitle: const Text("Loading..."),
      ),
    );
  }

  Widget _buildErrorCard(String label) {
    return Card(
      child: ListTile(
        title: Text(label),
        subtitle: const Text("Ralat memuatkan data"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF512D13),
        unselectedItemColor: Colors.white,
        backgroundColor: const Color(0xFFFFB800),
        showUnselectedLabels: true,
        iconSize: 30,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Menu",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: "Transaksi",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: "Mengurus Pengguna",
          ),
        ],
      ),
    );
  }
}
