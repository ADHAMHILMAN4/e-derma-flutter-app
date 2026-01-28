import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'transaction_records_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecordsScreen extends StatefulWidget {
  final String pusatDermaUid;
  final String pusatDermaName;
  final String profileImageUrl;

  const RecordsScreen({
    Key? key,
    required this.pusatDermaUid,
    required this.pusatDermaName,
    required this.profileImageUrl,
  }) : super(key: key);

  @override
  _RecordsScreenState createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showFilteredResult = false;

  void _onKiraPressed() {
    if (_startDate != null && _endDate != null) {
      setState(() {
        _showFilteredResult = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sila pilih kedua-dua tarikh")),
      );
    }
  }

  Future<double> getTotalDerma() async {
    double total = 0.0;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('derma')
          .where('pusatDermaUid', isEqualTo: widget.pusatDermaUid)
          .get();

      for (var doc in snapshot.docs) {
        total += (doc['amount'] as num).toDouble();
      }
    } catch (e) {
      debugPrint("Error fetching total derma: $e");
    }

    return total;
  }

  Future<double> getDermaInRange(DateTime start, DateTime end) async {
    double total = 0.0;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('derma')
          .where('pusatDermaUid', isEqualTo: widget.pusatDermaUid)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('timestamp',
              isLessThan: Timestamp.fromDate(end.add(const Duration(days: 1))))
          .get();

      for (var doc in snapshot.docs) {
        total += (doc['amount'] as num).toDouble();
      }
    } catch (e) {
      debugPrint("Error fetching derma in range: $e");
    }

    return total;
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Widget styledCard({required String title, required double amount}) {
    return Card(
      color: const Color(0xFF512D13),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        height: 160,
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "RM ${amount.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final startText =
        _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : '';
    final endText =
        _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : '';

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(
                (widget.profileImageUrl.isNotEmpty)
                    ? widget.profileImageUrl
                    : 'https://res.cloudinary.com/dc1mmjp5m/image/upload/v1743734561/default_propic-removebg-preview_jhorbs.png',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.pusatDermaName,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/');
            },
            child: const Text(
              "Logout",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<double>(
                future: getTotalDerma(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    debugPrint("Total Derma error: ${snapshot.error}");
                    return const Text("Ralat semasa mengambil data");
                  }
                  return styledCard(
                    title: "Jumlah Derma Keseluruhan",
                    amount: snapshot.data ?? 0.0,
                  );
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickStartDate,
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Dari Tarikh',
                            border: OutlineInputBorder(),
                          ),
                          controller: TextEditingController(text: startText),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickEndDate,
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Hingga Tarikh',
                            border: OutlineInputBorder(),
                          ),
                          controller: TextEditingController(text: endText),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onKiraPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB800),
                    foregroundColor: const Color(0xFF512D13),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("KIRA"),
                ),
              ),
              const SizedBox(height: 20),
              if (_showFilteredResult)
                Column(
                  children: [
                    FutureBuilder<double>(
                      future: getDermaInRange(_startDate!, _endDate!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        if (snapshot.hasError) {
                          debugPrint('Derma range error: ${snapshot.error}');
                          return const Text(
                              "Ralat semasa mengambil data julat");
                        }
                        return styledCard(
                          title: "Jumlah Dalam Julat Tarikh",
                          amount: snapshot.data ?? 0.0,
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TransactionRecordsScreen(
                                pusatDermaUid: widget.pusatDermaUid,
                                pusatDermaName: widget.pusatDermaName,
                                startDate: _startDate!,
                                endDate: _endDate!,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFB800),
                          foregroundColor: const Color(0xFF512D13),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        child: const Text("REKOD TRANSAKSI"),
                      ),
                    )
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
