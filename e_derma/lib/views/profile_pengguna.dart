import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';

class ProfilePengguna extends StatefulWidget {
  const ProfilePengguna({super.key});

  @override
  _ProfilePenggunaState createState() => _ProfilePenggunaState();
}

class _ProfilePenggunaState extends State<ProfilePengguna> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? imageUrl;
  File? _imageFile;
  bool isLoading = true;

  final String cloudName =
      "dc1mmjp5m"; // Replace with your Cloudinary cloud name
  final String uploadPreset =
      "e-derma"; // Replace with your Cloudinary upload preset

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('pengguna').doc(user.uid).get();

        if (userDoc.exists) {
          if (!mounted) return;
          setState(() {
            _nameController.text = userDoc['name'] ?? '';
            _emailController.text = user.email ?? '';
            _phoneController.text = userDoc['phone'] ?? '';
            imageUrl = userDoc['profile_picture'] ?? '';
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("User data not found in Firestore")),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateUserProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);

      User? user = _auth.currentUser;
      if (user != null) {
        try {
          if (_passwordController.text.isNotEmpty) {
            await user.updatePassword(_passwordController.text);
          }

          await _firestore.collection('pengguna').doc(user.uid).set({
            'name': _nameController.text,
            'phone': _phoneController.text,
            'profile_picture': imageUrl,
          }, SetOptions(merge: true));

          if (_emailController.text.isNotEmpty &&
              _emailController.text != user.email) {
            await user.updateEmail(_emailController.text);
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Edit Profil Berjaya!",
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
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e")),
          );
        }
      }

      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      await _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No image selected")),
      );
      return;
    }

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload'),
      );

      request.fields['upload_preset'] = uploadPreset;
      request.files
          .add(await http.MultipartFile.fromPath('file', _imageFile!.path));

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          imageUrl = jsonResponse['secure_url'];
        });

        User? user = _auth.currentUser;
        if (user != null) {
          await _firestore.collection('pengguna').doc(user.uid).update({
            'profile_picture': imageUrl,
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Muatnaik Imej Berjaya!",
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Image Upload Failed!")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload Error: $e")),
      );
    }
  }

  Future<void> _removeImage() async {
    setState(() {
      imageUrl = null;
    });

    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('pengguna').doc(user.uid).update({
        'profile_picture': FieldValue.delete(),
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.white),
            SizedBox(width: 10),
            Expanded(child: Text("Gambar profil dibuang!")),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Edit Profil",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _pickImage,
                              child: CircleAvatar(
                                radius: 70,
                                backgroundImage: imageUrl != null
                                    ? NetworkImage(imageUrl!)
                                    : null,
                                child: imageUrl == null
                                    ? const Icon(Icons.camera_alt, size: 60)
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 5),
                            if (imageUrl != null)
                              TextButton(
                                onPressed: _removeImage,
                                child: const Text(
                                  "Buang Gambar Profil",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: "Nama Penuh",
                                labelStyle:
                                    TextStyle(fontWeight: FontWeight.bold),
                                border: OutlineInputBorder(),
                              ),
                              style: const TextStyle(color: Color(0xFFFFB800)),
                              validator: (value) =>
                                  value!.isEmpty ? "Enter Name" : null,
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText:
                                    "Kata laluan baharu (Tidak diwajibkan)",
                                labelStyle:
                                    TextStyle(fontWeight: FontWeight.bold),
                                border: OutlineInputBorder(),
                              ),
                              style: const TextStyle(color: Color(0xFFFFB800)),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _emailController,
                              readOnly: true, // ✅ Make it read-only
                              decoration: const InputDecoration(
                                labelText: "Emel",
                                labelStyle:
                                    TextStyle(fontWeight: FontWeight.bold),
                                border: OutlineInputBorder(),
                              ),
                              style: const TextStyle(color: Color(0xFFFFB800)),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: "Nombor Telefon",
                                labelStyle:
                                    TextStyle(fontWeight: FontWeight.bold),
                                border: OutlineInputBorder(),
                              ),
                              style: const TextStyle(color: Color(0xFFFFB800)),
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Sila masukkan nombor telefon";
                                }

                                final pattern = RegExp(r'^01[0-9]{8,9}$');
                                if (!pattern.hasMatch(value.trim())) {
                                  return "Format nombor tidak sah. Contoh: 0123456789";
                                }

                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Full-width bottom button
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: _updateUserProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB800),
                      foregroundColor: const Color(0xFF512D13),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    child: const Text("EDIT PROFIL"),
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
