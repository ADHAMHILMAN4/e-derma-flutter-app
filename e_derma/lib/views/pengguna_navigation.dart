import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'map_screen.dart';
import 'search_screen.dart';
import 'donation_history.dart';
import 'profile_pengguna.dart';

class PenggunaNavigation extends StatefulWidget {
  const PenggunaNavigation({super.key});

  @override
  _PenggunaNavigationState createState() => _PenggunaNavigationState();
}

class _PenggunaNavigationState extends State<PenggunaNavigation> {
  int _selectedIndex = 0; // 🌟 Start at HomeScreen

  final List<Widget> _screens = [
    HomeScreen(), // Index 0 -> Home
    MapScreen(), // Index 1 -> Map
    SearchScreen(), // Index 2 -> Search
    DonationHistoryScreen(), // Index 3 -> Donation History
    ProfilePengguna(), // Index 4 -> Profile
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex], // Always starts at HomeScreen
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Keep all 5 icons visible
        currentIndex: _selectedIndex, // 🌟 Highlights the selected tab
        onTap: _onItemTapped,
        selectedItemColor: Color(0xFF512D13), // Selected icon color
        unselectedItemColor: Colors.white, // Unselected icon color
        backgroundColor: Color(0xFFFFB800), // Background color
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Menu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Peta',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Carian',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Rekod',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
