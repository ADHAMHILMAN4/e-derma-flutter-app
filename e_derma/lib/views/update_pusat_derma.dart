import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geocoding/geocoding.dart';

class UpdatePusatDerma extends StatefulWidget {
  final String pusatId;

  const UpdatePusatDerma({super.key, required this.pusatId});

  @override
  State<UpdatePusatDerma> createState() => _UpdatePusatDermaState();
}

class _UpdatePusatDermaState extends State<UpdatePusatDerma> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _donationTypeController = TextEditingController();

  List<String> _donationTypes = [];

  String? imageUrl;
  File? _image;
  bool _isLoading = false;

  final String cloudinaryUrl =
      'https://api.cloudinary.com/v1_1/dc1mmjp5m/image/upload';
  final String uploadPreset = 'e-derma';

  @override
  void initState() {
    super.initState();
    _loadPusatData();
  }

  Future<void> _loadPusatData() async {
    final doc = await FirebaseFirestore.instance
        .collection('pusat_derma')
        .doc(widget.pusatId)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _nameController.text = data['name'] ?? '';
        _emailController.text = data['email'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _addressController.text = data['address'] ?? '';
        _websiteController.text = data['website'] ?? '';
        final operationHours = data['operationHours'] ?? '';
        if (operationHours.contains(' - ')) {
          final parts = operationHours.split(' - ');
          _startTimeController.text = parts[0];
          _endTimeController.text = parts[1];
        }
        _donationTypes = (data['donationTypes'] as String?)?.split(', ') ?? [];
        imageUrl = data['profileImageUrl'];
      });
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  Future<String> _uploadImageToCloudinary() async {
    if (_image == null) return imageUrl ?? '';

    final request = http.MultipartRequest('POST', Uri.parse(cloudinaryUrl))
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', _image!.path));

    final res = await request.send();
    final resBody = await res.stream.bytesToString();
    final jsonData = json.decode(resBody);
    return jsonData['secure_url'];
  }

  Future<void> _removeImage() async {
    setState(() {
      imageUrl = null;
      _image = null;
    });

    await FirebaseFirestore.instance
        .collection('pusat_derma')
        .doc(widget.pusatId)
        .update({'profileImageUrl': FieldValue.delete()});
  }

  Future<void> _pickTime(BuildContext context, bool isStartTime) async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      final time = pickedTime.format(context);
      setState(() {
        if (isStartTime) {
          _startTimeController.text = time;
        } else {
          _endTimeController.text = time;
        }
      });
    }
  }

  void _addDonationType(String type) {
    setState(() {
      if (type.isNotEmpty && !_donationTypes.contains(type)) {
        _donationTypes.add(type);
        _donationTypeController.clear();
      }
    });
  }

  void _removeDonationType(String type) {
    setState(() => _donationTypes.remove(type));
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final uploadedUrl =
          _image != null ? await _uploadImageToCloudinary() : imageUrl;

      String? fullOperationHours;
      if (_startTimeController.text.isNotEmpty &&
          _endTimeController.text.isNotEmpty) {
        fullOperationHours =
            "${_startTimeController.text} - ${_endTimeController.text}";
      }

      double? latitude;
      double? longitude;

      if (_addressController.text.trim().isNotEmpty) {
        try {
          List<Location> locations =
              await locationFromAddress(_addressController.text.trim());
          latitude = locations.first.latitude;
          longitude = locations.first.longitude;
        } catch (e) {
          print("❌ Geocoding failed: $e");
        }
      }

      // 🔧 Fix: Make sure the map can hold mixed types (String, double, etc.)
      final Map<String, dynamic> updateData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'profileImageUrl': uploadedUrl,
      };

      if (fullOperationHours != null) {
        updateData['operationHours'] = fullOperationHours;
      }
      if (_addressController.text.trim().isNotEmpty) {
        updateData['address'] = _addressController.text.trim();
      }
      if (_websiteController.text.trim().isNotEmpty) {
        updateData['website'] = _websiteController.text.trim();
      }
      if (_donationTypes.isNotEmpty) {
        updateData['donationTypes'] = _donationTypes.join(', ');
      }
      if (latitude != null && longitude != null) {
        updateData['latitude'] = latitude;
        updateData['longitude'] = longitude;
      }

      await FirebaseFirestore.instance
          .collection('pusat_derma')
          .doc(widget.pusatId)
          .update(updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Pusat Derma berjaya dikemaskini!",
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
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ralat: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
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
        title: const Text("Kemaskini Pusat Derma"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF512D13)),
        titleTextStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFFFFB800),
          fontSize: 18,
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
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
                            : (imageUrl != null
                                ? NetworkImage(imageUrl!)
                                : null) as ImageProvider?,
                        child: _image == null && imageUrl == null
                            ? const Icon(Icons.camera_alt, size: 60)
                            : null,
                      ),
                    ),
                    if (imageUrl != null || _image != null)
                      TextButton(
                        onPressed: _removeImage,
                        child: const Text("Buang Gambar",
                            style: TextStyle(color: Colors.red)),
                      ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration("Nama Pusat Derma"),
                      style: const TextStyle(color: Color(0xFFFFB800)),
                      validator: (value) =>
                          value!.isEmpty ? "Sila isi nama." : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      readOnly: true,
                      decoration: _inputDecoration("Emel"),
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Color(0xFFFFB800)),
                      validator: (value) =>
                          value!.isEmpty ? "Sila isi emel." : null,
                    ),
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _startTimeController,
                            readOnly: true,
                            decoration: _inputDecoration("Dari").copyWith(
                              suffixIcon: const Icon(Icons.access_time),
                            ),
                            onTap: () => _pickTime(context, true),
                            validator: (value) => null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _endTimeController,
                            readOnly: true,
                            decoration: _inputDecoration("Hingga").copyWith(
                              suffixIcon: const Icon(Icons.access_time),
                            ),
                            onTap: () => _pickTime(context, false),
                            validator: (value) => null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: _inputDecoration("Alamat"),
                      style: const TextStyle(color: Color(0xFFFFB800)),
                      validator: (value) => null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _donationTypeController,
                            decoration:
                                _inputDecoration("Jenis Derma Diterima"),
                            style: const TextStyle(color: Color(0xFFFFB800)),
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              _addDonationType(_donationTypeController.text),
                          icon: const Icon(Icons.add, color: Color(0xFFFFB800)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: _donationTypes.length,
                      itemBuilder: (context, index) => ListTile(
                        title: Text(_donationTypes[index],
                            style: const TextStyle(color: Color(0xFFFFB800))),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove,
                              color: Color(0xFFFFB800)),
                          onPressed: () =>
                              _removeDonationType(_donationTypes[index]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _websiteController,
                      decoration: _inputDecoration("Laman Sesawang"),
                      keyboardType: TextInputType.url,
                      style: const TextStyle(color: Color(0xFFFFB800)),
                      validator: (value) => null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFB800),
                          foregroundColor: const Color(0xFF512D13),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        child: const Text("KEMASKINI"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
