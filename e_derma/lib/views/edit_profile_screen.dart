import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // for file handling
import 'package:http/http.dart' as http; // to make requests to Cloudinary
import 'dart:convert';
import 'package:crypto/crypto.dart'; // Import for generating the hash
import 'edit_operation_details.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _profileImageUrl;
  File? _image;
  bool _isLoading = false;

  // Cloudinary configuration
  final String cloudinaryUrl =
      'https://api.cloudinary.com/v1_1/dc1mmjp5m/image/upload';
  final String cloudinaryUploadPreset = 'e-derma';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      DocumentSnapshot userData = await FirebaseFirestore.instance
          .collection('pusat_derma')
          .doc(user.uid)
          .get();

      if (userData.exists) {
        final data = userData.data() as Map<String, dynamic>;

        setState(() {
          _nameController.text = data['name'] ?? '';
          _emailController.text = user.email ?? '';
          _phoneController.text = data['phone'] ?? '';
          _profileImageUrl = data.containsKey('profileImageUrl') &&
                  data['profileImageUrl'] != null &&
                  data['profileImageUrl'].toString().isNotEmpty
              ? data['profileImageUrl']
              : 'https://res.cloudinary.com/dc1mmjp5m/image/upload/v1743734561/default_propic-removebg-preview_jhorbs.png';
        });
      }
    }
  }

  String generateSignature(String publicId, String apiKey, String apiSecret) {
    // Get the current timestamp (in seconds)
    final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).toString();

    // Create the string to be signed
    final signString =
        'public_id=$publicId&timestamp=$timestamp&api_key=$apiKey';

    // Create the signature using the API secret and SHA-1 hash
    final key = utf8.encode(apiSecret); // Cloudinary API secret
    final bytes = utf8.encode(signString); // The string to be signed
    final hmac = Hmac(sha1, key); // HMAC SHA-1
    final digest = hmac.convert(bytes); // Hash the string

    return digest.toString(); // Return the signature
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _removeImage() async {
    setState(() {
      _image = null;
    });

    // Remove the image from Cloudinary if it exists
    if (_profileImageUrl != null) {
      // Extract the public_id from the URL or Firestore data
      final Uri uri = Uri.parse(_profileImageUrl!);
      final String? publicId = uri.pathSegments.last.split('.').first;

      if (publicId != null) {
        try {
          await _removeImageFromCloudinary(publicId);
          // Also clear the URL from Firestore
          User? user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            await FirebaseFirestore.instance
                .collection('pusat_derma')
                .doc(user.uid)
                .update({
              'profileImageUrl': null,
            });
          }
        } catch (e) {
          print("Error removing image: $e");
        }
      }
    }

    setState(() {
      _profileImageUrl = null;
    });
  }

  Future<Map<String, String>> _uploadImageToCloudinary() async {
    if (_image == null) {
      throw 'No image selected';
    }

    final Uri uri = Uri.parse(cloudinaryUrl);
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = cloudinaryUploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', _image!.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final decodedResponse = jsonDecode(responseBody);
      return {
        'secure_url': decodedResponse['secure_url'], // Image URL
        'public_id': decodedResponse['public_id'], // Image public ID
      };
    } else {
      throw 'Image upload failed: ${response.statusCode}';
    }
  }

  Future<void> _removeImageFromCloudinary(String publicId) async {
    final String cloudinaryDeleteUrl =
        'https://api.cloudinary.com/v1_1/dc1mmjp5m/image/destroy';
    final String apiKey =
        '252271876959255'; // Replace with your Cloudinary API key
    final String apiSecret =
        'GABkaDg2yvj4ZoEsWYEg5ILQrsA'; // Replace with your Cloudinary API secret

    // Generate the signature
    final String signature = generateSignature(publicId, apiKey, apiSecret);

    final response = await http.post(
      Uri.parse(cloudinaryDeleteUrl),
      body: {
        'public_id': publicId,
        'api_key': apiKey,
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        'signature': signature, // Use the generated signature
      },
    );

    if (response.statusCode == 200) {
      print("Image removed successfully from Cloudinary.");
    } else {
      throw 'Image removal failed: ${response.statusCode}';
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        String imageUrl = _profileImageUrl ?? '';

        // Upload new profile picture if selected
        if (_image != null) {
          Map<String, String> uploadedImageData =
              await _uploadImageToCloudinary();
          imageUrl =
              uploadedImageData['secure_url'] ?? ''; // Extract the image URL
        }

        // Update user profile in Firestore
        await FirebaseFirestore.instance
            .collection('pusat_derma')
            .doc(user.uid)
            .update({
          'name': _nameController.text,
          'phone': _phoneController.text,
          'profileImageUrl': imageUrl,
        });

        // Update email if changed
        if (_emailController.text != user.email) {
          await user.updateEmail(_emailController.text);
          await user.sendEmailVerification(); // Send the verification email

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Email updated successfully! Please verify it."),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Update password if changed
        if (_passwordController.text.isNotEmpty) {
          await user.updatePassword(_passwordController.text);
        }

        // Inform user that profile was successfully updated
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
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "PROFIL",
          style: TextStyle(
            color: Color(0xFF512D13),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF512D13)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Profile Picture
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 70,
                    backgroundImage: _image != null
                        ? FileImage(_image!)
                        : (_profileImageUrl != null
                            ? NetworkImage(_profileImageUrl!)
                            : null) as ImageProvider?,
                    child: _image == null && _profileImageUrl == null
                        ? Icon(Icons.camera_alt, size: 60, color: Colors.grey)
                        : null,
                  ),
                ),
                SizedBox(height: 20),

                // Option to remove profile image
                if (_profileImageUrl != null || _image != null)
                  TextButton(
                    onPressed: _removeImage,
                    child: Text(
                      "Buang Gambar Profil",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),

                SizedBox(height: 20),

                // ✅ Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: "Nama",
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(color: Color(0xFFFFB800)),
                  validator: (value) =>
                      value!.isEmpty ? "Nama diperlukan!" : null,
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: "Kata Laluan (Kosongkan jika tidak mahu tukar)",
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),

                // ✅ Email
                TextFormField(
                  controller: _emailController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: "Emel",
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(color: Color(0xFFFFB800)),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) =>
                      value!.isEmpty ? "Emel diperlukan!" : null,
                ),
                const SizedBox(height: 16),

                // ✅ Phone
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: "Nombor Telefon",
                    labelStyle: TextStyle(fontWeight: FontWeight.bold),
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

                const SizedBox(height: 20),

                // ... rest remains unchanged ...

                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFB800),
                                foregroundColor: const Color(0xFF512D13),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              child: const Text("EDIT PROFIL"),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        EditOperationDetailsScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFB800),
                                foregroundColor: const Color(0xFF512D13),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              child: const Text("UBAH MAKLUMAT PUSAT DERMA"),
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
