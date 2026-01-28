import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'derma_automatik_page.dart';
import 'derma_page.dart';

class ButiranPusatDermaPage extends StatelessWidget {
  final Map<String, dynamic> pusatDermaData;

  const ButiranPusatDermaPage({Key? key, required this.pusatDermaData})
      : super(key: key);

  Future<String> getUserNameFromFirestore() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('pengguna')
          .doc(user.uid)
          .get();
      if (snapshot.exists) {
        return snapshot['name'] ?? 'No name available';
      }
      return 'No user found';
    }
    return 'No user logged in';
  }

  Future<String> getUserPhoneNumberFromFirestore() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('pengguna')
          .doc(user.uid)
          .get();
      if (snapshot.exists) {
        return snapshot['phone'] ?? 'Tiada nombor telefon';
      }
      return 'Pengguna tidak dijumpai';
    }
    return 'Pengguna belum log masuk';
  }

  /// Helper to build label–value rows
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF512D13),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF512D13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Returns whether current time is within operation hours and a widget suffix
  Widget buildOperationHoursStatus(String operationHours) {
    try {
      final parts = operationHours.split('-');
      if (parts.length != 2) return const Text(' (maklumat tidak sah)');

      final now = TimeOfDay.now();
      final startParts = parts[0].trim().split(':');
      final endParts = parts[1].trim().split(':');

      final startHour = int.parse(startParts[0]);
      final startMinute = int.parse(startParts[1]);
      final endHour = int.parse(endParts[0]);
      final endMinute = int.parse(endParts[1]);

      final startTime = TimeOfDay(hour: startHour, minute: startMinute);
      final endTime = TimeOfDay(hour: endHour, minute: endMinute);

      bool isOpen = _isCurrentTimeInRange(now, startTime, endTime);

      return Text(
        isOpen ? ' (Buka)' : ' (Tutup)',
        style: TextStyle(
          color: isOpen ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
          fontFamily: 'Lato',
        ),
      );
    } catch (e) {
      return const Text(' (format tidak sah)');
    }
  }

  /// Checks if current time is within the given range
  bool _isCurrentTimeInRange(TimeOfDay now, TimeOfDay start, TimeOfDay end) {
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
  }

  /// Function to launch URL for phone call
  Future<void> _launchPhone(String phone) async {
    final url = 'tel:$phone';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not dial the phone number $phone';
    }
  }

  /// Function to launch website
  Future<void> _launchWebsite(String website) async {
    final url = website.startsWith('http') ? website : 'https://$website';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not open the website $website';
    }
  }

  @override
  Widget build(BuildContext context) {
    String imageUrl = pusatDermaData['profileImageUrl']?.toString() ?? '';
    String defaultImageUrl =
        'https://res.cloudinary.com/dc1mmjp5m/image/upload/v1743734561/default_propic-removebg-preview_jhorbs.png';
    String name = pusatDermaData['name'] ?? 'Tiada';
    String address = pusatDermaData['address'] ?? 'Tiada';
    String operationHours = pusatDermaData['operationHours'] ?? 'Tiada';
    String donationTypes = pusatDermaData['donationTypes'] ?? 'Tiada';
    String phone = pusatDermaData['phone'] ?? 'Tiada';
    String website = pusatDermaData['website'] ?? 'Tiada';

    // Split and trim donation types
    final bullets = donationTypes
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Butiran Pusat Derma",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Picture
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: Image.network(
                  imageUrl.isNotEmpty ? imageUrl : defaultImageUrl,
                  height: 120,
                  width: 120,
                  fit: BoxFit.cover,
                  loadingBuilder: (ctx, child, progress) => progress == null
                      ? child
                      : const SizedBox(
                          height: 120,
                          width: 120,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                  errorBuilder: (ctx, err, st) => const SizedBox(
                    height: 120,
                    width: 120,
                    child: Center(child: Icon(Icons.error, color: Colors.red)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Name below profile picture
            Center(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFB800),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Section Title
            const Text(
              "Maklumat Pusat Derma",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFB800),
              ),
            ),
            const SizedBox(height: 16),
            // Operation Hours row
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    width: 140,
                    child: Text(
                      "Tempoh Operasi:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF512D13),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          operationHours,
                          style: const TextStyle(
                            color: Color(0xFF512D13),
                            fontFamily: 'Lato',
                          ),
                        ),
                        const SizedBox(width: 8),
                        buildOperationHoursStatus(operationHours),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Address row
            _buildInfoRow("Alamat:", address),
            // Donation types as vertical bullets
            Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Text(
                "Jenis Derma:",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF512D13),
                ),
              ),
            ),
            donationTypes == 'Tiada'
                ? Text(
                    'Tiada',
                    style: const TextStyle(color: Color(0xFF512D13)),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: bullets
                        .map(
                          (b) => Text(
                            "• $b",
                            style: const TextStyle(color: Color(0xFF512D13)),
                          ),
                        )
                        .toList(),
                  ),
            const SizedBox(height: 12),
            // Phone row with clickable phone number
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    width: 140,
                    child: Text(
                      "Nombor Telefon:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF512D13),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _launchPhone(phone),
                      child: Text(
                        phone,
                        style: const TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Website row with clickable website
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    width: 140,
                    child: Text(
                      "Laman Sesawang:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF512D13),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _launchWebsite(website),
                      child: Text(
                        website,
                        style: const TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Navigation link
            RichText(
              text: TextSpan(
                text: 'Tekan ',
                style: const TextStyle(
                  color: Color(0xFF512D13),
                  fontSize: 16, // Match other body text size
                  fontFamily: 'Lato',
                  fontWeight: FontWeight.normal,
                  decoration: TextDecoration.none,
                ),
                children: [
                  TextSpan(
                    text: 'di sini',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 16,
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.normal,
                      decoration: TextDecoration.none,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        final encodedAddress = Uri.encodeComponent(address);
                        final url =
                            'https://www.google.com/maps/search/?api=1&query=$encodedAddress';
                        final uri = Uri.parse(url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Tidak dapat buka aplikasi peta')),
                          );
                        }
                      },
                  ),
                  const TextSpan(
                    text: ' untuk pergi ke pusat derma ini.',
                    style: TextStyle(
                      color: Color(0xFF512D13),
                      fontSize: 16,
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.normal,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            // Bottom buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      User? u = FirebaseAuth.instance.currentUser;
                      if (u != null) {
                        String userName = await getUserNameFromFirestore();
                        String userEmail = u.email ?? 'No Email';
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DermaAutomatikPage(
                              userName: userName,
                              userEmail: userEmail,
                              pusatDermaName: name,
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Please log in to use Derma Automatik')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB800),
                      foregroundColor: const Color(0xFF512D13),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("Derma Automatik"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      User? u = FirebaseAuth.instance.currentUser;
                      if (u != null) {
                        String userName = await getUserNameFromFirestore();
                        String userEmail = u.email ?? 'No Email';
                        String userPhone =
                            await getUserPhoneNumberFromFirestore(); // <- new line

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DermaPage(
                              userName: userName,
                              userEmail: userEmail,
                              userPhone: userPhone, // <- pass it here
                              pusatDermaName: name,
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Please log in to proceed with the donation')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB800),
                      foregroundColor: const Color(0xFF512D13),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("Derma"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
