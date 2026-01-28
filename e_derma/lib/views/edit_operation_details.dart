import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditOperationDetailsScreen extends StatefulWidget {
  const EditOperationDetailsScreen({super.key});

  @override
  _EditOperationDetailsScreenState createState() =>
      _EditOperationDetailsScreenState();
}

class _EditOperationDetailsScreenState
    extends State<EditOperationDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _donationTypeController = TextEditingController();

  List<String> _donationTypes = [];
  String? _profileImageUrl;
  File? _image;
  bool _isLoading = false;

  final String cloudinaryUploadPreset = 'e-derma';
  final String cloudinaryCloudName = 'dc1mmjp5m';

  @override
  void initState() {
    super.initState();
    _fetchOperationDetails();
  }

  Future<void> _fetchOperationDetails() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('pusat_derma')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          var data = doc.data() as Map<String, dynamic>;

          setState(() {
            _startTimeController.text =
                data['operationHours']?.split(' - ')[0] ?? '';
            _endTimeController.text =
                data['operationHours']?.split(' - ')[1] ?? '';
            _addressController.text = data['address'] ?? '';
            _websiteController.text = data['website'] ?? '';
            _profileImageUrl = data['profileImageUrl'];
            _donationTypes =
                (data['donationTypes'] as String?)?.split(', ') ?? [];
          });
        }
      } catch (e) {
        print("Error fetching operation details: $e");
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      await _uploadImageToCloudinary();
    }
  }

  Future<void> _uploadImageToCloudinary() async {
    if (_image == null) return;
    final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload');

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = cloudinaryUploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', _image!.path));

    final response = await request.send();
    final res = await response.stream.bytesToString();
    final data = json.decode(res);

    if (response.statusCode == 200 && data['secure_url'] != null) {
      setState(() {
        _profileImageUrl = data['secure_url'];
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('pusat_derma')
            .doc(user.uid)
            .update({'profileImageUrl': _profileImageUrl});
      }
    }
  }

  Future<void> _pickTime(BuildContext context, bool isStartTime) async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        if (isStartTime) {
          _startTimeController.text = pickedTime.format(context);
        } else {
          _endTimeController.text = pickedTime.format(context);
        }
      });
    }
  }

  Future<void> _saveOperationDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        List<Location> locations =
            await locationFromAddress(_addressController.text);
        double latitude = locations.first.latitude;
        double longitude = locations.first.longitude;

        await FirebaseFirestore.instance
            .collection('pusat_derma')
            .doc(user.uid)
            .update({
          'operationHours':
              "${_startTimeController.text} - ${_endTimeController.text}",
          'address': _addressController.text,
          'donationTypes': _donationTypes.join(", "),
          'website': _websiteController.text,
          'latitude': latitude,
          'longitude': longitude,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Maklumat Pusat Derma berjaya dikemaskini!",
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
            content: Text("Ralat: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  void _addDonationType(String type) {
    setState(() => _donationTypes.add(type));
  }

  void _removeDonationType(String type) {
    setState(() => _donationTypes.remove(type));
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        border: const OutlineInputBorder(),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "UBAH MAKLUMAT PUSAT DERMA",
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
                        ? const Icon(Icons.camera_alt,
                            size: 60, color: Colors.grey)
                        : null,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _startTimeController,
                        readOnly: true,
                        style: const TextStyle(color: Color(0xFFFFB800)),
                        decoration: _inputDecoration("Dari").copyWith(
                          suffixIcon: const Icon(Icons.access_time,
                              color: Colors.black),
                        ),
                        onTap: () => _pickTime(context, true),
                        validator: (value) =>
                            value!.isEmpty ? "Waktu mula diperlukan!" : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _endTimeController,
                        readOnly: true,
                        style: const TextStyle(color: Color(0xFFFFB800)),
                        decoration: _inputDecoration("Hingga").copyWith(
                          suffixIcon: const Icon(Icons.access_time,
                              color: Colors.black),
                        ),
                        onTap: () => _pickTime(context, false),
                        validator: (value) =>
                            value!.isEmpty ? "Waktu tamat diperlukan!" : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  style: const TextStyle(color: Color(0xFFFFB800)),
                  decoration: _inputDecoration("Alamat"),
                  validator: (value) =>
                      value!.isEmpty ? "Alamat diperlukan!" : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _donationTypeController,
                        style: const TextStyle(color: Color(0xFFFFB800)),
                        decoration: _inputDecoration("Jenis Derma Diterima"),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: Color(0xFFFFB800)),
                      onPressed: () {
                        String newDonation = _donationTypeController.text;
                        if (newDonation.isNotEmpty) {
                          _addDonationType(newDonation);
                          _donationTypeController.clear();
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _donationTypes.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Color(0xFFFFB800)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Text(
                                  _donationTypes[index],
                                  style: const TextStyle(
                                    color: Color(0xFFFFB800),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove,
                                  color: Color(0xFFFFB800)),
                              onPressed: () =>
                                  _removeDonationType(_donationTypes[index]),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _websiteController,
                  style: const TextStyle(color: Color(0xFFFFB800)),
                  decoration: _inputDecoration("Laman Sesawang"),
                  keyboardType: TextInputType.url,
                  validator: (value) =>
                      value!.isEmpty ? "Laman Sesawang diperlukan!" : null,
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveOperationDetails,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFB800),
                            foregroundColor: const Color(0xFF512D13),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          child: const Text("SIMPAN PERUBAHAN"),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
