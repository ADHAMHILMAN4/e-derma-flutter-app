import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ Added for user UID

class DermaPage extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String userPhone;
  final String pusatDermaName;

  const DermaPage({
    Key? key,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    required this.pusatDermaName,
  }) : super(key: key);

  @override
  _DermaPageState createState() => _DermaPageState();
}

class _DermaPageState extends State<DermaPage> {
  final TextEditingController _amountController = TextEditingController();
  Map<String, dynamic>? paymentIntent;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> makePayment() async {
    try {
      double? amount = double.tryParse(_amountController.text);
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      paymentIntent = await createPaymentIntent((amount * 100).toInt());

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent!['client_secret'],
          merchantDisplayName: 'Derma App',
          billingDetails: BillingDetails(
            email: widget.userEmail,
            name: widget.userName,
            phone: '+60123456789',
          ),
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      final pusatDermaUid = await getPusatDermaUid(widget.pusatDermaName);
      if (pusatDermaUid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pusat Derma tidak dijumpai.')),
        );
        return;
      }

      await saveDonationToFirestore(
        userName: widget.userName,
        userEmail: widget.userEmail,
        pusatDermaName: widget.pusatDermaName,
        pusatDermaUid: pusatDermaUid,
        amount: amount,
        paymentMethod: 'Credit/Debit Card',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Derma Berjaya. Terima Kasih!",
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
    } on StripeException catch (e) {
      print('Stripe exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment cancelled or failed.')),
      );
    } catch (e) {
      print('General error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Something went wrong: $e')),
      );
    }
  }

  Future<void> payWithToyyibPay() async {
    double? amount = double.tryParse(_amountController.text);
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

    final response = await http.post(
      Uri.parse('https://dev.toyyibpay.com/index.php/api/createBill'),
      body: {
        'userSecretKey': 'czeku37a-76r4-sdho-f426-c0fjj8q86lyw',
        'categoryCode': 'iwrhogrl',
        'billName': 'Derma to ${widget.pusatDermaName}',
        'billDescription': 'Online Banking Donation',
        'billPriceSetting': '1',
        'billPayorInfo': '1',
        'billAmount': (amount * 100).toInt().toString(),
        'billReturnUrl': 'https://yourapp.com/success',
        'billCallbackUrl': 'https://yourbackend.com/callback',
        'billExternalReferenceNo':
            DateTime.now().millisecondsSinceEpoch.toString(),
        'billTo': widget.userName,
        'billEmail': widget.userEmail,
        'billPhone': widget.userPhone,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is List && data.isNotEmpty && data[0]['BillCode'] != null) {
        final billCode = data[0]['BillCode'];
        final paymentUrl = 'https://dev.toyyibpay.com/$billCode';

        final pusatDermaUid = await getPusatDermaUid(widget.pusatDermaName);
        if (pusatDermaUid == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Pusat Derma tidak dijumpai')),
          );
          return;
        }

        await saveDonationToFirestore(
          userName: widget.userName,
          userEmail: widget.userEmail,
          pusatDermaName: widget.pusatDermaName,
          pusatDermaUid: pusatDermaUid,
          amount: amount,
          paymentMethod: 'Online Banking',
        );

        if (await canLaunchUrl(Uri.parse(paymentUrl))) {
          await launchUrl(Uri.parse(paymentUrl),
              mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not launch $paymentUrl';
        }
      } else {
        print('Unexpected ToyyibPay response: $data');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid response from ToyyibPay API')),
        );
      }
    } else {
      print('ToyyibPay error: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to initiate ToyyibPay payment.')),
      );
    }
  }

  Future<void> payWithToyyibPayEwallet() async {
    double? amount = double.tryParse(_amountController.text);
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

    String? selectedEwallet = await showModalBottomSheet<String>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Pilih eWallet",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ListTile(
                leading: Image.asset(
                  'assets/images/ewallets/grabpay2.png',
                  width: 32,
                  height: 32,
                ),
                title: Text("GrabPay"),
                onTap: () => Navigator.pop(context, "GrabPay"),
              ),
              ListTile(
                leading: Image.asset(
                  'assets/images/ewallets/touchngo.png',
                  width: 32,
                  height: 32,
                ),
                title: Text("Touch 'n Go eWallet"),
                onTap: () => Navigator.pop(context, "Touch 'n Go eWallet"),
              ),
              ListTile(
                leading: Image.asset(
                  'assets/images/ewallets/shopeepay.png',
                  width: 32,
                  height: 32,
                ),
                title: Text("ShopeePay"),
                onTap: () => Navigator.pop(context, "ShopeePay"),
              ),
              ListTile(
                leading: Image.asset(
                  'assets/images/ewallets/boost.png',
                  width: 32,
                  height: 32,
                ),
                title: Text("Boost"),
                onTap: () => Navigator.pop(context, "Boost"),
              ),
              ListTile(
                leading: Icon(Icons.close),
                title: Text("Cancel"),
                onTap: () => Navigator.pop(context, null),
              ),
            ],
          ),
        );
      },
    );

    if (selectedEwallet == null) return;

    // Show dummy processing dialog
