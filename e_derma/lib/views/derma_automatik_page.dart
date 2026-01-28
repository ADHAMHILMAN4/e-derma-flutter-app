import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DermaAutomatikPage extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String pusatDermaName;

  const DermaAutomatikPage({
    Key? key,
    required this.userName,
    required this.userEmail,
    required this.pusatDermaName,
  }) : super(key: key);

  @override
  _DermaAutomatikPageState createState() => _DermaAutomatikPageState();
}

class _DermaAutomatikPageState extends State<DermaAutomatikPage> {
  final TextEditingController _amountController = TextEditingController();
  String _selectedFrequency = 'Bulanan';

  final List<String> _frequencies = ['Mingguan', 'Bulanan', 'Tahunan'];

  String? _userUid;
  String? _pusatDermaUid;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUids();
  }

  Future<void> _fetchUids() async {
    try {
      // Get user UID by email
      final userSnapshot = await FirebaseFirestore.instance
          .collection('pengguna')
          .where('email', isEqualTo: widget.userEmail)
          .limit(1)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        _userUid = userSnapshot.docs.first.id;
      }

      // Get pusat derma UID by name
      final pusatSnapshot = await FirebaseFirestore.instance
          .collection('pusat_derma')
          .where('name', isEqualTo: widget.pusatDermaName)
          .limit(1)
          .get();

      if (pusatSnapshot.docs.isNotEmpty) {
        _pusatDermaUid = pusatSnapshot.docs.first.id;
      }
    } catch (e) {
      print('❌ Error fetching UIDs: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveDummyDonation() async {
    final double? amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.delete_forever, color: Colors.white),
              SizedBox(width: 10),
              Expanded(child: Text("Masukkan amaun yang sah!")),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    if (_userUid == null || _pusatDermaUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maklumat pengguna atau pusat derma tidak sah')),
      );
      return;
    }

    final timestamp = FieldValue.serverTimestamp();
    DateTime now = DateTime.now();
    late DateTime nextDonationDate;

    switch (_selectedFrequency) {
      case 'Mingguan':
        nextDonationDate = now.add(Duration(days: 7));
        break;
      case 'Bulanan':
        nextDonationDate = DateTime(now.year, now.month + 1, now.day);
        break;
      case 'Tahunan':
        nextDonationDate = DateTime(now.year + 1, now.month, now.day);
        break;
      default:
        nextDonationDate = now.add(Duration(days: 30));
    }

    try {
      await FirebaseFirestore.instance.collection('derma_automatik').add({
        'userName': widget.userName,
        'userEmail': widget.userEmail,
        'userUid': _userUid,
        'pusatDermaName': widget.pusatDermaName,
        'pusatDermaUid': _pusatDermaUid,
        'amount': amount,
        'frequency': _selectedFrequency,
        'timestamp': timestamp,
        'active': true,
        'nextDonationDate': Timestamp.fromDate(nextDonationDate),
      });

      await FirebaseFirestore.instance.collection('derma').add({
        'userName': widget.userName,
        'userEmail': widget.userEmail,
        'userUid': _userUid,
        'pusatDermaName': widget.pusatDermaName,
        'pusatDermaUid': _pusatDermaUid,
        'amount': amount,
        'paymentMethod': 'Credit/Debit Card',
        'timestamp': timestamp,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Derma automatik berjaya dijadualkan!",
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

      _amountController.clear();
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menjadualkan derma')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text("Maklumat Derma Automatik")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Maklumat Derma Automatik",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      resizeToAvoidBottomInset: true, // ✅ Allow keyboard to shift content
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nama Penuh:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
            TextFormField(
              readOnly: true,
              initialValue: widget.userName,
              decoration: InputDecoration(
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: Color(0xFFC4C4C4),
              ),
            ),
            SizedBox(height: 20),
            Text('Emel:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
            TextFormField(
              readOnly: true,
              initialValue: widget.userEmail,
              decoration: InputDecoration(
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: Color(0xFFC4C4C4),
              ),
            ),
            SizedBox(height: 20),
            Text('Derma Kepada:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
            TextFormField(
              readOnly: true,
              initialValue: widget.pusatDermaName,
              decoration: InputDecoration(
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: Color(0xFFC4C4C4),
              ),
            ),
            SizedBox(height: 20),
            Text('Jumlah Derma:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Enter amount (RM)',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            SizedBox(height: 20),
            Text('Kekerapan Derma:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
            DropdownButtonFormField<String>(
              value: _selectedFrequency,
              items: _frequencies.map((freq) {
                return DropdownMenuItem<String>(
                  value: freq,
                  child: Text(freq),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedFrequency = value;
                  });
                }
              },
              decoration: InputDecoration(
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_userUid == null || _pusatDermaUid == null)
                    ? null
                    : _saveDummyDonation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFFB800),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Jadualkan Derma',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
