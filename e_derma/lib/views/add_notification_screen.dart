import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddNotificationScreen extends StatefulWidget {
  const AddNotificationScreen({super.key});

  @override
  _AddNotificationScreenState createState() => _AddNotificationScreenState();
}

class _AddNotificationScreenState extends State<AddNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _tajukController = TextEditingController();
  final TextEditingController _peneranganController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitNotification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Ralat: Pengguna tidak dijumpai!"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // 1️⃣ Save to Firestore
      await FirebaseFirestore.instance.collection('notifikasi').add({
        'tajuk': _tajukController.text.trim(),
        'penerangan': _peneranganController.text.trim(),
        'pusatDermaId': user.uid,
        'timestamp': Timestamp.now(),
      });

      // 2️⃣ Send push notification to topic: pengguna
      final response = await http.post(
        Uri.parse(
            'http://10.79.201.90:3000/pusat-notify-pengguna'), // 🔁 Replace with actual IP
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': _tajukController.text.trim(),
          'body': _peneranganController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Notifikasi berjaya dihantar!",
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        throw Exception("Gagal hantar notifikasi. Kod: ${response.statusCode}");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Ralat: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _tajukController.dispose();
    _peneranganController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Tambah Notifikasi",
          style: TextStyle(
            fontFamily: 'Lato',
            color: Color(0xFFFFB800),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Tajuk Notifikasi",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _tajukController,
                decoration: const InputDecoration(
                  hintText: "Masukkan tajuk...",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Tajuk diperlukan!" : null,
              ),
              const SizedBox(height: 16),
              const Text("Penerangan",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _peneranganController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: "Masukkan penerangan...",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Penerangan diperlukan!" : null,
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitNotification,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFB800),
                          foregroundColor: const Color(0xFF512D13),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        child: const Text("TAMBAH"),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