// Show the dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text(
                    "Pembayaran sedang diproses menggunakan $selectedEwallet...",
                    style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        );
      },
    );

// Dismiss it after 2 seconds
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Close the dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Derma Berjaya. Terima Kasih!",
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
      }
    });

    await Future.delayed(Duration(seconds: 3));
    if (!mounted) return;
    Navigator.of(context).pop(); // close dialog

    final pusatDermaUid = await getPusatDermaUid(widget.pusatDermaName);
    if (pusatDermaUid == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pusat Derma tidak dijumpai.')),
        );
      }
      return;
    }

    await saveDonationToFirestore(
      userName: widget.userName,
      userEmail: widget.userEmail,
      pusatDermaName: widget.pusatDermaName,
      pusatDermaUid: pusatDermaUid,
      amount: amount,
      paymentMethod: 'eWallet',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Derma Berjaya. Terima Kasih!",
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
    }

    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        _amountController.clear();
      }
    });
  }

  Future<String?> getPusatDermaUid(String name) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('pusat_derma')
        .where('name', isEqualTo: name)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.id;
    }
    return null;
  }

  Future<void> saveDonationToFirestore({
    required String userName,
    required String userEmail,
    required String pusatDermaName,
    required double amount,
    required String paymentMethod,
    required String pusatDermaUid,
  }) async {
    final userUid = FirebaseAuth.instance.currentUser?.uid;

    final donationData = {
      'userUid': userUid, // ✅ Save UID here
      'userName': userName,
      'userEmail': userEmail,
      'pusatDermaName': pusatDermaName,
      'pusatDermaUid': pusatDermaUid,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance.collection('derma').add(donationData);
  }

  Future<Map<String, dynamic>> createPaymentIntent(int amount) async {
    try {
      const String secretKey =
          'sk_test_51RA1RxQ6gaeYFkZgIMycLqc9J0OoNKJA256YzZbU9MzEF96m5hEJ5OP8jJSW9qyU20wKwCddF8i1TVOgztHKBonB00eeSYw58A';

      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': amount.toString(),
          'currency': 'myr',
          'payment_method_types[]': 'card',
          'capture_method': 'automatic',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create payment intent');
      }
    } catch (err) {
      print('Error creating payment intent: $err');
      throw Exception('Error creating payment intent: $err');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Maklumat Derma",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      resizeToAvoidBottomInset:
          true, // ✅ allow screen to resize when keyboard appears
      body: SingleChildScrollView(
        // ✅ make the content scrollable
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildReadOnlyField('Nama Penuh:', widget.userName),
            buildReadOnlyField('Emel:', widget.userEmail),
            buildReadOnlyField('Derma Kepada:', widget.pusatDermaName),
            SizedBox(height: 2),
            Text('Jumlah Derma:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Enter amount (RM)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 20),
            Text('Kaedah Pembayaran:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: makePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFFB800),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Kad Kredit/Debit'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: payWithToyyibPay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFFB800),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Perbankan Atas Talian'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: payWithToyyibPayEwallet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFFB800),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('e-Wallet'),
                ),
              ],
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 5),
        TextFormField(
          readOnly: true,
          initialValue: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: Color(0xFFC4C4C4),
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }
}
