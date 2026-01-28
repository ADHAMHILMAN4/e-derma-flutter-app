import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final bool isPengguna;

  const UserProfileScreen(
      {super.key, required this.userId, required this.isPengguna});

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  void _updateUser() async {
    String collection = widget.isPengguna ? 'pengguna' : 'pusat_derma';
    await FirebaseFirestore.instance
        .collection(collection)
        .doc(widget.userId)
        .update({
      'nama': _nameController.text,
      'email': _emailController.text,
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profil Pengguna")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: "Nama")),
            TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: "Email")),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _updateUser, child: Text("Kemaskini")),
          ],
        ),
      ),
    );
  }
}
