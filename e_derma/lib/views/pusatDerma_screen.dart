import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'records_screen.dart';
import 'notification_list_screen.dart';
import 'edit_profile_screen.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class PusatdermaScreen extends StatefulWidget {
  const PusatdermaScreen({super.key});

  @override
  _PusatdermaScreenState createState() => _PusatdermaScreenState();
}

class _PusatdermaScreenState extends State<PusatdermaScreen> {
  int _selectedIndex = 0;

  DateTime? fromDate;
  DateTime? toDate;
  List<ChartData> chartList = [];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          isFrom ? (fromDate ?? DateTime.now()) : (toDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          fromDate = picked;
        } else {
          toDate = picked;
        }
      });
    }
  }

  void _resetFilter() {
    setState(() {
      fromDate = null;
      toDate = null;
      chartList = [];
    });
  }

  Future<void> _loadChartData(String pusatDermaUid) async {
    if (fromDate == null || toDate == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('derma')
        .where('pusatDermaUid', isEqualTo: pusatDermaUid)
        .where('timestamp', isGreaterThanOrEqualTo: fromDate)
        .where('timestamp', isLessThanOrEqualTo: toDate)
        .get();

    final donations = snapshot.docs.map((doc) => doc.data()).toList();
    final duration = toDate!.difference(fromDate!).inDays;

    Map<String, double> grouped = {};

    for (var donation in donations) {
      final timestamp = (donation['timestamp'] as Timestamp).toDate();
      final amount = (donation['amount'] ?? 0).toDouble();

      String key;
      if (duration < 7) {
        key = DateFormat('dd MMM').format(timestamp); // daily
      } else if (duration < 31) {
        key = 'Minggu ${((timestamp.day - 1) ~/ 7) + 1}'; // weekly
      } else {
        key = DateFormat('MMM yyyy').format(timestamp); // monthly
      }

      grouped.update(key, (value) => value + amount, ifAbsent: () => amount);
    }

    setState(() {
      chartList = grouped.entries
          .map((e) => ChartData(label: e.key, total: e.value))
          .toList();
    });
  }

  Future<void> _generatePDFReport(String pusatDermaName) async {
    if (chartList.isEmpty || fromDate == null || toDate == null) return;

    final pdf = pw.Document();

    final totalAmount =
        chartList.fold<double>(0.0, (sum, data) => sum + data.total);

    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 🟡 e-Derma "Logo"
              pw.Center(
                child: pw.Text(
                  "e-Derma",
                  style: pw.TextStyle(
                    fontSize: 60,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex("#FBB800"),
                  ),
                ),
              ),

              pw.SizedBox(height: 10),

              // 📄 Title
              pw.Text(
                "Laporan Derma Bulanan",
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height: 5),
              pw.Text("Pusat Derma: $pusatDermaName"),
              pw.Text(
                "Tempoh: ${DateFormat('dd MMM yyyy').format(fromDate!)} hingga ${DateFormat('dd MMM yyyy').format(toDate!)}",
              ),

              pw.SizedBox(height: 20),

              // 🟨 Executive Summary
              pw.Text(
                "Ringkasan:",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                "Laporan ini memaparkan jumlah kutipan derma yang telah diterima oleh pusat derma \"$pusatDermaName\" dalam tempoh yang dinyatakan di atas. Semua data telah direkod secara automatik melalui sistem e-Derma.",
                textAlign: pw.TextAlign.justify,
              ),

              pw.SizedBox(height: 20),

              // 💰 Total Donation Highlight
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Text(
                  "Jumlah Derma Keseluruhan: RM ${totalAmount.toStringAsFixed(2)}",
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green900,
                  ),
                ),
              ),

              pw.SizedBox(height: 20),

              // 📊 Table Header
              pw.Text(
                "Perincian Mengikut Tempoh:",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),

              pw.Table(
                border: pw.TableBorder.all(width: 1),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    decoration:
                        pw.BoxDecoration(color: PdfColor.fromHex("#FFF3C0")),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Tempoh',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Jumlah (RM)',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...chartList.map(
                    (data) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(data.label),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(data.total.toStringAsFixed(2)),
                        ),
                      ],
                    ),
                  )
                ],
              ),

              pw.SizedBox(height: 30),

              // 🖋️ Prepared By
              pw.Text(
                "Disediakan oleh: Sistem e-Derma",
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Text(
                "Tarikh Laporan: ${DateFormat('dd MMMM yyyy, hh:mm a').format(DateTime.now())}",
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),

              pw.SizedBox(height: 16),

              // ❤️ Appreciation
              pw.Text(
                "Terima kasih kerana menggunakan platform e-Derma sebagai platform untuk menerima derma. Setiap sumbangan yang anda terima amat bermakna.",
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey800,
                  fontStyle: pw.FontStyle.italic,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/Laporan_Derma.pdf');
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }

  double _getSafeMaxY() {
    if (chartList.isEmpty) return 100;
    final maxVal =
        chartList.map((e) => e.total).reduce((a, b) => a > b ? a : b);
    final safeMax = (maxVal * 1.1 / 10).ceil() * 10;
    return safeMax.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pusat_derma')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final docSnapshot = snapshot.data;
        if (docSnapshot == null || !docSnapshot.exists) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = docSnapshot.data() as Map<String, dynamic>;
        final pusatDermaName = data['name'] ?? 'Pusat Derma';
        final profileImageUrl = data['profileImageUrl'] ?? '';
        final pusatDermaUid = docSnapshot.id;
        final updatedProfileImage = data['profileImageUrl'] ?? '';

        final List<Widget> pages = [
          _buildHomePage(pusatDermaUid, pusatDermaName, profileImageUrl),
          RecordsScreen(
            pusatDermaName: pusatDermaName,
            pusatDermaUid: pusatDermaUid,
            profileImageUrl: profileImageUrl,
          ),
          NotificationListScreen(),
          EditProfileScreen(),
        ];

        return Scaffold(
          body: IndexedStack(index: _selectedIndex, children: pages),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFF512D13),
            unselectedItemColor: Colors.white,
            backgroundColor: const Color(0xFFFFB800),
            showUnselectedLabels: true,
            iconSize: 30,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: "Menu"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.receipt), label: "Rekod"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.notifications), label: "Notifikasi"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person), label: "Profil"),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHomePage(
      String pusatDermaUid, String pusatDermaName, String profileImageUrl) {
    return Scaffold(
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
                profileImageUrl.isNotEmpty
                    ? profileImageUrl
                    : 'https://res.cloudinary.com/dc1mmjp5m/image/upload/v1743734561/default_propic-removebg-preview_jhorbs.png',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                pusatDermaName,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontFamily: "Lato",
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDateFilter(),
            const SizedBox(height: 10),
            _buildActionButtons(pusatDermaUid),
            const SizedBox(height: 20),
            if (chartList.isNotEmpty)
              SizedBox(height: 300, child: _buildBarChart())
            else
              const Text("Tiada data untuk dipaparkan."),
            if (chartList.isNotEmpty) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _generatePDFReport(pusatDermaName),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB800),
                  foregroundColor: const Color(0xFF512D13),
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text("Jana Laporan"),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilter() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _selectDate(context, true),
            child: AbsorbPointer(
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Dari Tarikh',
                  border: OutlineInputBorder(),
                ),
                controller: TextEditingController(
                  text: fromDate != null
                      ? DateFormat('yyyy-MM-dd').format(fromDate!)
                      : '',
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => _selectDate(context, false),
            child: AbsorbPointer(
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Hingga Tarikh',
                  border: OutlineInputBorder(),
                ),
                controller: TextEditingController(
                  text: toDate != null
                      ? DateFormat('yyyy-MM-dd').format(toDate!)
                      : '',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(String pusatDermaUid) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _resetFilter,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFFFB800)),
              foregroundColor: const Color(0xFF512D13),
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            child: const Text("Tetap Semula"),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _loadChartData(pusatDermaUid),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB800),
              foregroundColor: const Color(0xFF512D13),
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            child: const Text("Paparkan"),
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _getSafeMaxY(),
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    value.toStringAsFixed(0),
                    style: const TextStyle(fontSize: 10),
                    textAlign: TextAlign.right,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                int index = value.toInt();
                if (index >= 0 && index < chartList.length) {
                  return Text(
                    chartList[index].label,
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text('');
              },
              reservedSize: 40,
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: List.generate(chartList.length, (index) {
          return BarChartGroupData(x: index, barRods: [
            BarChartRodData(
              toY: chartList[index].total,
              color: Colors.deepPurple,
              width: 18,
              borderRadius: BorderRadius.circular(4),
            ),
          ]);
        }),
      ),
    );
  }
}

class ChartData {
  final String label;
  final double total;

  ChartData({required this.label, required this.total});
}
