import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditNotificationScreen extends StatefulWidget {
  final String docId;
  final String initialTajuk;
  final String initialPenerangan;

  const EditNotificationScreen({
    super.key,
    required this.docId,
    required this.initialTajuk,
    required this.initialPenerangan,
  });

  @override
  State<EditNotificationScreen> createState() => _EditNotificationScreenState();
}

class _EditNotificationScreenState extends State<EditNotificationScreen> {
  late TextEditingController tajukController;
  late TextEditingController peneranganController;

  @override
  void initState() {
    super.initState();
    tajukController = TextEditingController(text: widget.initialTajuk);
    peneranganController =
        TextEditingController(text: widget.initialPenerangan);
  }

  Future<void> _updateNotification() async {
    await FirebaseFirestore.instance
        .collection('notifikasi')
        .doc(widget.docId)
        .update({
      'tajuk': tajukController.text.trim(),
      'penerangan': peneranganController.text.trim(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Expanded(child: Text("Notifikasi berjaya dikemaskini!")),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        duration: const Duration(seconds: 3),
      ),
    );

    Navigator.pop(context);
  }

  Future<void> _deleteNotification() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Padam Notifikasi"),
        content: const Text("Adakah anda pasti untuk memadam notifikasi ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Padam"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('notifikasi')
          .doc(widget.docId)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.delete_forever, color: Colors.white),
              SizedBox(width: 10),
              Expanded(child: Text("Notifikasi berjaya dipadam!")),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          duration: const Duration(seconds: 3),
        ),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kemaskini Notifikasi"),
        backgroundColor: const Color(0xFFFFB800),
        foregroundColor: const Color(0xFF512D13),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteNotification,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: tajukController,
              decoration: const InputDecoration(
                labelText: "Tajuk",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: peneranganController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: "Penerangan",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              onPressed: _updateNotification,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB800),
                foregroundColor: const Color(0xFF512D13),
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              ),
              label: const Text("Simpan Kemaskini"),
            ),
          ],
        ),
      ),
    );
  }
}
